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

    return FocusPage(
      footnote: const Text(
        'Progress saves automatically — pick up any time.',
        style: AppText.caption,
        textAlign: TextAlign.center,
      ),
      actions: [
        PrimaryButton(
          label: allComplete ? 'Review & submit' : 'Continue setup',
          onPressed: () {
            if (allComplete) {
              context.push('/onboarding/review');
            } else {
              controller.goToStep(controller.firstIncompleteStep);
              context.push('/onboarding/flow');
            }
          },
        ),
      ],
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 24),
          child: GridMark(compact: true),
        ),
        ScreenIntro(
          title: 'Your application',
          subtitle: allComplete
              ? 'Everything is filled in. Review it and submit.'
              : 'Finish each section to get verified and start taking jobs.',
        ),
        const SizedBox(height: 22),
        NavyPanel(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    flex: 3,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        '$completed of $total',
                        style: AppText.amountXL.copyWith(
                          color: Colors.white,
                          fontSize: 28,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'sections done',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption.copyWith(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: completed / total,
                  minHeight: 6,
                  color: AppColors.amber,
                  backgroundColor: Colors.white24,
                  semanticsLabel: 'Application progress',
                ),
              ),
            ],
          ),
        ),
        for (final stage in OnboardingStage.values) ...[
          SectionHeader(stage.title),
          MenuGroupShell(
            children: [
              for (final step in stage.steps)
                SectionStatusTile(
                  title: step.title,
                  status: draft.statusOf(step, config),
                  summary:
                      draft.statusOf(step, config) == SectionStatus.notStarted
                      ? null
                      : sectionSummary(draft, config, step),
                  onTap: () {
                    controller.goToStep(step);
                    context.push('/onboarding/flow');
                  },
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),
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
                await ref.read(appControllerProvider.notifier).signOut();
                if (context.mounted) context.go('/welcome');
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.muted),
            child: const Text('Start over'),
          ),
        ),
      ],
    );
  }
}
