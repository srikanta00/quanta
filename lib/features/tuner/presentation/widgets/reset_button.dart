import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quanta/core/constants/app_colors.dart';
import 'package:quanta/core/constants/app_spacing.dart';
import 'package:quanta/core/constants/app_typography.dart';
import 'package:quanta/features/tuner/presentation/providers/tuner_provider.dart';
import 'package:quanta/shared/widgets/animated_press_button.dart';

class ResetButton extends ConsumerWidget {
  const ResetButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedPressButton(
      onTap: () => _onReset(context, ref),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: AppColors.goldDim.withValues(alpha: 0.6),
            width: 1,
          ),
          color: AppColors.surfaceElevated,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shuffle_rounded,
              color: AppColors.onSurfaceMuted,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'RESET',
              style: AppTypography.cinzel(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceMuted,
                letterSpacing: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onReset(BuildContext context, WidgetRef ref) {
    final anyPlaying = ref
        .read(tunerNotifierProvider)
        .strings
        .any((s) => s.isSounding);

    if (!anyPlaying) {
      ref.read(tunerNotifierProvider.notifier).reset();
      return;
    }

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(color: AppColors.goldDim.withValues(alpha: 0.4)),
        ),
        title: Text(
          'RESET TUNING',
          style: AppTypography.cinzel(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.gold,
            letterSpacing: 2,
          ),
        ),
        content: Text(
          'Some strings are currently sounding. Reset will randomise all string tunings.',
          style: AppTypography.inter(
            fontSize: 13,
            color: AppColors.onSurfaceMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'CANCEL',
              style: AppTypography.cinzel(
                fontSize: 12,
                color: AppColors.onSurfaceMuted,
                letterSpacing: 1.5,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(tunerNotifierProvider.notifier).reset();
            },
            child: Text(
              'RESET',
              style: AppTypography.cinzel(
                fontSize: 12,
                color: AppColors.gold,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
