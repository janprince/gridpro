import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grid_professionals/core/models/models.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';
import 'package:grid_professionals/core/utils/formatters.dart';
import 'package:grid_professionals/core/widgets/app_widgets.dart';
import 'package:grid_professionals/state/work_state.dart';
import 'package:url_launcher/url_launcher.dart';

void _toast(BuildContext context, String message, {bool aboveActions = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        margin: aboveActions ? const EdgeInsets.fromLTRB(16, 0, 16, 92) : null,
      ),
    );
}

/// Moves [job] to its next stage, asking first when the step is one the
/// customer relies on (pickup, delivery, finishing). GRID has the final say:
/// if it refuses the step, the job is re-read and the reason shown.
///
/// [aboveActions] lifts the confirmation toast clear of a pinned button.
Future<void> advanceJob(
  BuildContext context,
  WidgetRef ref,
  Job job, {
  bool aboveActions = false,
}) async {
  final action = job.nextAction;
  if (action == null) return;
  final first = job.customerFirstName;
  if (action.confirm != null) {
    final yes = await showConfirmationSheet(
      context,
      title: action.confirm!,
      message: switch (action.next) {
        JobStage.pickedUp =>
          'Check the items against the request before you leave.',
        _ =>
          '$first will be asked to confirm. Your payment is released once '
              'they do.',
      },
      confirmLabel: action.label,
      cancelLabel: 'Not yet',
      header: _CompactJobCard(job: job),
    );
    if (!yes || !context.mounted) return;
  }
  try {
    await ref.read(workProvider.notifier).advance(job);
  } on Object catch (error) {
    if (context.mounted) {
      _toast(context, describeError(error), aboveActions: aboveActions);
    }
    return;
  }
  final message = switch (action.next) {
    JobStage.onTheWay => '$first has been told you\'re on the way.',
    JobStage.arrived => 'Arrival confirmed.',
    JobStage.inProgress =>
      job.service == ServiceKind.cleaning
          ? 'Cleaning started.'
          : 'Work started.',
    JobStage.pickedUp => 'Pickup confirmed.',
    JobStage.processing => 'Washing started.',
    JobStage.readyForDelivery => 'Marked as ready for delivery.',
    JobStage.outForDelivery => '$first has been told it\'s on the way.',
    JobStage.completed => 'Job complete. Nice work.',
    _ => null,
  };
  if (message != null && context.mounted) {
    _toast(context, message, aboveActions: aboveActions);
  }
}

/// All jobs, upcoming or done, grouped by day.
class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen> {
  bool _completed = false;

