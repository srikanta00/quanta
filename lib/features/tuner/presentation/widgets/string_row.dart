import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quanta/core/constants/app_colors.dart';
import 'package:quanta/core/constants/app_spacing.dart';
import 'package:quanta/core/constants/app_typography.dart';
import 'package:quanta/core/constants/note_constants.dart';
import 'package:quanta/features/tuner/domain/models/string_check_result.dart';
import 'package:quanta/features/tuner/domain/models/violin_string.dart';
import 'package:quanta/features/tuner/presentation/providers/tuner_provider.dart';
import 'package:quanta/features/tuner/presentation/widgets/cent_deviation_bar.dart';
import 'package:quanta/features/tuner/presentation/widgets/string_vibration_painter.dart';

class StringRow extends ConsumerStatefulWidget {
  const StringRow({super.key, required this.index});

  final int index;

  @override
  ConsumerState<StringRow> createState() => _StringRowState();
}

class _StringRowState extends ConsumerState<StringRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _vibCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  late final Animation<double> _phase = Tween<double>(
    begin: 0,
    end: 2 * pi,
  ).animate(_vibCtrl);

  @override
  void dispose() {
    _vibCtrl.dispose();
    super.dispose();
  }

  /// Triggers a short pluck sound + vibration animation on the string.
  /// No-ops if the string is already sounding continuously.
  void _pluck() {
    ref.read(tunerNotifierProvider.notifier).pluckString(widget.index);
    // Drive the vibration animation for the duration of the pluck decay.
    final isSounding = ref
        .read(tunerNotifierProvider)
        .strings[widget.index]
        .isSounding;
    if (isSounding) return; // animation already running via listener
    _vibCtrl.repeat();
    Future.delayed(const Duration(milliseconds: 550), () {
      if (!mounted) return;
      final stillSounding = ref
          .read(tunerNotifierProvider)
          .strings[widget.index]
          .isSounding;
      if (!stillSounding) {
        _vibCtrl.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final string = ref.watch(
      tunerNotifierProvider.select((s) => s.strings[widget.index]),
    );
    final isSelected = ref.watch(
      tunerNotifierProvider.select(
        (s) => s.selectedStringIndex == widget.index,
      ),
    );
    final checkResult = ref.watch(
      tunerNotifierProvider.select((s) => s.checkResults?[widget.index]),
    );

    ref.listen(
      tunerNotifierProvider.select((s) => s.strings[widget.index].isSounding),
      (_, isSounding) {
        if (isSounding) {
          _vibCtrl.repeat();
        } else {
          _vibCtrl.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      },
    );

    return GestureDetector(
      onTap: () =>
          ref.read(tunerNotifierProvider.notifier).selectString(widget.index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : AppColors.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected
                ? AppColors.gold.withValues(alpha: 0.55)
                : AppColors.goldDim.withValues(alpha: 0.2),
            width: isSelected ? 0.8 : 0.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.08),
                    blurRadius: 16,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _StringLabel(string: string, isSelected: isSelected),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Listener(
                      onPointerDown: (_) => _pluck(),
                      child: _StringLine(
                        index: widget.index,
                        string: string,
                        isSelected: isSelected,
                        phaseAnimation: _phase,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _SoundToggle(
                    isSounding: string.isSounding,
                    onToggle: () => ref
                        .read(tunerNotifierProvider.notifier)
                        .toggleString(widget.index),
                  ),
                ],
              ),
              // Always reserve the check-result space so the layout below
              // (tuning wheels) never shifts when check mode toggles.
              // 29px = ~14px text line metrics + 3px gap + 12px bar.
              const SizedBox(height: 2),
              SizedBox(
                height: 29,
                child: AnimatedOpacity(
                  opacity: checkResult != null ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: checkResult != null
                      ? _AnimatedCheckResult(
                          result: checkResult,
                          freq: string.currentFreq,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _StringLabel extends StatelessWidget {
  const _StringLabel({required this.string, required this.isSelected});

  final ViolinString string;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: Text(
        string.name,
        style: AppTypography.cinzel(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isSelected ? AppColors.gold : AppColors.onSurfaceMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StringLine extends StatelessWidget {
  const _StringLine({
    required this.index,
    required this.string,
    required this.isSelected,
    required this.phaseAnimation,
  });

  final int index;
  final ViolinString string;
  final bool isSelected;
  final Animation<double> phaseAnimation;

  @override
  Widget build(BuildContext context) {
    final thickness = NoteConstants.stringThicknesses[index];
    final color = isSelected
        ? AppColors.stringSelected
        : string.isSounding
        ? AppColors.string
        : AppColors.stringMuted;

    return SizedBox(
      height: 22,
      child: AnimatedBuilder(
        animation: phaseAnimation,
        builder: (_, _) => CustomPaint(
          painter: StringVibrationPainter(
            amplitude: string.isSounding
                ? 0.4 + 0.6 * (0.5 + 0.5 * sin(phaseAnimation.value))
                : 0.0,
            phase: phaseAnimation.value,
            color: color,
            thickness: thickness,
          ),
          size: const Size(double.infinity, 22),
        ),
      ),
    );
  }
}

class _SoundToggle extends StatelessWidget {
  const _SoundToggle({required this.isSounding, required this.onToggle});

  final bool isSounding;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: GestureDetector(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSounding
                ? AppColors.gold.withValues(alpha: 0.18)
                : Colors.transparent,
            border: Border.all(
              color: isSounding ? AppColors.gold : AppColors.goldDim,
              width: 1,
            ),
          ),
          child: Icon(
            isSounding ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            size: 16,
            color: isSounding ? AppColors.gold : AppColors.onSurfaceMuted,
          ),
        ),
      ),
    );
  }
}

class _AnimatedCheckResult extends StatelessWidget {
  const _AnimatedCheckResult({required this.result, required this.freq});

  final StringCheckResult result;
  final double freq;

  @override
  Widget build(BuildContext context) {
    // Match the string row's column structure exactly so the bar is centered
    // under the string line:
    //   [36px blank] [8px gap] [Expanded] [4px gap] [36px blank]
    return Row(
      children: [
        const SizedBox(width: 36), // aligns with string-name label
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    '${freq.toStringAsFixed(1)} Hz',
                    style: AppTypography.mono(
                      fontSize: 9,
                      color: AppColors.onSurfaceMuted,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    result.nearestNote,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: result.indicatorColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    result.centsLabel,
                    style: TextStyle(
                      fontSize: 9,
                      color: result.indicatorColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              SizedBox(height: 12, child: CentDeviationBar(result: result)),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        const SizedBox(width: 36), // aligns with sound-toggle button
      ],
    );
  }
}
