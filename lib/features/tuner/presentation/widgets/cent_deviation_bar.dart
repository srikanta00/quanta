import 'package:flutter/material.dart';
import 'package:quanta/core/constants/app_colors.dart';
import 'package:quanta/features/tuner/domain/models/string_check_result.dart';

/// Horizontal bar + label showing how many cents sharp or flat a string is.
class CentDeviationBar extends StatefulWidget {
  const CentDeviationBar({super.key, required this.result});

  final StringCheckResult result;

  @override
  State<CentDeviationBar> createState() => _CentDeviationBarState();
}

class _CentDeviationBarState extends State<CentDeviationBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late Animation<double> _centsAnim;

  @override
  void initState() {
    super.initState();
    _centsAnim = Tween<double>(
      begin: 0,
      end: widget.result.centDeviation,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(CentDeviationBar old) {
    super.didUpdateWidget(old);
    if (widget.result.centDeviation != old.result.centDeviation) {
      _centsAnim = Tween<double>(
        begin: _centsAnim.value,
        end: widget.result.centDeviation,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _centsAnim,
      builder: (_, _) {
        final cents = _centsAnim.value;
        final color = widget.result.indicatorColor;
        // Needle position: 0.5 = center, 0.0 = −50¢, 1.0 = +50¢
        final t = (cents / 50.0).clamp(-1.0, 1.0) * 0.5 + 0.5;

        return Column(
          children: [
            SizedBox(
              height: 18,
              child: CustomPaint(
                painter: _BarPainter(needlePos: t, color: color),
                size: const Size(double.infinity, 18),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.result.nearestNote,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  widget.result.centsLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _BarPainter extends CustomPainter {
  const _BarPainter({required this.needlePos, required this.color});

  final double needlePos; // 0.0–1.0
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.height / 2;

    // Track
    final trackPaint = Paint()
      ..color = AppColors.surfaceElevated
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, cx - 2, size.width, 4),
        const Radius.circular(2),
      ),
      trackPaint,
    );

    // Centre tick
    final tickPaint = Paint()
      ..color = AppColors.onSurfaceMuted.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width / 2, cx - 6),
      Offset(size.width / 2, cx + 6),
      tickPaint,
    );

    // Filled range from centre to needle
    final centre = size.width / 2;
    final nx = needlePos * size.width;
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          nx < centre ? nx : centre,
          cx - 2,
          nx < centre ? centre : nx,
          cx + 2,
        ),
        const Radius.circular(2),
      ),
      fillPaint,
    );

    // Needle
    final needlePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(nx, cx - 7), Offset(nx, cx + 7), needlePaint);
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      needlePos != old.needlePos || color != old.color;
}
