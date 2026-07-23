import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grid_professionals/core/models/models.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';
import 'package:grid_professionals/core/widgets/app_widgets.dart';
import 'package:grid_professionals/features/onboarding/onboarding_summaries.dart';
import 'package:grid_professionals/state/onboarding_state.dart';

class OnboardingReviewScreen extends ConsumerWidget {
  const OnboardingReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final config = ref.watch(countryConfigProvider);
    final draft = state.draft;
    final allComplete = draft.isComplete(config);
    final resubmitting = state.status != ApplicationStatus.draft;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review your application'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => context.go('/onboarding'),
        ),
      ),
      body: SafeArea(
        child: AppPage(
          children: [
            Text(
              resubmitting
                  ? 'Check the updated sections, then resubmit your '
                        'application.'
                  : 'Check everything before you submit. You can still edit '
                        'sections while your application is under review.',
              style: const TextStyle(color: AppColors.muted),
            ),
            if (!allComplete) ...[
              const SizedBox(height: 14),
              const StatusBanner(
                kind: StatusKind.actionRequired,
                title: 'Some sections are incomplete',
                message: 'Finish the sections marked below before submitting.',
              ),
            ],
            for (final stage in OnboardingStage.values) ...[
              SectionHeader(stage.title),
              AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    for (final step in stage.steps) ...[
                      _ReviewRow(
                        step: step,
                        summary: sectionSummary(draft, config, step),
                        complete:
                            draft.statusOf(step, config) ==
                            SectionStatus.complete,
                        onEdit: () {
                          controller.goToStep(step);
                          context.push('/onboarding/flow?from=review');
                        },
                      ),
                      if (step != stage.steps.last) const Divider(height: 1),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: draft.agreedToStandards,
              onChanged: (value) => controller.updateDraft(
                (draft) => draft.copyWith(agreedToStandards: value ?? false),
              ),
              title: const Text(
                'I agree to the GRID professional standards: honest quotes, '
                'punctuality, safe work and respect for customers\' homes.',
                style: TextStyle(fontSize: 13.5, height: 1.45),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        label: resubmitting ? 'Resubmit application' : 'Submit application',
        busy: state.submitting,
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
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                summary ?? (complete ? 'Complete' : 'Not filled in yet'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
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
