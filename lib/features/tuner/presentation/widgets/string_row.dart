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
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
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
            vertical: AppSpacing.sm,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _StringLabel(string: string, isSelected: isSelected),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _StringLine(
                      index: widget.index,
                      string: string,
                      isSelected: isSelected,
                      phaseAnimation: _phase,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _HzLabel(freq: string.currentFreq),
                  const SizedBox(width: AppSpacing.xs),
                  _SoundToggle(
                    isSounding: string.isSounding,
                    onToggle: () => ref
                        .read(tunerNotifierProvider.notifier)
                        .toggleString(widget.index),
                  ),
                ],
              ),
              if (checkResult != null) ...[
                const SizedBox(height: AppSpacing.xs),
                _AnimatedCheckResult(result: checkResult),
              ],
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
      height: 28,
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
          size: const Size(double.infinity, 28),
        ),
      ),
    );
  }
}

class _HzLabel extends StatelessWidget {
  const _HzLabel({required this.freq});

  final double freq;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      child: Text(
        '${freq.toStringAsFixed(1)} Hz',
        textAlign: TextAlign.right,
        style: AppTypography.mono(
          fontSize: 11,
          color: AppColors.onSurfaceMuted,
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
  const _AnimatedCheckResult({required this.result});

  final StringCheckResult result;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 38, child: CentDeviationBar(result: result));
  }
}
