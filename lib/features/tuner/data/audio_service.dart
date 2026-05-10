import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// Base frequency produced by a SoLoud waveform at relativePlaySpeed = 1.0.
/// SoLoud sine waveforms default to A4 = 440 Hz.
const double _kBaseFreq = 440.0;

/// Voice slot constants.
///   -1  → reference note
///  0–3  → violin strings E5, A4, D4, G3
typedef _VoicePair = (SoundHandle, SoundHandle);

/// Singleton wrapper around flutter_soloud for Quanta's tone synthesis.
///
/// Each voice uses two oscillators:
///   • Primary   — at the target frequency, volume 0.6
///   • Secondary — +2 cents detuned, volume 0.3  (adds warmth)
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  AudioSource? _source;
  final Map<int, _VoicePair> _voices = {};
  bool _initialized = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;
    try {
      await SoLoud.instance.init();
      _source = await SoLoud.instance.loadWaveform(
        WaveForm.sin,
        false,
        0.25,
        0,
      );
      _initialized = true;
    } catch (e) {
      if (kDebugMode) debugPrint('[AudioService] init error: $e');
    }
  }

  Future<void> dispose() async {
    stopAll();
    if (_source != null) await SoLoud.instance.disposeSource(_source!);
    if (_initialized) SoLoud.instance.deinit();
    _initialized = false;
  }

  // ── Playback ───────────────────────────────────────────────────────────────

  /// Starts (or updates) a tone for [slot] at [frequency] Hz.
  Future<void> playTone(int slot, double frequency) async {
    if (!_initialized || _source == null) return;
    if (_voices.containsKey(slot)) {
      _setSpeed(slot, frequency);
      return;
    }

    final speed = frequency / _kBaseFreq;
    final detuneSpeed = speed * pow(2.0, 2.0 / 1200.0);

    try {
      final h1 = await SoLoud.instance.play(
        _source!,
        volume: 0.0,
        looping: true,
      );
      final h2 = await SoLoud.instance.play(
        _source!,
        volume: 0.0,
        looping: true,
      );

      SoLoud.instance.setRelativePlaySpeed(h1, speed);
      SoLoud.instance.setRelativePlaySpeed(h2, detuneSpeed);

      // Fade in to avoid clicks.
      SoLoud.instance.fadeVolume(h1, 0.6, const Duration(milliseconds: 20));
      SoLoud.instance.fadeVolume(h2, 0.3, const Duration(milliseconds: 20));

      _voices[slot] = (h1, h2);
    } catch (e) {
      if (kDebugMode) debugPrint('[AudioService] playTone error: $e');
    }
  }

  /// Stops the tone for [slot] with a short fade-out.
  void stopTone(int slot) {
    final pair = _voices.remove(slot);
    if (pair == null) return;
    final (h1, h2) = pair;
    SoLoud.instance.fadeVolume(h1, 0.0, const Duration(milliseconds: 20));
    SoLoud.instance.fadeVolume(h2, 0.0, const Duration(milliseconds: 20));
    // Schedule stop after the fade completes.
    Future.delayed(const Duration(milliseconds: 30), () {
      unawaited(SoLoud.instance.stop(h1));
      unawaited(SoLoud.instance.stop(h2));
    });
  }

  /// Updates the pitch of an already-playing [slot] without re-triggering.
  void updateFrequency(int slot, double frequency) {
    if (_voices.containsKey(slot)) _setSpeed(slot, frequency);
  }

  bool isPlaying(int slot) => _voices.containsKey(slot);

  void stopAll() {
    for (final slot in List<int>.from(_voices.keys)) {
      stopTone(slot);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _setSpeed(int slot, double frequency) {
    final pair = _voices[slot];
    if (pair == null) return;
    final (h1, h2) = pair;
    final speed = frequency / _kBaseFreq;
    SoLoud.instance.setRelativePlaySpeed(h1, speed);
    SoLoud.instance.setRelativePlaySpeed(h2, speed * pow(2.0, 2.0 / 1200.0));
  }
}
