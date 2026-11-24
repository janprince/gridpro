import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grid_professionals/core/models/models.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';
import 'package:grid_professionals/core/utils/formatters.dart';
import 'package:grid_professionals/core/widgets/app_widgets.dart';
import 'package:grid_professionals/features/jobs/job_screens.dart';
import 'package:grid_professionals/state/work_state.dart';

/// Today at a glance: what today should pay, what's new, and the one job to
/// act on next. The same screen for a first day and a busy one.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final work = ref.watch(workProvider);
    final pro = profile.value;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.read(workProvider.notifier).refresh(),
          ref.read(profileProvider.notifier).refresh(),
        ]);
      },
      child: AppPage(
        children: [
          _Greeting(profile: pro, work: work.value),
          const SizedBox(height: 20),
          ...switch (work) {
            AsyncData(:final value) => _content(context, ref, value, pro),
            AsyncError() => [
              RetryState(
                title: 'Could not reach GRID',
                message: 'Check your connection and try again.',
                onRetry: () => ref.invalidate(workProvider),
              ),
            ],
            _ => const [
              LoadingSkeleton(height: 168, radius: AppRadius.xl),
              SizedBox(height: 14),
              LoadingSkeleton(height: 96, radius: AppRadius.lg),
            ],
          },
        ],
      ),
    );
  }

  List<Widget> _content(
    BuildContext context,
    WidgetRef ref,
    WorkState work,
    ProviderProfile? pro,
  ) {
    final offers = work.offers;
    final active = work.active;
    final today = active.where((job) => formatDay(job.scheduledAt) == 'Today');
    final todayEarnings = today.fold<double>(
      0,
      (sum, job) => sum + job.earnings,
    );
    final next = active.isEmpty ? null : active.first;
    final later = active.skip(1).toList();
    final quiet = offers.isEmpty && active.isEmpty;

    return [
      NavyPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'TODAY',
                    style: AppText.overline.copyWith(color: Colors.white70),
                  ),
                ),
                Text(
                  formatDate(DateTime.now()),
                  style: AppText.caption.copyWith(color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatCurrency(todayEarnings),
                style: AppText.amountXL.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              today.isEmpty
                  ? 'No jobs today yet.'
                  : 'Expected from ${today.length} '
                        'job${today.length == 1 ? '' : 's'}, after GRID fees',
              style: AppText.caption.copyWith(
                color: Colors.white70,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 18),
            OnNavyButton(
              label: 'View earnings',
              onPressed: () => context.go('/earnings'),
            ),
          ],
        ),
      ),
      if (pro != null && !pro.canGoOnline) ...[
        const SizedBox(height: 14),
        StatusBanner(
          kind: StatusKind.actionRequired,
          title: 'One more thing before you can go online',
          message: pro.missingToGoOnline.join(' '),
        ),
      ] else if (pro != null && !pro.online) ...[
        const SizedBox(height: 14),
        const StatusBanner(
          kind: StatusKind.neutral,
          title: 'You\'re offline',
          message: 'Go online to receive new requests.',
        ),
      ],
      if (offers.isNotEmpty) ...[
        SectionHeader(
          offers.length == 1 ? 'New request' : 'New requests',
          action: offers.length > 1 ? 'See all ${offers.length}' : null,
          onAction: () => context.go('/jobs'),
        ),
        OfferCard(
          job: offers.first,
          onOpen: () => context.push('/job/${offers.first.id}/offer'),
        ),
      ] else if (quiet) ...[
        const SectionHeader('New requests'),
        EmptyState(
          title: 'No offers yet',
          message: pro?.completedJobs == 0
              ? 'New providers usually get their first request within a few '
                    'days.'
              : 'Requests near you will show here as customers book.',
          points: const [
            'Stay online during your working hours',
            'Keep your service areas up to date',
          ],
        ),
      ],
      if (!quiet) ...[
        SectionHeader(
          'Up next',
          action: 'All jobs',
          onAction: () => context.go('/jobs'),
        ),
        if (next == null)
          const EmptyState(
            title: 'Nothing scheduled',
            message: 'Accepted jobs will show here, in the order you do them.',
          )
        else
          JobTile(
            job: next,
            showDay: true,
            onTap: () => context.push('/job/${next.id}'),
            footer: next.nextAction == null
                ? null
                : PrimaryButton(
                    label: next.nextAction!.label,
                    onPressed: () => advanceJob(context, ref, next),
                  ),
          ),
        if (later.isNotEmpty) ...[
          const SectionHeader('Later'),
          for (final job in later)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: JobTile(
                job: job,
                showDay: true,
                onTap: () => context.push('/job/${job.id}'),
              ),
            ),
        ],
      ] else ...[
        const SectionHeader('Get ready'),
        MenuGroup(
          children: [
            MenuRow(
              icon: Icons.schedule_rounded,
              label: 'Check your hours',
              onTap: () => context.push('/availability'),
            ),
            MenuRow(
              icon: Icons.sell_outlined,
              label: 'Services & prices',
              onTap: () => context.push('/services'),
            ),
            MenuRow(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Payout account',
              onTap: () => context.push('/payout-account'),
            ),
          ],
        ),
      ],
    ];
  }
}