  List<Widget> _list(WorkState work) {
    final list = _completed
        ? work.finished
        : ([...work.offers, ...work.active]
            ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt)));
    if (list.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 32),
          child: EmptyState(
            title: _completed ? 'No completed jobs yet' : 'All clear',
            message: _completed
                ? 'Finished jobs and what they paid will be listed here.'
                : 'New requests and accepted jobs will show here.',
          ),
        ),
      ];
    }
    final children = <Widget>[];
    String? day;
    for (final job in list) {
      final label = formatDay(job.scheduledAt);
      if (label != day) {
        children.add(DateChip(label));
        day = label;
      }
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: JobTile(
            job: job,
            onTap: () => context.push(
              job.stage == JobStage.offer
                  ? '/job/${job.id}/offer'
                  : '/job/${job.id}',
            ),
          ),
        ),
      );
    }
    return children;
  }

  @override
  Widget build(BuildContext context) {
    final work = ref.watch(workProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppHeader(title: 'Jobs'),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(workProvider.notifier).refresh(),
            child: AppPage(
              children: [
                SegmentedTabs(
                  labels: const ['Upcoming', 'Completed'],
                  index: _completed ? 1 : 0,
                  onChanged: (index) => setState(() => _completed = index == 1),
                ),
                const SizedBox(height: 12),
                ...switch (work) {
                  AsyncData(:final value) => _list(value),
                  AsyncError() => [
                    const SizedBox(height: 20),
                    RetryState(
                      title: 'Could not load your jobs',
                      message: 'Check your connection and try again.',
                      onRetry: () => ref.invalidate(workProvider),
                    ),
                  ],
                  _ => const [
                    SizedBox(height: 8),
                    LoadingSkeleton(height: 104, radius: AppRadius.lg),
                    SizedBox(height: 12),
                    LoadingSkeleton(height: 104, radius: AppRadius.lg),
                  ],
                },
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Two-way switch styled as a grey track with a white thumb.
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: AppColors.chip,
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Semantics(
              button: true,
              selected: i == index,
              label: labels[i],
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == index ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: i == index
                        ? const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 6,
                              offset: Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: i == index
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: i == index ? AppColors.ink : AppColors.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// A new request: everything needed to decide, and two buttons.
class JobOfferScreen extends ConsumerStatefulWidget {
  const JobOfferScreen({super.key, required this.jobId});
  final String jobId;

  @override
  ConsumerState<JobOfferScreen> createState() => _JobOfferScreenState();
}

class _JobOfferScreenState extends ConsumerState<JobOfferScreen> {
  bool _busy = false;

  Future<void> _accept(Job offer) async {
    setState(() => _busy = true);
    try {
      final job = await ref.read(workProvider.notifier).accept(offer);
      if (!mounted) return;
      _toast(context, 'Accepted. ${job.customerFirstName} has been notified.');
      context.pushReplacement('/job/${job.id}');
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      _toast(context, describeError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final work = ref.watch(workProvider);
    final job = work.value?.offer(widget.jobId);
    if (job == null) {
      // Taken by someone else, expired, or already accepted here.
      final mine = work.value?.job(widget.jobId);
      return FocusPage(
        title: 'Request',
        onClose: () => context.pop(),
        actions: [
          if (mine != null && mine.stage.isActive)
            PrimaryButton(
              label: 'Open job',
              onPressed: () => context.pushReplacement('/job/${mine.id}'),
            ),
        ],
        children: [
          if (work.isLoading && !work.hasValue)
            const LoadingSkeleton(height: 220, radius: AppRadius.xl)
          else
            StatusBanner(
              kind: mine != null ? StatusKind.success : StatusKind.neutral,
              title: mine != null
                  ? 'You accepted this request'
                  : 'This request is no longer available',
              message: mine != null
                  ? null
                  : 'It was taken by another professional or ran out of time.',
            ),
        ],
      );
    }
    return FocusPage(
      title: 'New request',
      onClose: () => context.pop(),
      actions: [
        FloatingActionBar(
          title: 'You earn ${formatCurrency(job.earnings)}',
          caption: 'after GRID\'s ${job.feePercent}% fee',
          label: 'Accept',
          busy: _busy,
          busyLabel: 'Accepting',
          onPressed: () => _accept(job),
        ),
        Center(
          child: TextLink(
            label: 'Decline this request',
            onPressed: _busy ? null : () => _decline(context, job),
          ),
        ),
      ],
      children: [
        ServiceHeroCard(
          service: job.service,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
          child: Column(
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
                  Text(
                    job.code,
                    style: AppText.caption.copyWith(
                      color: job.service.palette.ink,
                      fontFeatures: AppText.tabular,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ServiceBadge(service: job.service, size: 56),
              const SizedBox(height: 14),
              Text(
                job.title,
                style: AppText.title,
                textAlign: TextAlign.center,
              ),
              if (job.scope.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  job.scope,
                  textAlign: TextAlign.center,
                  style: AppText.bodyMuted,
                ),
              ],
              const SizedBox(height: 16),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(formatCurrency(job.price), style: AppText.amountXL),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        DetailGroup(
          rows: [
            DetailRow(
              label: job.service == ServiceKind.laundry ? 'Pickup' : 'When',
              value: formatWhen(job.scheduledAt),
            ),
            DetailRow(
              label: 'Area',
              value: job.distanceKm == null
                  ? job.area
                  : '${job.area}\n'
                        '${job.distanceKm!.toStringAsFixed(1)} km away',
            ),
            if (job.items.isNotEmpty)
              DetailRow(label: 'Items', value: job.items.join('\n')),
            if (job.notes.isNotEmpty)
              DetailRow(
                label: 'Customer\'s note',
                value: job.notes,
                stacked: true,
              ),
          ],
        ),
        const SizedBox(height: 12),
        _EarningsBreakdown(job: job),
        const SizedBox(height: 14),
        const Row(
          children: [
            Icon(Icons.lock_outline_rounded, size: 15, color: AppColors.muted),
            SizedBox(width: 7),
            Expanded(
              child: Text(
                'The customer\'s name and full address are shared once you '
                'accept.',
                style: AppText.caption,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _decline(BuildContext context, Job job) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            4,
            AppSpacing.gutter,
            16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Why are you declining?', style: AppText.title),
              const SizedBox(height: 6),
              const Text(
                'It helps us send you better requests.',
                style: AppText.bodyMuted,
              ),
              const SizedBox(height: 18),
              MenuGroup(
                children: [
                  for (final (icon, label) in const [
                    (Icons.near_me_outlined, 'Too far'),
                    (Icons.event_busy_outlined, 'Not available then'),
                    (Icons.payments_outlined, 'Price too low'),
                    (Icons.more_horiz_rounded, 'Something else'),
                  ])
                    MenuRow(
                      icon: icon,
                      label: label,
                      onTap: () => Navigator.pop(context, label),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (reason == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(workProvider.notifier).decline(job, reason);
      if (!context.mounted) return;
      _toast(context, 'Request declined.');
      context.pop();
    } on Object catch (error) {
      if (!context.mounted) return;
      setState(() => _busy = false);
      _toast(context, describeError(error));
    }
  }
}

/// A job after acceptance: what, where, who, and the single next step.
class JobDetailScreen extends ConsumerStatefulWidget {
  const JobDetailScreen({super.key, required this.jobId});
  final String jobId;

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  bool _busy = false;

  Future<void> _advance(Job job) async {
    setState(() => _busy = true);
    await advanceJob(context, ref, job, aboveActions: true);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _open(Uri uri, String failure) async {
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      opened = false;
    }
    if (!opened && mounted) _toast(context, failure, aboveActions: true);
  }

  @override
  Widget build(BuildContext context) {
    final work = ref.watch(workProvider);
    final job = work.value?.job(widget.jobId);
    if (job == null) {
      return FocusPage(
        title: 'Job',
        onBack: () => context.pop(),
        children: [
          if (work.isLoading && !work.hasValue)
            const LoadingSkeleton(height: 220, radius: AppRadius.xl)
          else
            RetryState(
              title: 'Could not open this job',
              message: 'Check your connection and try again.',
              onRetry: () => ref.read(workProvider.notifier).refresh(),
            ),
        ],
      );
    }
    final action = job.nextAction;
    final stages = stagesFor(job.service);
    final first = job.customerFirstName;
    final phone = job.customerPhone;
    // A pin is exact; without one the written address is searched for.
    final directions = job.latitude != null && job.longitude != null
        ? '${job.latitude},${job.longitude}'
        : job.address;

    return FocusPage(
      title: job.code,
      onBack: () => context.pop(),
      trailing: NavChip(
        onPressed: () => context.push('/report-issue?job=${job.id}'),
        icon: Icons.help_outline_rounded,
        tooltip: 'Get help with this job',
      ),
      actions: [
        if (action != null)
          PrimaryButton(
            label: action.label,
            busy: _busy,
            onPressed: () => _advance(job),
          ),
      ],
      children: [
        ServiceHeroCard(
          service: job.service,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ServiceBadge(service: job.service, size: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.service.label.toUpperCase(),
                          style: AppText.overline.copyWith(
                            color: job.service.palette.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(job.title, style: AppText.title),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _HeroFact(
                      label: job.scope,
                      value: formatWhen(job.scheduledAt),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Amount(
                    job.price,
                    style: AppText.amount.copyWith(fontSize: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (job.stage.isActive)
          StageProgress(
            total: stages.length,
            current: stages.indexOf(job.stage),
            label: job.stageLabel,
          )
        else if (job.stage == JobStage.completed)
          StatusBanner(
            kind: StatusKind.pending,
            title: 'Waiting for $first to confirm',
            message:
                '${formatCurrency(job.earnings)} is released to you as soon '
                'as they do — within a day at most.',
          )
        else if (job.stage == JobStage.paid)
          StatusBanner(
            kind: StatusKind.success,
            title: 'Confirmed',
            message:
                '${formatCurrency(job.earnings)} was added to your earnings.',
          )
        else if (job.stage == JobStage.cancelled)
          StatusBanner(
            kind: StatusKind.danger,
            title: 'This job was cancelled',
            message: job.cancelReason,
          ),
        const SizedBox(height: 20),
        DetailGroup(
          rows: [
            DetailRow(
              label: 'Customer',
              value: job.customerName,
              stacked: true,
              trailing: job.stage.isActive && phone != null
                  ? RoundIconButton(
                      icon: Icons.call_outlined,
                      tooltip: 'Call $first',
                      onPressed: () => _open(
                        Uri(scheme: 'tel', path: '+$phone'),
                        'Could not start a call from this phone.',
                      ),
                    )
                  : null,
            ),
            DetailRow(
              label: 'Address',
              value: job.address,
              stacked: true,
              trailing: job.stage.isActive
                  ? RoundIconButton(
                      icon: Icons.directions_outlined,
                      tooltip: 'Directions',
                      onPressed: () => _open(
                        Uri.https('www.google.com', '/maps/dir/', {
                          'api': '1',
                          'destination': directions,
                        }),
                        'Could not open maps on this phone.',
                      ),
                    )
                  : null,
            ),
            if (job.items.isNotEmpty)
              DetailRow(label: 'Items', value: job.items.join('\n')),
            if (job.notes.isNotEmpty)
              DetailRow(
                label: 'Customer\'s note',
                value: job.notes,
                stacked: true,
              ),
          ],
        ),
        const SizedBox(height: 12),
        _EarningsBreakdown(job: job),
      ],
    );
  }
}

class _HeroFact extends StatelessWidget {
  const _HeroFact({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.caption.copyWith(fontSize: 13),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.subtitle,
      ),
    ],
  );
}

class _EarningsBreakdown extends StatelessWidget {
  const _EarningsBreakdown({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context) => DetailGroup(
    rows: [
      DetailRow(label: 'Customer pays', value: formatCurrency(job.price)),
      DetailRow(
        label: 'GRID fee (${job.feePercent}%)',
        value: '− ${formatCurrency(job.fee)}',
      ),
      DetailRow(
        label: 'You earn',
        value: formatCurrency(job.earnings),
        emphasis: true,
      ),
    ],
  );
}

/// The job in one line, for confirmation sheets.
class _CompactJobCard extends StatelessWidget {
  const _CompactJobCard({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context) => ServiceHeroCard(
    service: job.service,
    padding: const EdgeInsets.all(16),
    child: Row(
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
                style: AppText.subtitle,
              ),
              Text(
                job.customerName.isEmpty
                    ? job.area
                    : '${job.customerName} · ${job.area}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Amount(job.price),
      ],
    ),
  );
}
