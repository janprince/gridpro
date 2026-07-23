import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grid_professionals/core/models/models.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';
import 'package:grid_professionals/core/widgets/app_widgets.dart';
import 'package:grid_professionals/features/onboarding/onboarding_summaries.dart';
import 'package:grid_professionals/state/app_state.dart';
import 'package:grid_professionals/state/onboarding_state.dart';

/// Application overview: every section with its status. This is where a
/// returning provider resumes, and how completed sections are re-opened.
class OnboardingHubScreen extends ConsumerWidget {
  const OnboardingHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final config = ref.watch(countryConfigProvider);
    final draft = state.draft;

    final completed = OnboardingStep.values
        .where((step) => draft.statusOf(step, config) == SectionStatus.complete)
        .length;
    final total = OnboardingStep.values.length;
    final allComplete = completed == total;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your application'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: AppPage(
          children: [
            Text(
              allComplete
                  ? 'Everything is filled in. Review your application and '
                        'submit it for verification.'
                  : 'Complete each section to submit your profile for '
                        'verification. Your progress saves automatically.',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: completed / total,
                      minHeight: 7,
                      semanticsLabel: 'Application progress',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$completed of $total',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            for (final stage in OnboardingStage.values) ...[
              SectionHeader(stage.title),
              AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    for (final step in stage.steps) ...[
                      SectionStatusTile(
                        title: step.title,
                        status: draft.statusOf(step, config),
                        summary:
                            draft.statusOf(step, config) ==
                                SectionStatus.notStarted
                            ? null
                            : sectionSummary(draft, config, step),
                        onTap: () {
                          controller.goToStep(step);
                          context.push('/onboarding/flow');
                        },
                      ),
                      if (step != stage.steps.last) const Divider(height: 1),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () async {
                  final confirmed = await showConfirmationSheet(
                    context,
                    title: 'Start over?',
                    message:
                        'This clears everything you have entered so far. '
                        'This cannot be undone.',
                    confirmLabel: 'Clear application',
                  );
                  if (confirmed) {
                    await controller.reset();
                    await ref.read(appControllerProvider.notifier).resetDemo();
                    if (context.mounted) context.go('/welcome');
                  }
                },
                child: const Text('Start over'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        label: allComplete ? 'Review & submit' : 'Continue setup',
        hint: 'Progress saves automatically — pick up any time.',
        onPressed: () {
          if (allComplete) {
            context.push('/onboarding/review');
          } else {
            controller.goToStep(controller.firstIncompleteStep);
            context.push('/onboarding/flow');
          }
        },
      ),
    );
  }
}
