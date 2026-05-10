import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quanta/core/constants/app_colors.dart';
import 'package:quanta/core/constants/app_typography.dart';
import 'package:quanta/features/tuner/presentation/providers/tuner_provider.dart';

class TuningKnob extends ConsumerStatefulWidget {
  const TuningKnob({super.key, required this.isCoarse});

  /// true = coarse (0.5 ¢/px), false = fine (0.05 ¢/px)
  final bool isCoarse;

  @override
  ConsumerState<TuningKnob> createState() => _TuningKnobState();
}

class _TuningKnobState extends ConsumerState<TuningKnob> {
  bool _dragging = false;

  /// Sensitivity: pixels of vertical drag → cents change.
  double get _sensitivity => widget.isCoarse ? 0.5 : 0.05;

  @override
  Widget build(BuildContext context) {
    // Knob angle mirrors the selected string's detuning:
    // ±50 cents maps to ±270° (±3π/2 radians).
    final detuning = ref.watch(
      tunerNotifierProvider.select(
        (s) => s.strings[s.selectedStringIndex].detuningCents,
      ),
    );
    final angle = (detuning / 50.0) * (3 * pi / 2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onPanStart: (_) {
            setState(() => _dragging = true);
            ref.read(tunerNotifierProvider.notifier).onKnobDragStart();
          },
          onPanUpdate: (d) {
            final delta = -d.delta.dy * _sensitivity;
            ref.read(tunerNotifierProvider.notifier).adjustDetuning(delta);
          },
          onPanEnd: (_) {
            setState(() => _dragging = false);
            ref.read(tunerNotifierProvider.notifier).onKnobDragEnd();
          },
          child: _KnobFace(
            angle: angle,
            isActive: _dragging,
            size: widget.isCoarse ? 100.0 : 80.0,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          widget.isCoarse ? 'COARSE' : 'FINE',
          style: AppTypography.cinzel(
            fontSize: 10,
            color: AppColors.onSurfaceMuted,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _KnobFace extends StatelessWidget {
  const _KnobFace({
    required this.angle,
    required this.isActive,
    required this.size,
  });

  final double angle;
  final bool isActive;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: isActive
                ? AppColors.gold.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.6),
            blurRadius: isActive ? 20 : 12,
            spreadRadius: isActive ? 2 : 0,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _KnobPainter(angle: angle, isActive: isActive),
      ),
    );
  }
}

class _KnobPainter extends CustomPainter {
  const _KnobPainter({required this.angle, required this.isActive});

  final double angle;
  final bool isActive;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = cx - 2;

    // Body gradient
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 1,
        colors: [
          AppColors.surfaceElevated.withValues(alpha: 1),
          AppColors.background,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r, bodyPaint);

    // Gold ring
    final ringPaint = Paint()
      ..color = isActive ? AppColors.gold : AppColors.goldDim
      ..style = PaintingStyle.stroke
      ..strokeWidth = isActive ? 1.5 : 1.0;
    canvas.drawCircle(Offset(cx, cy), r, ringPaint);

    // Inner ring (subtle depth)
    final innerRingPaint = Paint()
      ..color = AppColors.surfaceElevated
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawCircle(Offset(cx, cy), r - 6, innerRingPaint);

    // Indicator line (tuning peg marker)
    final markerPaint = Paint()
      ..color = isActive ? AppColors.gold : AppColors.onSurface
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const startRatio = 0.38;
    const endRatio = 0.78;
    final markerAngle = angle - pi / 2; // 0° points up
    canvas.drawLine(
      Offset(
        cx + cos(markerAngle) * r * startRatio,
        cy + sin(markerAngle) * r * startRatio,
      ),
      Offset(
        cx + cos(markerAngle) * r * endRatio,
        cy + sin(markerAngle) * r * endRatio,
      ),
      markerPaint,
    );

    // Centre dot
    canvas.drawCircle(
      Offset(cx, cy),
      3,
      Paint()..color = AppColors.onSurfaceMuted.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(_KnobPainter old) =>
      angle != old.angle || isActive != old.isActive;
}
