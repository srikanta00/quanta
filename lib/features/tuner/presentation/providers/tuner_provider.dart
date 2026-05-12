import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quanta/core/constants/note_constants.dart';
import 'package:quanta/core/utils/math_utils.dart';
import 'package:quanta/features/tuner/data/audio_service.dart';
import 'package:quanta/features/tuner/domain/models/reference_note.dart';
import 'package:quanta/features/tuner/domain/models/string_check_result.dart';
import 'package:quanta/features/tuner/domain/models/violin_string.dart';
import 'package:quanta/features/tuner/domain/tuning_calculator.dart';

// ── State ────────────────────────────────────────────────────────────────────

class TunerState {
  final int selectedStringIndex;
  final List<ViolinString> strings;
  final ReferenceNote referenceNote;
  final List<StringCheckResult>? checkResults;

  const TunerState({
    required this.selectedStringIndex,
    required this.strings,
    required this.referenceNote,
    this.checkResults,
  });

  TunerState copyWith({
    int? selectedStringIndex,
    List<ViolinString>? strings,
    ReferenceNote? referenceNote,
    List<StringCheckResult>? checkResults,
    bool clearCheckResults = false,
  }) => TunerState(
    selectedStringIndex: selectedStringIndex ?? this.selectedStringIndex,
    strings: strings ?? this.strings,
    referenceNote: referenceNote ?? this.referenceNote,
    checkResults: clearCheckResults
        ? null
        : (checkResults ?? this.checkResults),
  );
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class TunerNotifier extends Notifier<TunerState> {
  // Tracks whether a knob drag started a tone that needs auto-stopping.
  bool _knobDragStartedPlay = false;

  AudioService get _audio => AudioService.instance;

  @override
  TunerState build() {
    ref.onDispose(_audio.stopAll);

    final strings = List.generate(
      NoteConstants.stringNames.length,
      (i) => ViolinString(
        name: NoteConstants.stringNames[i],
        nominalFreq: NoteConstants.stringNominalFreqs[i],
        detuningCents: 0.0,
        isSounding: false,
      ),
    );

    return TunerState(
      selectedStringIndex: 0,
      strings: strings,
      referenceNote: ReferenceNote(
        noteName: 'A4',
        frequency: NoteConstants.referenceFrequencies['A4']!,
        isPlaying: false,
      ),
    );
  }

  // ── String selection & toggle ─────────────────────────────────────────────

  void selectString(int index) {
    state = state.copyWith(selectedStringIndex: index);
  }

  void toggleString(int index) {
    final string = state.strings[index];
    final nowSounding = !string.isSounding;

    if (nowSounding) {
      _audio.playTone(index, string.currentFreq);
    } else {
      _audio.stopTone(index);
    }

    state = state.copyWith(
      strings: _updateString(index, string.copyWith(isSounding: nowSounding)),
    );
  }

  // ── Knob interaction ──────────────────────────────────────────────────────

  void onKnobDragStart() {
    final index = state.selectedStringIndex;
    final string = state.strings[index];
    if (!string.isSounding) {
      _audio.playTone(index, string.currentFreq);
      _knobDragStartedPlay = true;
    }
  }

  void onKnobDragEnd() {
    if (_knobDragStartedPlay) {
      _audio.stopTone(state.selectedStringIndex);
      _knobDragStartedPlay = false;
    }
  }

  void adjustDetuning(double deltaCents) {
    final index = state.selectedStringIndex;
    final string = state.strings[index];
    final newCents = clampD(string.detuningCents + deltaCents, -500.0, 500.0);
    final updated = string.copyWith(detuningCents: newCents);

    _audio.updateFrequency(index, updated.currentFreq);

    state = state.copyWith(
      strings: _updateString(index, updated),
      clearCheckResults: true,
    );
  }

  // ── Reference note ────────────────────────────────────────────────────────

  void selectReferenceNote(String noteName) {
    final freq = NoteConstants.referenceFrequencies[noteName]!;
    if (state.referenceNote.isPlaying) {
      _audio.updateFrequency(-1, freq);
    }
    state = state.copyWith(
      referenceNote: state.referenceNote.copyWith(
        noteName: noteName,
        frequency: freq,
      ),
    );
  }

  void toggleReferenceNote() {
    final note = state.referenceNote;
    if (note.isPlaying) {
      _audio.stopTone(-1);
      state = state.copyWith(referenceNote: note.copyWith(isPlaying: false));
    } else {
      _audio.playTone(-1, note.frequency);
      state = state.copyWith(referenceNote: note.copyWith(isPlaying: true));
    }
  }

  // ── Check & Reset ─────────────────────────────────────────────────────────

  void pluckString(int index) {
    final string = state.strings[index];
    if (string.isSounding) return; // already ringing continuously
    _audio.pluckTone(index, string.currentFreq);
  }

  void checkTuning() {
    state = state.copyWith(
      checkResults: TuningCalculator.checkAll(state.strings),
    );
  }

  void reset() {
    final rng = Random();
    final updated = state.strings.map((s) {
      final magnitude = rng.nextDouble() * 500.0; // 0–500 cents
      final sign = rng.nextBool() ? 1.0 : -1.0;
      final detunedString = s.copyWith(detuningCents: magnitude * sign);
      if (s.isSounding) {
        _audio.updateFrequency(
          state.strings.indexOf(s),
          detunedString.currentFreq,
        );
      }
      return detunedString;
    }).toList();

    state = state.copyWith(strings: updated, clearCheckResults: true);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  List<ViolinString> _updateString(int index, ViolinString updated) {
    final list = List<ViolinString>.from(state.strings);
    list[index] = updated;
    return list;
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final tunerNotifierProvider = NotifierProvider<TunerNotifier, TunerState>(
  TunerNotifier.new,
);