class _Greeting extends ConsumerStatefulWidget {
  const _Greeting({required this.profile, required this.work});
  final ProviderProfile? profile;
  final WorkState? work;

  @override
  ConsumerState<_Greeting> createState() => _GreetingState();
}

class _GreetingState extends ConsumerState<_Greeting> {
  bool _changing = false;

  Future<void> _setOnline(bool online) async {
    setState(() => _changing = true);
    final problem = await ref.read(profileProvider.notifier).setOnline(online);
    if (!mounted) return;
    setState(() => _changing = false);
    if (problem != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(problem)));
    } else if (online) {
      // Requests may have been waiting for someone to come online.
      ref.read(workProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pro = widget.profile;
    final work = widget.work;
    // A first day reads as a welcome; after that the name is enough.
    final fresh =
        pro != null &&
        pro.completedJobs == 0 &&
        (work?.jobs.isEmpty ?? true) &&
        (work?.offers.isEmpty ?? true);
    return Row(
      children: [
        Semantics(
          button: true,
          label: 'Your account',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () => context.go('/account'),
            child: InitialsAvatar(initials: pro?.initials ?? '', size: 46),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption.copyWith(fontSize: 13),
              ),
              Text(
                pro == null
                    ? ''
                    : fresh
                    ? 'Welcome, ${pro.firstName}'
                    : pro.firstName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.title,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (pro != null)
          OnlineToggle(
            value: pro.online,
            onChanged: _changing ? null : _setOnline,
          ),
      ],
    );
  }
}

/// A new request, tinted by service, with everything needed to decide.
class OfferCard extends StatelessWidget {
  const OfferCard({super.key, required this.job, required this.onOpen});
  final Job job;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final minutes = job.expiresAt
        ?.difference(DateTime.now())
        .inMinutes
        .clamp(1, 99);
    return GestureDetector(
      onTap: onOpen,
      child: ServiceHeroCard(
        service: job.service,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.service.label.toUpperCase(),
                    style: AppText.overline.copyWith(
                      color: job.service.palette.ink,
                    ),
                  ),
                ),
                if (minutes != null) _Expiry(label: '$minutes min left'),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                ServiceBadge(service: job.service, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.subtitle.copyWith(fontSize: 17),
                      ),
                      Text(
                        job.scope,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption.copyWith(fontSize: 13.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Amount(job.price, style: AppText.amount.copyWith(fontSize: 17)),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _Meta(icon: Icons.place_outlined, text: job.areaAndDistance),
                _Meta(
                  icon: Icons.schedule_rounded,
                  text: formatWhen(job.scheduledAt),
                ),
              ],
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Review request', onPressed: onOpen),
          ],
        ),
      ),
    );
  }
}

class _Expiry extends StatelessWidget {
  const _Expiry({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.timer_outlined, size: 14, color: AppColors.warning),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.warningText,
          ),
        ),
      ],
    ),
  );
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: AppColors.muted),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.caption.copyWith(
            fontSize: 13,
            color: AppColors.ink.withValues(alpha: 0.75),
          ),
        ),
      ),
    ],
  );
}
