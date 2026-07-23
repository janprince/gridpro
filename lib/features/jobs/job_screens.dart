import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grid_professionals/core/models/models.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';
import 'package:grid_professionals/core/utils/formatters.dart';
import 'package:grid_professionals/core/widgets/app_widgets.dart';
import 'package:grid_professionals/state/app_state.dart';

class JobOfferScreen extends ConsumerWidget {
  const JobOfferScreen({super.key, required this.jobId});
  final String jobId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref
        .watch(appControllerProvider)
        .jobs
        .firstWhere((item) => item.id == jobId);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job offer'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Expires in 04:59',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
        ],
      ),
      body: AppPage(
        children: [
          Row(
            children: [
              Chip(
                label: Text(job.urgency),
                avatar: const Icon(Icons.priority_high, size: 16),
              ),
              const Spacer(),
              StatusChip(status: job.status),
            ],
          ),
          const SizedBox(height: 10),
          Text(job.summary, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 16),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFFDCE6DF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _MapPainter())),
                const Center(
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: AppColors.forest,
                    child: Icon(Icons.location_on, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.map_outlined,
                  label: 'GENERAL AREA',
                  value:
                      '${job.area}\n${job.distanceKm} km away • about ${(job.distanceKm * 3).round()} min',
                ),
                const Divider(height: 28),
                _DetailRow(
                  icon: Icons.description_outlined,
                  label: 'PROBLEM SUMMARY',
                  value: job.description,
                ),
                const Divider(height: 28),
                _DetailRow(
                  icon: Icons.schedule,
                  label: 'PREFERRED TIME',
                  value:
                      '${formatDate(job.scheduledAt)} at ${formatTime(job.scheduledAt)}',
                ),
                const Divider(height: 28),
                _DetailRow(
                  icon: Icons.payments_outlined,
                  label: 'INSPECTION FEE',
                  value: formatCurrency(job.calloutFee),
                  prominent: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const AppCard(
            color: Color(0xFFEAF2FB),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: AppColors.info),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Accept only if you can arrive on time and complete the job professionally. The full address is shown only after acceptance.',
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader('Customer photos'),
          const Row(
            children: [
              Expanded(
                child: _MockPhoto(
                  icon: Icons.broken_image_outlined,
                  label: 'Issue photo',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _MockPhoto(
                  icon: Icons.photo_outlined,
                  label: 'Area photo',
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        label: 'Accept job',
        secondaryLabel: 'Decline',
        onSecondary: () => _decline(context, ref, job),
        onPressed: () async {
          final confirmed = await showConfirmationSheet(
            context,
            title: 'Accept this job?',
            message:
                'You are committing to arrive on time, communicate professionally and follow the GRID job process.',
            confirmLabel: 'Accept job',
          );
          if (confirmed) {
            ref
                .read(appControllerProvider.notifier)
                .updateJob(job.id, JobStatus.accepted);
            if (context.mounted) context.go('/job/${job.id}');
          }
        },
      ),
    );
  }

  Future<void> _decline(BuildContext context, WidgetRef ref, Job job) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Why are you declining?',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              for (final item in const [
                'Too far',
                'Not available',
                'Outside my skill',
                'Need more information',
                'Other',
              ])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(context, item),
                ),
            ],
          ),
        ),
      ),
    );
    if (reason != null) {
      ref
          .read(appControllerProvider.notifier)
          .updateJob(job.id, JobStatus.declined);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Job declined: $reason')));
        context.go('/jobs');
      }
    }
  }
}

