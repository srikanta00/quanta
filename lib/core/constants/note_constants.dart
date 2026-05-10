abstract final class NoteConstants {
  /// Notes shown in the reference panel selector.
  static const List<String> referenceNotes = ['G3', 'D4', 'A4', 'E5'];

  /// Equal-temperament frequencies (A4 = 440 Hz).
  static const Map<String, double> referenceFrequencies = {
    'G3': 196.00,
    'D4': 293.66,
    'A4': 440.00,
    'E5': 659.25,
  };

  /// Violin strings from highest to lowest — matches physical orientation.
  static const List<String> stringNames = ['E5', 'A4', 'D4', 'G3'];

  /// Nominal open-string frequencies in the same order as [stringNames].
  static const List<double> stringNominalFreqs = [
    659.25,
    440.00,
    293.66,
    196.00,
  ];

  /// Visual stroke widths per string (E thinnest, G thickest).
  static const List<double> stringThicknesses = [1.5, 2.0, 2.5, 3.5];
}
