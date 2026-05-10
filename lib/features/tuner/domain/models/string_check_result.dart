import 'package:flutter/material.dart';
import 'package:quanta/core/constants/app_colors.dart';

class StringCheckResult {
  final int stringIndex;
  final String nearestNote;
  final double centDeviation;

  const StringCheckResult({
    required this.stringIndex,
    required this.nearestNote,
    required this.centDeviation,
  });

  bool get isInTune => centDeviation.abs() <= 5;
  bool get isSharp => centDeviation > 5;
  bool get isFlat => centDeviation < -5;

  Color get indicatorColor {
    final abs = centDeviation.abs();
    if (abs <= 5) return AppColors.neutral;
    if (abs <= 20) return const Color(0xFFE07B3A); // orange mid-range
    return centDeviation > 0 ? AppColors.sharp : AppColors.flat;
  }

  String get centsLabel {
    final rounded = centDeviation.round();
    final sign = rounded >= 0 ? '+' : '';
    return '$sign$rounded¢';
  }
}
