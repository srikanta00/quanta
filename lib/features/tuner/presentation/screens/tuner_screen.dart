import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quanta/core/constants/app_colors.dart';
import 'package:quanta/core/constants/app_spacing.dart';
import 'package:quanta/core/constants/app_typography.dart';
import 'package:quanta/features/tuner/presentation/widgets/check_button.dart';
import 'package:quanta/features/tuner/presentation/widgets/reference_note_panel.dart';
import 'package:quanta/features/tuner/presentation/widgets/reset_button.dart';
import 'package:quanta/features/tuner/presentation/widgets/string_row.dart';
import 'package:quanta/features/tuner/presentation/widgets/tuning_knob.dart';

class TunerScreen extends ConsumerWidget {
  const TunerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.sm),
              _AppHeader(),
              const SizedBox(height: AppSpacing.sm),
              // ── Reference note panel ──────────────────────────────────────
              const ReferenceNotePanel(),
              const SizedBox(height: AppSpacing.sm),
              // ── 4 string rows ─────────────────────────────────────────────
              const StringRow(index: 0),
              const StringRow(index: 1),
              const StringRow(index: 2),
              const StringRow(index: 3),
              const SizedBox(height: AppSpacing.sm),
              // ── Tuning knobs ──────────────────────────────────────────────
              _KnobSection(),
              const SizedBox(height: AppSpacing.sm),
              // ── Action buttons ────────────────────────────────────────────
              const Row(
                children: [
                  Expanded(child: CheckButton()),
                  SizedBox(width: AppSpacing.md),
                  Expanded(child: ResetButton()),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
          ),
        ),
      ),
    );
  }
}

// ── App header ────────────────────────────────────────────────────────────────

class _AppHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          'QUANTA',
          style: AppTypography.cinzel(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.gold,
            letterSpacing: 6,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'VIOLIN TUNER',
          style: AppTypography.cinzel(
            fontSize: 11,
            color: AppColors.onSurfaceMuted,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}

// ── Knob section ──────────────────────────────────────────────────────────────

class _KnobSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.goldDim.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            'TUNING',
            style: AppTypography.cinzel(
              fontSize: 10,
              color: AppColors.onSurfaceMuted,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: TuningKnob(isCoarse: true)),
              SizedBox(width: AppSpacing.md),
              Expanded(child: TuningKnob(isCoarse: false)),
            ],
          ),
        ],
      ),
    );
  }
}
