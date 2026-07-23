import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grid_professionals/core/models/models.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';
import 'package:grid_professionals/core/widgets/app_widgets.dart';
import 'package:grid_professionals/state/app_state.dart';
import 'package:grid_professionals/state/onboarding_state.dart';

/// One screen for the whole post-submission lifecycle: under review,
/// more information required, verification failed, approved and rejected.
class ApplicationStatusScreen extends ConsumerWidget {
  const ApplicationStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application status'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: AppPage(
          children: [
            ...switch (state.status) {
              ApplicationStatus.moreInfoRequired => _moreInfo(context, ref),
              ApplicationStatus.verificationFailed => _failed(context, ref),
              ApplicationStatus.approved => _approved(context, ref),
              ApplicationStatus.rejected => _rejected(context, ref),
              _ => _underReview(context, ref),
            },
            const SizedBox(height: 28),
            const _DemoControls(),
          ],
        ),
      ),
    );
  }

  List<Widget> _underReview(BuildContext context, WidgetRef ref) => [
    const AppCard(
      color: AppColors.forest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.manage_search, color: Colors.white, size: 32),
          SizedBox(height: 14),
          Text(
            'Your application is under review.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'We\'ll text you as soon as there is an update — usually within '
            '1–3 working days.',
            style: TextStyle(color: AppColors.mint, height: 1.45),
          ),
        ],
      ),
    ),
    const SectionHeader('What we check'),
    const AppCard(
      child: Column(
        children: [
          TimelineStep(label: 'Application received', complete: true),
          TimelineStep(
            label: 'Identity checks',
            caption: 'Your Ghana Card and selfie',
            complete: false,
            current: true,
          ),
          TimelineStep(
            label: 'Skills and standards',
            caption: 'Your services, experience and portfolio',
            complete: false,
          ),
          TimelineStep(label: 'Decision', complete: false, last: true),
        ],
      ),
    ),
    const SectionHeader('While you wait'),
    const Text(
      'You can still edit your application. If anything needs a second '
      'look, we\'ll list exactly what to fix here.',
      style: TextStyle(color: AppColors.muted),
    ),
    const SizedBox(height: 18),
    OutlinedButton(
      onPressed: () => context.push('/onboarding/review'),
      child: const Text('View my application'),
    ),
    const SizedBox(height: 10),
    OutlinedButton(
      onPressed: () => context.push('/support'),
      child: const Text('Contact support'),
    ),
  ];

  List<Widget> _moreInfo(BuildContext context, WidgetRef ref) {
    final controller = ref.read(onboardingControllerProvider.notifier);
    return [
      const StatusBanner(
        kind: StatusKind.actionRequired,
        title: 'We need a little more from you',
        message:
            'Your application is on hold until the items below are updated. '
            'Fix them and resubmit — your place in the queue is kept.',
      ),
      const SectionHeader('What to fix'),
      _FixItem(
        title: 'Retake your Ghana Card photos',
        detail: 'The front of your ID was too blurry to read.',
        onFix: () {
          controller.resumeForCorrections(OnboardingStep.identity);
          context.push('/onboarding/flow?from=review');
        },
      ),
      _FixItem(
        title: 'Add more work photos',
        detail:
            'One clear photo of a finished job is the minimum; '
            'three or more is best.',
        onFix: () {
          controller.resumeForCorrections(OnboardingStep.portfolio);
          context.push('/onboarding/flow?from=review');
        },
      ),
      const SizedBox(height: 18),
      FilledButton(
        onPressed: () => context.push('/onboarding/review'),
        child: const Text('Review and resubmit'),
      ),
      const SizedBox(height: 10),
      OutlinedButton(
        onPressed: () => context.push('/support'),
        child: const Text('Contact support'),
      ),
    ];
  }

  List<Widget> _failed(BuildContext context, WidgetRef ref) {
    final controller = ref.read(onboardingControllerProvider.notifier);
    return [
      const StatusBanner(
        kind: StatusKind.danger,
        title: 'Identity verification was unsuccessful',
        message:
            'We couldn\'t match your selfie to your Ghana Card. This is '
            'usually a lighting problem — it does not affect your '
            'application otherwise.',
      ),
      const SectionHeader('Try again'),
      const Text(
        'Find good lighting, remove hats or glasses, and hold the card '
        'steady. You can retry as many times as you need.',
        style: TextStyle(color: AppColors.muted),
      ),
      const SizedBox(height: 18),
      FilledButton(
        onPressed: () {
          controller.resumeForCorrections(OnboardingStep.identity);
          context.push('/onboarding/flow?from=review');
        },
        child: const Text('Retry verification'),
      ),
      const SizedBox(height: 10),
      OutlinedButton(
        onPressed: () => context.push('/support'),
        child: const Text('Get help from support'),
      ),
    ];
  }

  List<Widget> _approved(BuildContext context, WidgetRef ref) => [
    AppCard(
      color: AppColors.forest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified, color: Colors.white, size: 32),
          const SizedBox(height: 14),
          const Text(
            'You\'re approved.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Welcome to GRID, '
            '${ref.watch(onboardingControllerProvider).draft.fullName.split(' ').first}. '
            'Your profile is live and customers in your areas can now book '
            'you.',
            style: const TextStyle(color: AppColors.mint, height: 1.45),
          ),
        ],
      ),
    ),
    const SectionHeader('What happens next'),
    const AppCard(
      child: Column(
        children: [
          TimelineStep(label: 'Profile verified and live', complete: true),
          TimelineStep(
            label: 'Job offers arrive as notifications',
            caption: 'Matched to your services, areas and hours',
            complete: false,
            current: true,
          ),
          TimelineStep(
            label: 'Get paid after each completed job',
            caption: 'Straight to your payout account',
            complete: false,
            last: true,
          ),
        ],
      ),
    ),
    const SizedBox(height: 20),
    FilledButton(
      onPressed: () async {
        await ref.read(onboardingControllerProvider.notifier).enterApp();
        if (context.mounted) context.go('/jobs');
      },
      child: const Text('Go to your dashboard'),
    ),
  ];

  List<Widget> _rejected(BuildContext context, WidgetRef ref) => [
    const StatusBanner(
      kind: StatusKind.danger,
      title: 'Your application was not approved',
      message:
          'Based on the information provided, we can\'t verify your profile '
          'right now. This decision can be reviewed — support can tell you '
          'exactly why and what your options are.',
    ),
    const SectionHeader('Your options'),
    const Text(
      'You can appeal the decision, or apply again after 30 days with '
      'updated documents and portfolio.',
      style: TextStyle(color: AppColors.muted),
    ),
    const SizedBox(height: 18),
    FilledButton(
      onPressed: () => context.push('/support'),
      child: const Text('Talk to support'),
    ),
  ];
}

