import 'package:flutter/material.dart';
import 'package:quanta/core/constants/app_colors.dart';
import 'package:quanta/core/constants/app_spacing.dart';

/// A container with an optional gold glow border that animates between
/// active (bright gold) and inactive (dim) states.
class GlowBorderContainer extends StatelessWidget {
  const GlowBorderContainer({
    super.key,
    required this.child,
    this.isActive = false,
    this.borderRadius = AppSpacing.radiusMd,
    this.color = AppColors.surface,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final bool isActive;
  final double borderRadius;
  final Color color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isActive
              ? AppColors.gold
              : AppColors.goldDim.withValues(alpha: 0.4),
          width: isActive ? 1.0 : 0.5,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.18),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