class JobDetailScreen extends ConsumerWidget {
  const JobDetailScreen({super.key, required this.jobId});
  final String jobId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref
        .watch(appControllerProvider)
        .jobs
        .firstWhere((item) => item.id == jobId);
    return Scaffold(
      appBar: AppBar(
        title: Text(job.id),
        actions: [
          IconButton(
            onPressed: () => context.push('/report-issue'),
            icon: const Icon(Icons.support_agent),
          ),
        ],
      ),
      body: AppPage(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  job.summary,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              StatusChip(status: job.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${job.category} • ${job.urgency}',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.person_outline,
                  label: 'CUSTOMER',
                  value: job.customerName,
                ),
                const Divider(height: 28),
                _DetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'FULL ADDRESS',
                  value: job.fullAddress,
                ),
                const Divider(height: 28),
                _DetailRow(
                  icon: Icons.schedule,
                  label: 'APPOINTMENT',
                  value:
                      '${formatDate(job.scheduledAt)} • ${formatTime(job.scheduledAt)}',
                ),
                const Divider(height: 28),
                _DetailRow(
                  icon: Icons.payments_outlined,
                  label: 'CALL-OUT FEE',
                  value: formatCurrency(job.calloutFee),
                ),
              ],
            ),
          ),
          const SectionHeader('Issue description'),
          Text(job.description),
          const SectionHeader('Job progress'),
          AppCard(child: _JobTimeline(status: job.status)),
          const SectionHeader('Contact & route'),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.phone_outlined),
                  label: const Text('Customer'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.directions_outlined),
                  label: const Text('Directions'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => context.push('/report-issue'),
            icon: const Icon(Icons.support_agent),
            label: const Text('Contact GRID Support'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => _next(context, ref, job),
            child: Text(_action(job.status)),
          ),
          if (job.status == JobStatus.awaitingCustomerApproval) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => context.push('/quote-awaiting/${job.id}'),
              child: const Text('View submitted quote'),
            ),
          ],
        ],
      ),
    );
  }

  String _action(JobStatus status) => switch (status) {
    JobStatus.accepted => 'Start journey',
    JobStatus.onMyWay => 'Open journey status',
    JobStatus.arrived => 'Start inspection',
    JobStatus.inspectionInProgress ||
    JobStatus.quoteDraft => 'Continue to quote builder',
    JobStatus.awaitingCustomerApproval ||
    JobStatus.quoteSubmitted => 'View approval status',
    JobStatus.quoteApproved => 'Review approval and begin work',
    JobStatus.workInProgress => 'Continue work',
    JobStatus.workCompleted ||
    JobStatus.awaitingCustomerConfirmation ||
    JobStatus.paymentProcessing ||
    JobStatus.payoutPending => 'View payment status',
    JobStatus.paid => 'View completed job receipt',
    _ => 'View job status',
  };

  void _next(BuildContext context, WidgetRef ref, Job job) {
    switch (job.status) {
      case JobStatus.accepted:
        context.push('/journey/${job.id}');
      case JobStatus.onMyWay:
        context.push('/journey/${job.id}');
      case JobStatus.arrived:
        context.push('/inspection/${job.id}');
      case JobStatus.inspectionInProgress:
      case JobStatus.quoteDraft:
        context.push('/quote/${job.id}');
      case JobStatus.awaitingCustomerApproval:
      case JobStatus.quoteSubmitted:
        context.push('/quote-awaiting/${job.id}');
      case JobStatus.quoteApproved:
        context.push('/quote-approved/${job.id}');
      case JobStatus.workInProgress:
        context.push('/work/${job.id}');
      case JobStatus.workCompleted:
      case JobStatus.awaitingCustomerConfirmation:
      case JobStatus.paymentProcessing:
      case JobStatus.payoutPending:
        context.push('/payment/${job.id}');
      case JobStatus.paid:
        context.push('/receipt/${job.id}');
      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(job.status.label)));
    }
  }
}