class _FixItem extends StatelessWidget {
  const _FixItem({
    required this.title,
    required this.detail,
    required this.onFix,
  });
  final String title;
  final String detail;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: AppCard(
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.warningText),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(detail, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(onPressed: onFix, child: const Text('Fix')),
        ],
      ),
    ),
  );
}

/// Clearly-labelled demo panel to preview each application state without a
/// backend. Collapsed by default so the screen reads realistically.
class _DemoControls extends ConsumerWidget {
  const _DemoControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(onboardingControllerProvider.notifier);
    final current = ref.watch(onboardingControllerProvider).status;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ExpansionTile(
        shape: const Border(),
        leading: const Icon(Icons.science_outlined, color: AppColors.muted),
        title: const Text(
          'Demo controls',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        subtitle: const Text(
          'Preview review outcomes (no backend in this build)',
          style: TextStyle(fontSize: 12),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (label, status) in const [
                ('Under review', ApplicationStatus.underReview),
                ('More info required', ApplicationStatus.moreInfoRequired),
                ('Verification failed', ApplicationStatus.verificationFailed),
                ('Approved', ApplicationStatus.approved),
                ('Rejected', ApplicationStatus.rejected),
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: current == status,
                  onSelected: (_) => controller.setDemoStatus(status),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () async {
                await controller.reset();
                await ref.read(appControllerProvider.notifier).resetDemo();
                if (context.mounted) context.go('/welcome');
              },
              child: const Text('Reset entire demo'),
            ),
          ),
        ],
      ),
    );
  }
}
