import 'dart:math';

/// Returns the MIDI note number closest to [freq].
int freqToMidi(double freq) => (69 + 12 * log(freq / 440.0) / log(2)).round();

/// Converts a MIDI note number to its frequency in Hz.
double midiToFreq(int midi) => 440.0 * pow(2.0, (midi - 69) / 12.0);

/// Returns the note name for a MIDI note number (e.g. 69 → "A4").
String midiToNoteName(int midi) {
  const names = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];
  final octave = (midi ~/ 12) - 1;
  final index = midi % 12;
  return '${names[index]}$octave';
}

/// Cents deviation of [freq] from the nearest semitone.
/// Negative = flat, positive = sharp.  Range: (−50, +50].
double centDeviation(double freq) {
  final midi = freqToMidi(freq);
  final nearestFreq = midiToFreq(midi);
  return 1200.0 * log(freq / nearestFreq) / log(2);
}

/// Applies [cents] of detuning to [nominalFreq].
double applyDetuning(double nominalFreq, double cents) =>
    nominalFreq * pow(2.0, cents / 1200.0);
