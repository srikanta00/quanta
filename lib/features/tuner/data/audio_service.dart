import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// Base frequency a SoLoud waveform oscillator produces at relativePlaySpeed = 1.0.
/// SoLoud waveforms default to A4 = 440 Hz.
const double _kBaseFreq = 440.0;

/// Slot mapping:
///   -1  → reference note
///  0–3  → violin strings E5, A4, D4, G3
typedef _VoicePair = (SoundHandle, SoundHandle);

/// Singleton wrapper around flutter_soloud.
///
/// All 5 voice pairs are pre-allocated at [init] time and run continuously at
/// volume 0. Playing a tone = setVolume to audible; stopping = setVolume to 0.
/// This makes [playTone] and [stopTone] fully synchronous and race-condition-free.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  AudioSource? _source;

  /// Slots: -1 (reference), 0–3 (strings). Pre-allocated at init.
  final Map<int, _VoicePair> _voices = {};

  bool _initialized = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;
    try {
      await SoLoud.instance.init();
      _source = await SoLoud.instance.loadWaveform(
        WaveForm.sin,
        false, // superWave
        0.5, // scale (amplitude)
        0, // detune
      );

      // Pre-allocate all 5 voice pairs (reference + 4 strings).
      // Primary oscillator: full frequency.  Secondary: +2 ¢ for warmth.
      for (int slot = -1; slot <= 3; slot++) {
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
        _voices[slot] = (h1, h2);
      }
      _initialized = true;
    } catch (e) {
      if (kDebugMode) debugPrint('[AudioService] init error: $e');
    }
  }

  Future<void> dispose() async {
    _silenceAll();
    if (_source != null) await SoLoud.instance.disposeSource(_source!);
    if (_initialized) SoLoud.instance.deinit();
    _initialized = false;
  }

  // ── Playback (fully synchronous) ──────────────────────────────────────────

  /// Sounds [slot] at [frequency] Hz.
  void playTone(int slot, double frequency) {
    if (!_initialized) return;
    final pair = _voices[slot];
    if (pair == null) return;
    final (h1, h2) = pair;
    _setPitch(h1, h2, frequency);
    SoLoud.instance.setVolume(h1, 0.6);
    SoLoud.instance.setVolume(h2, 0.3);
  }

  /// Silences [slot] immediately.
  void stopTone(int slot) {
    if (!_initialized) return;
    final pair = _voices[slot];
    if (pair == null) return;
    final (h1, h2) = pair;
    SoLoud.instance.setVolume(h1, 0.0);
    SoLoud.instance.setVolume(h2, 0.0);
  }

  /// Updates pitch of an already-sounding [slot] in real time.
  void updateFrequency(int slot, double frequency) {
    if (!_initialized) return;
    final pair = _voices[slot];
    if (pair == null) return;
    _setPitch(pair.$1, pair.$2, frequency);
  }

  bool isPlaying(int slot) {
    if (!_initialized) return false;
    final pair = _voices[slot];
    if (pair == null) return false;
    // A slot is "playing" if its primary handle has non-zero volume.
    return SoLoud.instance.getVolume(pair.$1) > 0;
  }

  void stopAll() {
    if (!_initialized) return;
    _silenceAll();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _setPitch(SoundHandle h1, SoundHandle h2, double frequency) {
    final speed = frequency / _kBaseFreq;
    SoLoud.instance.setRelativePlaySpeed(h1, speed);
    SoLoud.instance.setRelativePlaySpeed(h2, speed * pow(2.0, 2.0 / 1200.0));
  }

  void _silenceAll() {
    for (final pair in _voices.values) {
      SoLoud.instance.setVolume(pair.$1, 0.0);
      SoLoud.instance.setVolume(pair.$2, 0.0);
    }
  }
}
