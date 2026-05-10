import 'dart:math';

class ViolinString {
  final String name;
  final double nominalFreq;
  final double detuningCents;
  final bool isSounding;

  const ViolinString({
    required this.name,
    required this.nominalFreq,
    required this.detuningCents,
    required this.isSounding,
  });

  /// Actual sounding frequency after detuning is applied.
  double get currentFreq => nominalFreq * pow(2.0, detuningCents / 1200.0);

  ViolinString copyWith({
    String? name,
    double? nominalFreq,
    double? detuningCents,
    bool? isSounding,
  }) => ViolinString(
    name: name ?? this.name,
    nominalFreq: nominalFreq ?? this.nominalFreq,
    detuningCents: detuningCents ?? this.detuningCents,
    isSounding: isSounding ?? this.isSounding,
  );
}
