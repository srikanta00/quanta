import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quanta/core/constants/app_colors.dart';
import 'package:quanta/core/constants/app_typography.dart';
import 'package:quanta/features/tuner/presentation/providers/tuner_provider.dart';

/// A horizontal scroll-wheel tuning control.
/// Drag left/right to detune the selected string.
///   Coarse: 0.5 ¢/px   Fine: 0.08 ¢/px
class TuningKnob extends ConsumerStatefulWidget {
  const TuningKnob({super.key, required this.isCoarse});

  final bool isCoarse;

  @override
  ConsumerState<TuningKnob> createState() => _TuningKnobState();
}

class _TuningKnobState extends ConsumerState<TuningKnob> {
  bool _dragging = false;

  double get _sensitivity => widget.isCoarse ? 0.5 : 0.08;

  @override
  Widget build(BuildContext context) {
    final detuning = ref.watch(
      tunerNotifierProvider.select(
        (s) => s.strings[s.selectedStringIndex].detuningCents,
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.isCoarse ? 'COARSE' : 'FINE',
          textAlign: TextAlign.center,
          style: AppTypography.cinzel(
            fontSize: 10,
            color: AppColors.onSurfaceMuted,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) {
            setState(() => _dragging = true);
            ref.read(tunerNotifierProvider.notifier).onKnobDragStart();
          },
          onPanUpdate: (d) {
            final delta = d.delta.dx * _sensitivity;
            ref.read(tunerNotifierProvider.notifier).adjustDetuning(delta);
          },
          onPanEnd: (_) {
            setState(() => _dragging = false);
            ref.read(tunerNotifierProvider.notifier).onKnobDragEnd();
          },
          child: _WheelFace(detuning: detuning, isActive: _dragging),
        ),
      ],
    );
  }
}

// ── Wheel face ────────────────────────────────────────────────────────────────

class _WheelFace extends StatelessWidget {
  const _WheelFace({required this.detuning, required this.isActive});

  final double detuning;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? AppColors.gold.withValues(alpha: 0.28)
                : Colors.black.withValues(alpha: 0.55),
            blurRadius: isActive ? 18 : 8,
            spreadRadius: isActive ? 1 : 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CustomPaint(
          painter: _WheelPainter(detuning: detuning, isActive: isActive),
          size: Size.infinite,
        ),
      ),
    );
  }
}

// ── Wheel painter ─────────────────────────────────────────────────────────────

class _WheelPainter extends CustomPainter {
  const _WheelPainter({required this.detuning, required this.isActive});

  final double detuning;
  final bool isActive;

  /// Pixels per cent of detuning — controls tick density.
  static const _pxPerCent = 7.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // ── Background ────────────────────────────────────────────────────────────
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.surfaceElevated, AppColors.background],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // ── Tick marks ────────────────────────────────────────────────────────────
    final visibleCents = w / _pxPerCent;
    final minC = (detuning - visibleCents / 2).floor() - 1;
    final maxC = (detuning + visibleCents / 2).ceil() + 1;

    for (int c = minC; c <= maxC; c++) {
      final x = cx + (c - detuning) * _pxPerCent;
      if (x < 0 || x > w) continue;

      final bool isMajor = c % 10 == 0;
      final bool isMid = c % 5 == 0;

      final double tickH;
      final Color tickColor;
      final double strokeW;

      if (isMajor) {
        tickH = h * 0.60;
        tickColor = isActive
            ? AppColors.gold.withValues(alpha: 0.9)
            : AppColors.onSurface.withValues(alpha: 0.55);
        strokeW = 1.5;
      } else if (isMid) {
        tickH = h * 0.35;
        tickColor = AppColors.onSurfaceMuted.withValues(alpha: 0.45);
        strokeW = 1.0;
      } else {
        tickH = h * 0.18;
        tickColor = AppColors.onSurfaceMuted.withValues(alpha: 0.2);
        strokeW = 0.6;
      }

      final topY = (h - tickH) / 2;
      canvas.drawLine(
        Offset(x, topY),
        Offset(x, topY + tickH),
        Paint()
          ..color = tickColor
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );
    }

    // ── Center indicator line (fixed) ─────────────────────────────────────────
    canvas.drawLine(
      Offset(cx, 5),
      Offset(cx, h - 5),
      Paint()
        ..color = isActive
            ? AppColors.gold
            : AppColors.gold.withValues(alpha: 0.75)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    // ── Edge fade ─────────────────────────────────────────────────────────────
    const fadeW = 36.0;
    const fadeColor = AppColors.background;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, fadeW, h),
      Paint()
        ..shader = LinearGradient(
          colors: [fadeColor, fadeColor.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, 0, fadeW, h)),
    );
    canvas.drawRect(
      Rect.fromLTWH(w - fadeW, 0, fadeW, h),
      Paint()
        ..shader = LinearGradient(
          colors: [fadeColor.withValues(alpha: 0), fadeColor],
        ).createShader(Rect.fromLTWH(w - fadeW, 0, fadeW, h)),
    );

    // ── Border ────────────────────────────────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(0.5, 0.5, w - 1, h - 1),
      Paint()
        ..color = isActive
            ? AppColors.gold.withValues(alpha: 0.8)
            : AppColors.goldDim.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isActive ? 1.5 : 1.0,
    );
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      detuning != old.detuning || isActive != old.isActive;
}
