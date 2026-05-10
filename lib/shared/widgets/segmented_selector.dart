import 'package:flutter/material.dart';
import 'package:quanta/core/constants/app_colors.dart';
import 'package:quanta/core/constants/app_spacing.dart';
import 'package:quanta/core/constants/app_typography.dart';

/// A custom horizontal segmented control with gold highlight on selection.
class SegmentedSelector extends StatelessWidget {
  const SegmentedSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: AppColors.goldDim.withValues(alpha: 0.35),
          width: 0.5,
        ),
      ),
      child: Row(
        children: options.map((option) {
          final isSelected = option == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.gold.withValues(alpha: 0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm - 1),
                  border: isSelected
                      ? Border.all(color: AppColors.gold, width: 1)
                      : null,
                ),
                child: Center(
                  child: Text(
                    option,
                    style: AppTypography.cinzel(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.gold
                          : AppColors.onSurfaceMuted,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
