import 'package:flutter/material.dart';
import 'package:quanta/core/constants/app_colors.dart';
import 'package:quanta/core/constants/app_spacing.dart';
import 'package:quanta/core/constants/app_typography.dart';
import 'package:quanta/core/constants/note_constants.dart';
import 'package:quanta/features/tuner/presentation/providers/tuner_provider.dart';
import 'package:quanta/shared/widgets/animated_press_button.dart';
import 'package:quanta/shared/widgets/glow_border_container.dart';
import 'package:quanta/shared/widgets/segmented_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReferenceNotePanel extends ConsumerWidget {
  const ReferenceNotePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = ref.watch(
      tunerNotifierProvider.select((s) => s.referenceNote),
    );
    final notifier = ref.read(tunerNotifierProvider.notifier);

    return GlowBorderContainer(
      isActive: note.isPlaying,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REFERENCE',
            style: AppTypography.cinzel(
              fontSize: 10,
              color: AppColors.onSurfaceMuted,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: SegmentedSelector(
                  options: NoteConstants.referenceNotes,
                  selected: note.noteName,
                  onSelected: notifier.selectReferenceNote,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _PlayToggle(
                isPlaying: note.isPlaying,
                onToggle: notifier.toggleReferenceNote,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlayToggle extends StatefulWidget {
  const _PlayToggle({required this.isPlaying, required this.onToggle});

  final bool isPlaying;
  final VoidCallback onToggle;

  @override
  State<_PlayToggle> createState() => _PlayToggleState();
}

class _PlayToggleState extends State<_PlayToggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didUpdateWidget(_PlayToggle old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.reset();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPressButton(
      onTap: widget.onToggle,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, _) {
          final glow = widget.isPlaying ? _pulse.value : 0.0;
          return Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isPlaying
                  ? AppColors.gold.withValues(alpha: 0.15 + glow * 0.12)
                  : AppColors.surfaceElevated,
              border: Border.all(
                color: widget.isPlaying ? AppColors.gold : AppColors.goldDim,
                width: 1,
              ),
              boxShadow: widget.isPlaying
                  ? [
                      BoxShadow(
                        color: AppColors.gold.withValues(
                          alpha: 0.3 + glow * 0.25,
                        ),
                        blurRadius: 12 + glow * 8,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              widget.isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
              color: widget.isPlaying
                  ? AppColors.gold
                  : AppColors.onSurfaceMuted,
              size: 22,
            ),
          );
        },
      ),
    );
  }
}