class JourneyScreen extends ConsumerWidget {
  const JourneyScreen({super.key, required this.jobId});
  final String jobId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref
        .watch(appControllerProvider)
        .jobs
        .firstWhere((item) => item.id == jobId);
    final started = job.status == JobStatus.onMyWay;
    return Scaffold(
      appBar: AppBar(title: const Text('Journey to customer')),
      body: AppPage(
        children: [
          Container(
            height: 230,
            decoration: BoxDecoration(
              color: const Color(0xFFDCE6DF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _MapPainter())),
                Center(
                  child: Icon(
                    started ? Icons.directions_car_filled : Icons.location_on,
                    color: AppColors.forest,
                    size: 48,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'DESTINATION',
                  value: job.fullAddress,
                ),
                const Divider(height: 28),
                const _DetailRow(
                  icon: Icons.schedule,
                  label: 'ESTIMATED ARRIVAL',
                  value: '18 minutes • 10:42 AM',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            color: started ? AppColors.mint : Colors.white,
            child: Row(
              children: [
                Icon(
                  started ? Icons.navigation : Icons.info_outline,
                  color: AppColors.forest,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    started
                        ? 'The customer has been notified that you are on your way.'
                        : 'Start the journey only when you are ready to leave.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (!started)
            FilledButton(
              onPressed: () => ref
                  .read(appControllerProvider.notifier)
                  .updateJob(job.id, JobStatus.onMyWay),
              child: const Text('Start journey'),
            )
          else
            FilledButton(
              onPressed: () async {
                final yes = await showConfirmationSheet(
                  context,
                  title: 'Confirm arrival',
                  message:
                      'Confirm only when you are at the customer’s location.',
                  confirmLabel: 'I have arrived',
                );
                if (yes) {
                  ref
                      .read(appControllerProvider.notifier)
                      .updateJob(job.id, JobStatus.arrived);
                  if (context.mounted) context.go('/inspection/${job.id}');
                }
              },
              child: const Text('I have arrived'),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.phone),
                  label: const Text('Customer'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/report-issue'),
                  icon: const Icon(Icons.support_agent),
                  label: const Text('Support'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class InspectionScreen extends ConsumerStatefulWidget {
  const InspectionScreen({super.key, required this.jobId});
  final String jobId;
  @override
  ConsumerState<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends ConsumerState<InspectionScreen> {
  final _notes = TextEditingController(
    text:
        'Inspection found a damaged breaker and heat damage around the terminal. Replacement and load testing required.',
  );
  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final job = ref
        .watch(appControllerProvider)
        .jobs
        .firstWhere((item) => item.id == widget.jobId);
    final active = job.status == JobStatus.inspectionInProgress;
    return Scaffold(
      appBar: AppBar(title: const Text('Arrival & inspection')),
      body: AppPage(
        children: [
          AppCard(
            color: active ? AppColors.mint : Colors.white,
            child: Row(
              children: [
                Icon(
                  active ? Icons.fact_check : Icons.location_on,
                  color: AppColors.forest,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    active
                        ? 'Inspection is in progress. Record what you find clearly.'
                        : 'Arrival confirmed. Begin only with the customer’s permission.',
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader('Customer issue photos'),
          const Row(
            children: [
              Expanded(
                child: _MockPhoto(
                  icon: Icons.electrical_services,
                  label: 'Customer photo',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _MockPhoto(icon: Icons.zoom_in, label: 'View detail'),
              ),
            ],
          ),
          const SectionHeader('Inspection evidence'),
          const PhotoUploadTile(label: 'Add inspection photos'),
          const SizedBox(height: 14),
          TextField(
            controller: _notes,
            minLines: 4,
            maxLines: 7,
            decoration: const InputDecoration(
              labelText: 'Inspection notes',
              hintText:
                  'Describe the cause, safety risks and recommended work.',
            ),
          ),
          const SizedBox(height: 18),
          if (!active)
            FilledButton(
              onPressed: () => ref
                  .read(appControllerProvider.notifier)
                  .updateJob(job.id, JobStatus.inspectionInProgress),
              child: const Text('Start inspection'),
            )
          else
            FilledButton(
              onPressed: () {
                if (_notes.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Add inspection notes before preparing a quote.',
                      ),
                    ),
                  );
                  return;
                }
                context.push('/quote/${job.id}');
              },
              child: const Text('Continue to quote builder'),
            ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => context.push('/report-issue'),
            icon: const Icon(Icons.support_agent),
            label: const Text('Contact support'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.prominent = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool prominent;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20, color: AppColors.forest),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: .8,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontSize: prominent ? 18 : 14,
                fontWeight: prominent ? FontWeight.w800 : FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _MockPhoto extends StatelessWidget {
  const _MockPhoto({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    height: 112,
    decoration: BoxDecoration(
      color: const Color(0xFFE7ECE9),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.forest, size: 35),
        const SizedBox(height: 7),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _JobTimeline extends StatelessWidget {
  const _JobTimeline({required this.status});
  final JobStatus status;
  @override
  Widget build(BuildContext context) {
    final progress = switch (status) {
      JobStatus.accepted => 1,
      JobStatus.onMyWay => 2,
      JobStatus.arrived ||
      JobStatus.inspectionInProgress ||
      JobStatus.quoteDraft => 3,
      JobStatus.quoteSubmitted || JobStatus.awaitingCustomerApproval => 4,
      JobStatus.quoteApproved || JobStatus.workInProgress => 5,
      JobStatus.workCompleted || JobStatus.awaitingCustomerConfirmation => 6,
      JobStatus.paymentProcessing || JobStatus.payoutPending => 7,
      JobStatus.paid => 8,
      _ => 0,
    };
    const labels = [
      'Accepted',
      'On my way',
      'Inspection',
      'Quote approval',
      'Work',
      'Completion',
      'Payout',
      'Paid',
    ];
    return Column(
      children: [
        for (var i = 0; i < labels.length; i++)
          TimelineStep(
            label: labels[i],
            complete: i < progress,
            current: i == progress && progress < 8,
            last: i == labels.length - 1,
          ),
      ],
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .8)
      ..strokeWidth = 3;
    for (var i = 0; i < 6; i++) {
      final y = 20.0 + i * 36;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + (i.isEven ? 22 : -14)),
        paint,
      );
    }
    paint.color = const Color(0xFFB6C9BE);
    paint.strokeWidth = 5;
    canvas.drawLine(
      Offset(size.width * .12, 0),
      Offset(size.width * .72, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height * .25),
      Offset(0, size.height * .75),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
