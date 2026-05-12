import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// Slot mapping:
///   -1  → reference note
///  0–3  → violin strings E5, A4, D4, G3
class _Slot {
  _Slot({required this.source, required this.handle});

  final AudioSource source;
  final SoundHandle handle;
}

/// Singleton wrapper around flutter_soloud.
///
/// One sawtooth [AudioSource] per slot — sawtooth has natural harmonics that
/// resemble a bowed string far better than a sine wave. Single oscillator per
/// slot eliminates the inter-oscillator beating that causes a "wavy" volume.
/// All voices are pre-allocated as paused at init; play/stop are synchronous.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final Map<int, _Slot> _slots = {};
  bool _initialized = false;

  // Generation counters — incremented to cancel a pending pluck decay.
  final Map<int, int> _pluckGen = {};

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;
    try {
      await SoLoud.instance.init();

      for (int slot = -1; slot <= 3; slot++) {
        final source = await SoLoud.instance.loadWaveform(
          WaveForm.saw, // sawtooth ≈ bowed string timbre
          false,
          0.5,
          0,
        );
        final handle = await SoLoud.instance.play(
          source,
          volume: 0.0,
          paused: true,
          looping: true,
        );
        _slots[slot] = _Slot(source: source, handle: handle);
      }
      _initialized = true;
    } catch (e) {
      if (kDebugMode) debugPrint('[AudioService] init error: $e');
    }
  }

  Future<void> dispose() async {
    if (!_initialized) return;
    stopAll();
    for (final s in _slots.values) {
      await SoLoud.instance.disposeSource(s.source);
    }
    _slots.clear();
    SoLoud.instance.deinit();
    _initialized = false;
  }

  // ── Playback (synchronous) ─────────────────────────────────────────────────

  void playTone(int slot, double frequency) {
    if (!_initialized) return;
    final s = _slots[slot];
    if (s == null) return;
    _pluckGen[slot] = (_pluckGen[slot] ?? 0) + 1; // cancel pending pluck decay
    SoLoud.instance.setWaveformFreq(s.source, frequency);
    SoLoud.instance.setVolume(s.handle, 0.5);
    SoLoud.instance.setPause(s.handle, false);
  }

  void stopTone(int slot) {
    if (!_initialized) return;
    final s = _slots[slot];
    if (s == null) return;
    _pluckGen[slot] = (_pluckGen[slot] ?? 0) + 1; // cancel pending pluck decay
    SoLoud.instance.setVolume(s.handle, 0.0);
    SoLoud.instance.setPause(s.handle, true);
  }

  /// Plays [frequency] on [slot] with an exponential volume decay that mimics
  /// a plucked string. Safe to call while a pluck is already decaying — the
  /// previous decay is cancelled via the generation counter.
  void pluckTone(int slot, double frequency) {
    if (!_initialized) return;
    final s = _slots[slot];
    if (s == null) return;

    _pluckGen[slot] = (_pluckGen[slot] ?? 0) + 1;
    final gen = _pluckGen[slot]!;

    SoLoud.instance.setWaveformFreq(s.source, frequency);
    SoLoud.instance.setVolume(s.handle, 0.7);
    SoLoud.instance.setPause(s.handle, false);

    // Exponential decay: (delay-ms, target-volume)
    const curve = [
      (110, 0.48),
      (110, 0.28),
      (120, 0.13),
      (110, 0.05),
      (100, 0.0),
    ];
    int elapsed = 0;
    for (final (delay, vol) in curve) {
      elapsed += delay;
      Future.delayed(Duration(milliseconds: elapsed), () {
        if ((_pluckGen[slot] ?? 0) != gen) return; // cancelled
        if (!_initialized) return;
        if (vol == 0.0) {
          SoLoud.instance.setVolume(s.handle, 0.0);
          SoLoud.instance.setPause(s.handle, true);
        } else {
          SoLoud.instance.setVolume(s.handle, vol);
        }
      });
    }
  }

  void updateFrequency(int slot, double frequency) {
    if (!_initialized) return;
    final s = _slots[slot];
    if (s == null) return;
    SoLoud.instance.setWaveformFreq(s.source, frequency);
  }

  bool isPlaying(int slot) {
    if (!_initialized) return false;
    final s = _slots[slot];
    if (s == null) return false;
    return !SoLoud.instance.getPause(s.handle);
  }

  void stopAll() {
    if (!_initialized) return;
    for (final slot in _slots.keys) {
      stopTone(slot);
    }
  }
}
