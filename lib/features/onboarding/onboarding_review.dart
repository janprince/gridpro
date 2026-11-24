import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grid_professionals/core/models/models.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';
import 'package:grid_professionals/core/widgets/app_widgets.dart';
import 'package:grid_professionals/features/onboarding/onboarding_summaries.dart';
import 'package:grid_professionals/state/onboarding_state.dart';

class OnboardingReviewScreen extends ConsumerStatefulWidget {
  const OnboardingReviewScreen({super.key});

  @override
  ConsumerState<OnboardingReviewScreen> createState() =>
      _OnboardingReviewScreenState();
}

class _OnboardingReviewScreenState
    extends ConsumerState<OnboardingReviewScreen> {
  @override
  void initState() {
    super.initState();
    // GRID decides what "complete" means; ask it as soon as the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingControllerProvider.notifier).refreshReadiness();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final config = ref.watch(countryConfigProvider);
    final draft = state.draft;
    final allComplete = draft.isComplete(config);
    final resubmitting = state.status != ApplicationStatus.draft;

    return FocusPage(
      title: 'Review your application',
      onBack: () => context.go('/onboarding'),
      actions: [
        PrimaryButton(
          label: resubmitting ? 'Resubmit application' : 'Submit application',
          busy: state.submitting,
          busyLabel: 'Submitting',
          onPressed: allComplete && draft.agreedToStandards
              ? () async {
                  await controller.submit();
                  if (context.mounted) context.go('/application-status');
                }
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        allComplete
                            ? 'Agree to the professional standards to submit.'
                            : 'Complete the highlighted sections first.',
                      ),
                    ),
                  );
                },
        ),
      ],
      children: [
        Text(
          resubmitting
              ? 'Check the updated sections, then resubmit your application.'
              : 'Check everything before you submit. You can still edit '
                    'sections while we review it.',
          style: AppText.bodyMuted,
        ),
        if (!allComplete) ...[
          const SizedBox(height: 14),
          const StatusBanner(
            kind: StatusKind.actionRequired,
            title: 'Some sections are incomplete',
            message: 'Finish the sections marked below before submitting.',
          ),
        ],
        // GRID's own checks. These can flag things local validation cannot
        // see, such as a document that failed review.
        if (state.serverRequirements.isNotEmpty) ...[
          const SizedBox(height: 14),
          StatusBanner(
            kind: StatusKind.actionRequired,
            title: 'GRID still needs',
            message: state.serverRequirements.map((r) => r.message).join('\n'),
          ),
        ],
        if (state.offline) ...[
          const SizedBox(height: 14),
          const StatusBanner(
            kind: StatusKind.neutral,
            title: 'Saved on this device',
            message:
                'You are offline. Everything you entered is safe and will be '
                'sent to GRID when you reconnect.',
          ),
        ],
        for (final stage in OnboardingStage.values) ...[
          SectionHeader(stage.title),
          MenuGroupShell(
            children: [
              for (final step in stage.steps)
                _ReviewRow(
                  step: step,
                  summary: sectionSummary(draft, config, step),
                  complete:
                      draft.statusOf(step, config) == SectionStatus.complete,
                  onEdit: () {
                    controller.goToStep(step);
                    context.push('/onboarding/flow?from=review');
                  },
                ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        Material(
          color: AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(AppRadius.md),
          clipBehavior: Clip.antiAlias,
          child: CheckboxListTile(
            contentPadding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
            controlAffinity: ListTileControlAffinity.leading,
            value: draft.agreedToStandards,
            onChanged: (value) => controller.updateDraft(
              (draft) => draft.copyWith(agreedToStandards: value ?? false),
            ),
            title: const Text(
              'I agree to the GRID professional standards: fair prices, '
              'punctuality, care with people\'s homes and belongings.',
              style: TextStyle(fontSize: 14, height: 1.45),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.step,
    required this.summary,
    required this.complete,
    required this.onEdit,
  });

  final OnboardingStep step;
  final String? summary;
  final bool complete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 6, 10),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.title, style: AppText.subtitle),
              const SizedBox(height: 2),
              Text(
                summary ?? (complete ? 'Complete' : 'Not filled in yet'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption.copyWith(
                  color: complete ? AppColors.muted : AppColors.warningText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        TextButton(onPressed: onEdit, child: const Text('Edit')),
      ],
    ),
  );
}
