import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grid_professionals/core/models/models.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';
import 'package:grid_professionals/core/utils/formatters.dart';
import 'package:grid_professionals/core/widgets/app_widgets.dart';
import 'package:grid_professionals/data/mock_data.dart';
import 'package:grid_professionals/state/app_state.dart';
import 'package:grid_professionals/state/onboarding_state.dart';

class JobsDashboard extends ConsumerWidget {
  const JobsDashboard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    if (state.isNewProvider) return const _FirstTimeDashboard();
    final offers = state.jobs
        .where((job) => job.status == JobStatus.newOffer)
        .toList();
    final active = state.jobs
        .where(
          (job) => !{
            JobStatus.newOffer,
            JobStatus.declined,
            JobStatus.cancelled,
            JobStatus.paid,
          }.contains(job.status),
        )
        .toList();
    final actionRequired = active
        .where(
          (job) => {
            JobStatus.accepted,
            JobStatus.arrived,
            JobStatus.inspectionInProgress,
            JobStatus.quoteApproved,
            JobStatus.workInProgress,
          }.contains(job.status),
        )
        .toList();
    return AppPage(
      children: [
        Row(
          children: [
            const Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: GridMark(compact: true),
              ),
            ),
            const SizedBox(width: 8),
            AvailabilityToggle(
              value: state.availability.status,
              onChanged: ref
                  .read(appControllerProvider.notifier)
                  .setAvailability,
            ),
            IconButton(
              onPressed: () {},
              visualDensity: VisualDensity.compact,
              icon: const Badge(child: Icon(Icons.notifications_none)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Good morning, Kofi',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          state.availability.status == AvailabilityStatus.available
              ? 'You are available for jobs.'
              : 'Your status is ${state.availability.status.name}.',
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'New offers',
                value: '${offers.length}',
                icon: Icons.local_offer_outlined,
                caption: offers.isEmpty ? 'All caught up' : 'Respond soon',
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: MetricCard(
                label: 'Earnings today',
                value: 'GH₵ 320',
                icon: Icons.account_balance_wallet_outlined,
                dark: true,
                caption: 'After commission',
              ),
            ),
          ],
        ),
        if (actionRequired.isNotEmpty) ...[
          const SectionHeader('Action required'),
          for (final job in actionRequired)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ActionCard(
                job: job,
                onTap: () => context.push('/job/${job.id}'),
              ),
            ),
        ],
        SectionHeader('New job offers', action: 'View all', onAction: () {}),
        if (offers.isEmpty)
          const EmptyStateCard(
            icon: Icons.work_outline,
            title: 'No new offers',
            message: 'Stay available and keep your service areas current.',
          )
        else
          for (final job in offers)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: JobCard(
                job: job,
                offer: true,
                onTap: () => context.push('/job/${job.id}/offer'),
              ),
            ),
        SectionHeader(
          'Active jobs',
          action: 'History',
          onAction: () => context.push('/job-history'),
        ),
        if (active.isEmpty)
          const EmptyStateCard(
            icon: Icons.handyman_outlined,
            title: 'No active jobs',
            message:
                'Accepted jobs and quotes awaiting approval will appear here.',
          )
        else
          for (final job in active)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: JobCard(
                job: job,
                onTap: () => context.push('/job/${job.id}'),
              ),
            ),
        const SectionHeader('Quick earnings'),
        AppCard(
          onTap: () => context.go('/earnings'),
          child: Row(
            children: [
              const Icon(Icons.trending_up, color: AppColors.teal, size: 34),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('This week', style: TextStyle(color: AppColors.muted)),
                    Text(
                      'GH₵ 1,450.00',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${MockData.earnings.length} jobs',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ],
    );
  }
}

/// Dashboard for a provider who just finished onboarding: no fake numbers,
/// honest empty states, and practical guidance while they wait for offers.
class _FirstTimeDashboard extends ConsumerWidget {
  const _FirstTimeDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final draft = ref.watch(onboardingControllerProvider).draft;
    final firstName = draft.fullName.trim().isEmpty
        ? 'there'
        : draft.fullName.trim().split(' ').first;
    return AppPage(
      children: [
        Row(
          children: [
            const Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: GridMark(compact: true),
              ),
            ),
            const SizedBox(width: 8),
            AvailabilityToggle(
              value: app.availability.status,
              onChanged: ref
                  .read(appControllerProvider.notifier)
                  .setAvailability,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome, $firstName',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        const Text(
          'Your profile is live. Job offers will appear here.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        const StatusBanner(
          kind: StatusKind.success,
          title: 'You\'re verified and open for work',
          message:
              'Customers in your areas can now find and book you. Keep your '
              'availability up to date so offers match your day.',
        ),
        const SectionHeader('Job offers'),
        const EmptyStateCard(
          icon: Icons.work_outline,
          title: 'No offers yet',
          message:
              'New providers usually get their first offer within a few '
              'days. Staying available and adding portfolio photos helps.',
        ),
        const SectionHeader('While you wait'),
        _TipRow(
          icon: Icons.photo_library_outlined,
          text: 'Add more photos of your work',
          onTap: () => context.push('/portfolio'),
        ),
        _TipRow(
          icon: Icons.schedule,
          text: 'Check your availability and hours',
          onTap: () => context.push('/availability'),
        ),
        _TipRow(
          icon: Icons.school_outlined,
          text: 'Take the free GRID training modules',
          onTap: () => context.push('/training'),
        ),
        const SectionHeader('Earnings'),
        AppCard(
          child: Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.forest,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GH₵ 0.00',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Text(
                      'Earnings from completed jobs will show here.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: TextButton(
            onPressed: () =>
                ref.read(appControllerProvider.notifier).loadDemoData(),
            child: const Text('Load demo data (preview a busy dashboard)'),
          ),
        ),
      ],
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.icon, required this.text, required this.onTap});
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: AppSizes.iconSm, color: AppColors.forest),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ],
      ),
    ),
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.job, required this.onTap});
  final Job job;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.line),
    ),
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ColoredBox(color: AppColors.danger, child: SizedBox(width: 4)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _ActionCardContent(
                job: job,
                action: _action,
                button: _button,
                onTap: onTap,
              ),
            ),
          ),
        ],
      ),
    ),
  );
  String get _action => switch (job.status) {
    JobStatus.accepted => 'Start your journey',
    JobStatus.arrived => 'Begin inspection',
    JobStatus.inspectionInProgress => 'Prepare a quote',
    JobStatus.quoteApproved => 'Approved — ready to work',
    JobStatus.workInProgress => 'Complete job evidence',
    _ => 'Continue job',
  };
  String get _button => switch (job.status) {
    JobStatus.inspectionInProgress => 'Build quote',
    JobStatus.quoteApproved => 'Begin work',
    JobStatus.workInProgress => 'Complete job',
    _ => 'Open job',
  };
}

class _ActionCardContent extends StatelessWidget {
  const _ActionCardContent({
    required this.job,
    required this.action,
    required this.button,
    required this.onTap,
  });

  final Job job;
  final String action;
  final String button;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(action, style: Theme.of(context).textTheme.titleMedium),
          ),
          StatusChip(status: job.status),
        ],
      ),
      const SizedBox(height: 4),
      Text(job.summary),
      const SizedBox(height: 5),
      Text(
        '${job.area} • ${formatTime(job.scheduledAt)}',
        style: const TextStyle(color: AppColors.muted, fontSize: 12),
      ),
      const SizedBox(height: 12),
      FilledButton(onPressed: onTap, child: Text(button)),
    ],
  );
}
