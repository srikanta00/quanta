import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quanta/core/constants/app_colors.dart';
import 'package:quanta/core/constants/app_spacing.dart';
import 'package:quanta/core/constants/app_typography.dart';
import 'package:quanta/features/tuner/presentation/providers/tuner_provider.dart';
import 'package:quanta/shared/widgets/animated_press_button.dart';

class CheckButton extends ConsumerWidget {
  const CheckButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedPressButton(
      onTap: () => ref.read(tunerNotifierProvider.notifier).checkTuning(),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.gold, width: 1),
          color: AppColors.gold.withValues(alpha: 0.12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.tune_rounded, color: AppColors.gold, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'CHECK',
              style: AppTypography.cinzel(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.gold,
                letterSpacing: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
