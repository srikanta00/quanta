import 'package:quanta/core/utils/audio_utils.dart';
import 'models/violin_string.dart';
import 'models/string_check_result.dart';

abstract final class TuningCalculator {
  static StringCheckResult checkString(int index, ViolinString string) {
    final freq = string.currentFreq;
    final deviation = centDeviation(freq);
    final nearestMidi = freqToMidi(freq);
    final noteName = midiToNoteName(nearestMidi);
    return StringCheckResult(
      stringIndex: index,
      nearestNote: noteName,
      centDeviation: deviation,
    );
  }

  static List<StringCheckResult> checkAll(List<ViolinString> strings) =>
      strings.asMap().entries.map((e) => checkString(e.key, e.value)).toList();
}
