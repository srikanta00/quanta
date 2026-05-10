import 'dart:math';
import 'package:flutter/material.dart';
import 'package:quanta/core/constants/app_colors.dart';

/// Paints a violin string as either a straight line or a sine-wave vibration.
class StringVibrationPainter extends CustomPainter {
  const StringVibrationPainter({
    required this.amplitude,
    required this.phase,
    required this.color,
    required this.thickness,
  });

  final double amplitude; // 0.0 – 1.0
  final double phase; // 0.0 – 2π
  final Color color;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.height / 2;

    // Gradient shimmer along the string.
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0.3),
          color,
          color,
          color.withValues(alpha: 0.3),
        ],
        stops: const [0, 0.15, 0.85, 1],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, cx);

    if (amplitude > 0.005) {
      const waveCount = 3.0;
      for (double x = 0; x <= size.width; x += 1) {
        final y =
            cx +
            amplitude *
                8.0 *
                sin(2 * pi * waveCount * x / size.width + phase) *
                sin(pi * x / size.width); // envelope to fade at edges
        path.lineTo(x, y);
      }
    } else {
      path.lineTo(size.width, cx);
    }

    canvas.drawPath(path, paint);

    // Highlight line (thin bright strip) for 3-D effect.
    if (thickness > 2) {
      final highlightPaint = Paint()
        ..color = AppColors.stringSelected.withValues(alpha: 0.25)
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(0, cx - thickness * 0.3),
        Offset(size.width, cx - thickness * 0.3),
        highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(StringVibrationPainter old) =>
      amplitude != old.amplitude || phase != old.phase || color != old.color;
}
