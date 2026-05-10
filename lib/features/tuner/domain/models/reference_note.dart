class ReferenceNote {
  final String noteName;
  final double frequency;
  final bool isPlaying;

  const ReferenceNote({
    required this.noteName,
    required this.frequency,
    required this.isPlaying,
  });

  ReferenceNote copyWith({
    String? noteName,
    double? frequency,
    bool? isPlaying,
  }) => ReferenceNote(
    noteName: noteName ?? this.noteName,
    frequency: frequency ?? this.frequency,
    isPlaying: isPlaying ?? this.isPlaying,
  );
}
