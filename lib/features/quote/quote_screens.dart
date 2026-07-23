import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grid_professionals/core/models/models.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';
import 'package:grid_professionals/core/utils/formatters.dart';
import 'package:grid_professionals/core/widgets/app_widgets.dart';
import 'package:grid_professionals/state/app_state.dart';

class QuoteBuilderScreen extends ConsumerStatefulWidget {
  const QuoteBuilderScreen({super.key, required this.jobId});
  final String jobId;
  @override
  ConsumerState<QuoteBuilderScreen> createState() => _QuoteBuilderScreenState();
}

class _QuoteBuilderScreenState extends ConsumerState<QuoteBuilderScreen> {
  final _form = GlobalKey<FormState>();
  final _labour = TextEditingController(text: '180');
  final _material = TextEditingController(text: 'Circuit breaker');
  final _quantity = TextEditingController(text: '2');
  final _unitPrice = TextEditingController(text: '120');
  final _notes = TextEditingController(
    text:
        'Replace damaged breakers, tighten terminals and complete a full load test.',
  );
  final _duration = TextEditingController(text: '3 hours');
  final _warranty = TextEditingController(text: '90 days');
  @override
  void dispose() {
    for (final c in [
      _labour,
      _material,
      _quantity,
      _unitPrice,
      _notes,
      _duration,
      _warranty,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double get _labourValue => double.tryParse(_labour.text) ?? 0;
  double get _materialTotal =>
      (double.tryParse(_quantity.text) ?? 0) *
      (double.tryParse(_unitPrice.text) ?? 0);
  Quote _quote(double callout) => Quote(
    jobId: widget.jobId,
    labour: _labourValue,
    materials: [
      MaterialItem(
        name: _material.text,
        quantity: double.tryParse(_quantity.text) ?? 0,
        unitPrice: double.tryParse(_unitPrice.text) ?? 0,
      ),
    ],
    notes: _notes.text,
    duration: _duration.text,
    warranty: _warranty.text,
    calloutFee: callout,
  );
  @override
  Widget build(BuildContext context) {
    final job = ref
        .watch(appControllerProvider)
        .jobs
        .firstWhere((item) => item.id == widget.jobId);
    final total = job.calloutFee + _labourValue + _materialTotal;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Build professional quote'),
        actions: [
          TextButton(
            onPressed: () {
              ref
                  .read(appControllerProvider.notifier)
                  .saveQuote(_quote(job.calloutFee));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Quote draft saved locally.')),
              );
            },
            child: const Text('Save draft'),
          ),
        ],
      ),
      body: Form(
        key: _form,
        child: AppPage(
          children: [
            AppCard(
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.mint,
                    child: Icon(Icons.receipt_long, color: AppColors.forest),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.summary,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${job.id} • ${job.customerName}',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SectionHeader('Labour'),
            TextFormField(
              controller: _labour,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Labour cost',
                prefixText: 'GH₵ ',
              ),
              onChanged: (_) => setState(() {}),
              validator: (value) {
                final amount = double.tryParse(value ?? '');
                return amount == null || amount <= 0
                    ? 'Enter a valid labour cost'
                    : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _duration,
              decoration: const InputDecoration(
                labelText: 'Estimated duration',
              ),
              validator: requiredValidator,
            ),
            SectionHeader(
              'Materials',
              action: '+ Add item',
              onAction: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('A new mock material line is ready.'),
                ),
              ),
            ),
            AppCard(
              child: Column(
                children: [
                  TextFormField(
                    controller: _material,
                    decoration: const InputDecoration(
                      labelText: 'Material name',
                    ),
                    validator: requiredValidator,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _quantity,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: _positive,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _unitPrice,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Unit price',
                            prefixText: 'GH₵ ',
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: _positive,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text('Material subtotal'),
                      const Spacer(),
                      Text(
                        formatCurrency(_materialTotal),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SectionHeader('Notes & details'),
            TextFormField(
              controller: _notes,
              minLines: 4,
              maxLines: 7,
              decoration: const InputDecoration(
                labelText: 'Scope and professional notes',
              ),
              validator: requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _warranty,
              decoration: const InputDecoration(
                labelText: 'Warranty period (optional)',
              ),
            ),
            const SizedBox(height: 12),
            const PhotoUploadTile(
              label: 'Attach quote photo (mock)',
              compact: true,
            ),
            const SizedBox(height: 12),
            const TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Discount / adjustment',
                hintText: 'Future placeholder',
              ),
            ),
            const SectionHeader('Quote total'),
            _QuoteTotals(
              callout: job.calloutFee,
              labour: _labourValue,
              materials: _materialTotal,
              total: total,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                if (_form.currentState!.validate()) {
                  final quote = _quote(job.calloutFee);
                  ref.read(appControllerProvider.notifier).saveQuote(quote);
                  context.push('/quote-preview/${job.id}');
                }
              },
              child: const Text('Preview quote'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                if (_form.currentState!.validate()) {
                  ref
                      .read(appControllerProvider.notifier)
                      .saveQuote(_quote(job.calloutFee));
                }
              },
              child: const Text('Save draft'),
            ),
          ],
        ),
      ),
    );
  }

  String? _positive(String? value) {
    final amount = double.tryParse(value ?? '');
    return amount == null || amount <= 0 ? 'Enter a valid amount' : null;
  }
}

class QuotePreviewScreen extends ConsumerWidget {
  const QuotePreviewScreen({super.key, required this.jobId});
  final String jobId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final job = state.jobs.firstWhere((item) => item.id == jobId);
    final quote =
        state.draftQuote ??
        Quote(
          jobId: jobId,
          labour: 180,
          materials: const [
            MaterialItem(name: 'Circuit breaker', quantity: 2, unitPrice: 120),
          ],
          notes: 'Replace damaged breakers and complete load testing.',
          duration: '3 hours',
          warranty: '90 days',
          calloutFee: job.calloutFee,
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Quote preview')),
      body: AppPage(
        children: [
          const AppCard(
            color: AppColors.forest,
            child: Row(
              children: [
                Icon(Icons.verified_user_outlined, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'GRID PROFESSIONAL QUOTE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.customerName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${job.summary} • ${job.id}',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const Divider(height: 28),
                _PreviewRow('Call-out / inspection fee', quote.calloutFee),
                _PreviewRow('Professional labour', quote.labour),
                for (final item in quote.materials)
                  _PreviewRow(
                    '${item.name} × ${item.quantity.toStringAsFixed(0)}',
                    item.total,
                  ),
                const Divider(height: 28),
                Row(
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const Spacer(),
                    Text(
                      formatCurrency(quote.total),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        color: AppColors.forest,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SectionHeader('Scope of work'),
          Text(quote.notes),
          const SectionHeader('Commitments'),
          AppCard(
            child: Column(
              children: [
                _InfoLine(
                  icon: Icons.schedule,
                  label: 'Estimated duration',
                  value: quote.duration,
                ),
                const Divider(),
                _InfoLine(
                  icon: Icons.shield_outlined,
                  label: 'Workmanship warranty',
                  value: quote.warranty,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () async {
              final ok = await showConfirmationSheet(
                context,
                title: 'Submit quote?',
                message:
                    'The customer will review this professional breakdown. You may edit it only before approval.',
                confirmLabel: 'Submit for approval',
              );
              if (ok) {
                ref.read(appControllerProvider.notifier).submitQuote(quote);
                if (context.mounted) context.go('/quote-awaiting/$jobId');
              }
            },
            child: const Text('Submit quote'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => context.pop(),
            child: const Text('Edit quote'),
          ),
        ],
      ),
    );
  }
}

class QuoteAwaitingScreen extends ConsumerWidget {
  const QuoteAwaitingScreen({super.key, required this.jobId});
  final String jobId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref
        .watch(appControllerProvider)
        .jobs
        .firstWhere((item) => item.id == jobId);
    return Scaffold(
      appBar: AppBar(title: const Text('Quote status')),
      body: AppPage(
        children: [
          const SizedBox(height: 20),
          const Center(
            child: CircleAvatar(
              radius: 45,
              backgroundColor: AppColors.infoBg,
              child: Icon(Icons.hourglass_top, color: AppColors.info, size: 42),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Awaiting customer approval',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Your quote has been sent. We will notify you when the customer responds.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          MetricCard(
            label: 'Submitted quote',
            value: formatCurrency(job.quoteTotal ?? 470),
            icon: Icons.receipt_long,
            caption: 'Submitted today at ${formatTime(DateTime.now())}',
          ),
          const SizedBox(height: 14),
          const AppCard(
            color: Color(0xFFFFF1D6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber, color: AppColors.warning),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Do not begin work until the customer approves the quote.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader('Available actions'),
          OutlinedButton(
            onPressed: () => context.push('/quote/$jobId'),
            child: const Text('Edit quote before approval'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => context.push('/report-issue'),
            icon: const Icon(Icons.support_agent),
            label: const Text('Contact support'),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () {
              ref
                  .read(appControllerProvider.notifier)
                  .updateJob(jobId, JobStatus.quoteApproved);
              context.go('/quote-approved/$jobId');
            },
            child: const Text('Simulate customer approval'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Demo control — no real customer approval occurs.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class QuoteApprovedScreen extends ConsumerWidget {
  const QuoteApprovedScreen({super.key, required this.jobId});
  final String jobId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref
        .watch(appControllerProvider)
        .jobs
        .firstWhere((item) => item.id == jobId);
    return Scaffold(
      appBar: AppBar(title: const Text('Quote approved')),
      body: AppPage(
        children: [
          const SizedBox(height: 20),
          const Center(
            child: CircleAvatar(
              radius: 45,
              backgroundColor: AppColors.mint,
              child: Icon(Icons.check, color: AppColors.forest, size: 46),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Customer approved your quote',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Approval recorded in this mocked job flow.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          MetricCard(
            label: 'Approved amount',
            value: formatCurrency(job.quoteTotal ?? 470),
            icon: Icons.verified,
            dark: true,
            caption: 'Approved today at ${formatTime(DateTime.now())}',
          ),
          const SectionHeader('Approved commitment'),
          const AppCard(
            child: Column(
              children: [
                _InfoLine(
                  icon: Icons.schedule,
                  label: 'Estimated duration',
                  value: '3 hours',
                ),
                Divider(),
                _InfoLine(
                  icon: Icons.shield_outlined,
                  label: 'Warranty',
                  value: '90 days',
                ),
                Divider(),
                _InfoLine(
                  icon: Icons.receipt_long,
                  label: 'Scope',
                  value: 'Replace breakers and load test',
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: () async {
              final ok = await showConfirmationSheet(
                context,
                title: 'Begin approved work?',
                message:
                    'Start only when the site is safe and the approved scope is understood.',
                confirmLabel: 'Begin work',
              );
              if (ok) {
                ref
                    .read(appControllerProvider.notifier)
                    .updateJob(jobId, JobStatus.workInProgress);
                if (context.mounted) context.go('/work/$jobId');
              }
            },
            child: const Text('Begin work'),
          ),
        ],
      ),
    );
  }
}

class WorkInProgressScreen extends ConsumerStatefulWidget {
  const WorkInProgressScreen({super.key, required this.jobId});
  final String jobId;
  @override
  ConsumerState<WorkInProgressScreen> createState() =>
      _WorkInProgressScreenState();
}

class _WorkInProgressScreenState extends ConsumerState<WorkInProgressScreen> {
  final _note = TextEditingController();
  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final job = ref
        .watch(appControllerProvider)
        .jobs
        .firstWhere((item) => item.id == widget.jobId);
    return Scaffold(
      appBar: AppBar(title: const Text('Work in progress')),
      body: AppPage(
        children: [
          AppCard(
            color: AppColors.forest,
            child: Row(
              children: [
                const Icon(Icons.handyman, color: Colors.white, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.summary,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'Approved work is now in progress',
                        style: TextStyle(color: AppColors.mint),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader('Approved quote'),
          MetricCard(
            label: 'Approved total',
            value: formatCurrency(job.quoteTotal ?? 470),
            icon: Icons.receipt_long,
            caption: 'Warranty: 90 days',
          ),
          const SectionHeader('Progress record'),
          TextField(
            controller: _note,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Add progress note',
              hintText: 'What has been completed?',
            ),
          ),
          const SizedBox(height: 12),
          const PhotoUploadTile(label: 'Add progress photo'),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => context.push('/complete/${job.id}'),
            child: const Text('Mark job complete'),
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

class CompletionScreen extends ConsumerStatefulWidget {
  const CompletionScreen({super.key, required this.jobId});
  final String jobId;
  @override
  ConsumerState<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends ConsumerState<CompletionScreen> {
  final _notes = TextEditingController(
    text:
        'Replaced damaged breakers, secured all terminals and tested circuits under load.',
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
    return Scaffold(
      appBar: AppBar(title: const Text('Complete job')),
      body: AppPage(
        children: [
          const AppCard(
            color: AppColors.mint,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: AppColors.forest),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Clear photos help protect your work and build customer trust.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader('Before photos'),
          const PhotoUploadTile(label: 'Add before photos'),
          const SectionHeader('After photos'),
          const PhotoUploadTile(label: 'Add after photos'),
          const SectionHeader('Completion record'),
          TextField(
            controller: _notes,
            minLines: 4,
            maxLines: 7,
            decoration: const InputDecoration(labelText: 'Completion notes'),
          ),
          const SizedBox(height: 12),
          const TextField(
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Materials used summary',
              hintText: '2 × circuit breakers',
            ),
          ),
          const SizedBox(height: 12),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Warranty details',
              hintText: '90 days workmanship',
            ),
          ),
          const SizedBox(height: 12),
          const TextField(
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Follow-up recommendations (optional)',
            ),
          ),
          const SectionHeader('Customer confirmation'),
          const AppCard(
            child: Row(
              children: [
                Icon(Icons.person_search, color: AppColors.forest),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Customer confirmation will be requested after submission. This is a mock placeholder.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () async {
              if (_notes.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add completion notes.')),
                );
                return;
              }
              final ok = await showConfirmationSheet(
                context,
                title: 'Submit completion?',
                message:
                    'Your evidence and notes will be sent to the customer for confirmation.',
                confirmLabel: 'Confirm completion',
              );
              if (ok) {
                ref
                    .read(appControllerProvider.notifier)
                    .updateJob(job.id, JobStatus.awaitingCustomerConfirmation);
                if (context.mounted) context.go('/payment/${job.id}');
              }
            },
            child: const Text('Confirm completion'),
          ),
        ],
      ),
    );
  }
}

class PaymentStatusScreen extends ConsumerWidget {
  const PaymentStatusScreen({super.key, required this.jobId});
  final String jobId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref
        .watch(appControllerProvider)
        .jobs
        .firstWhere((item) => item.id == jobId);
    final amount = job.quoteTotal ?? 470;
    final commission = amount * .15;
    return Scaffold(
      appBar: AppBar(title: const Text('Completion & payment')),
      body: AppPage(
        children: [
          const SizedBox(height: 12),
          Center(
            child: CircleAvatar(
              radius: 42,
              backgroundColor: job.status == JobStatus.paid
                  ? AppColors.mint
                  : AppColors.infoBg,
              child: Icon(
                job.status == JobStatus.paid
                    ? Icons.check
                    : Icons.hourglass_top,
                color: job.status == JobStatus.paid
                    ? AppColors.forest
                    : AppColors.info,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            job.status == JobStatus.paid
                ? 'Payout complete'
                : job.status == JobStatus.payoutPending
                ? 'Your payout is being processed.'
                : 'Awaiting customer confirmation',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            job.status == JobStatus.awaitingCustomerConfirmation
                ? 'The customer has been asked to review the completed work.'
                : 'GRID is processing this mocked payment and payout record.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          AppCard(
            child: Column(
              children: [
                _PreviewRow('Job total', amount),
                _PreviewRow('GRID commission (15%)', -commission),
                const Divider(height: 28),
                Row(
                  children: [
                    const Text(
                      'EXPECTED PAYOUT',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const Spacer(),
                    Text(
                      formatCurrency(amount - commission),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: AppColors.forest,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SectionHeader('Payment progress'),
          AppCard(
            child: Column(
              children: [
                TimelineStep(label: 'Job completed', complete: true),
                TimelineStep(
                  label: 'Customer confirmation',
                  complete:
                      job.status != JobStatus.awaitingCustomerConfirmation,
                  current: job.status == JobStatus.awaitingCustomerConfirmation,
                ),
                TimelineStep(
                  label: 'Payment processing',
                  complete: {
                    JobStatus.payoutPending,
                    JobStatus.paid,
                  }.contains(job.status),
                  current: job.status == JobStatus.paymentProcessing,
                ),
                TimelineStep(
                  label: 'Payout pending',
                  complete: job.status == JobStatus.paid,
                  current: job.status == JobStatus.payoutPending,
                ),
                TimelineStep(
                  label: 'Paid',
                  complete: job.status == JobStatus.paid,
                  current: false,
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (job.status != JobStatus.paid)
            FilledButton(
              onPressed: () {
                final next =
                    job.status == JobStatus.awaitingCustomerConfirmation
                    ? JobStatus.paymentProcessing
                    : job.status == JobStatus.paymentProcessing
                    ? JobStatus.payoutPending
                    : JobStatus.paid;
                ref
                    .read(appControllerProvider.notifier)
                    .updateJob(job.id, next);
              },
              child: const Text('Advance mock payment state'),
            )
          else
            FilledButton(
              onPressed: () => context.push('/receipt/${job.id}'),
              child: const Text('View receipt'),
            ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => context.go('/earnings'),
            child: const Text('View earnings'),
          ),
        ],
      ),
    );
  }
}

class ReceiptScreen extends ConsumerWidget {
  const ReceiptScreen({super.key, required this.jobId});
  final String jobId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref
        .watch(appControllerProvider)
        .jobs
        .firstWhere((item) => item.id == jobId);
    final amount = job.quoteTotal ?? 470;
    return Scaffold(
      appBar: AppBar(title: const Text('Job receipt')),
      body: AppPage(
        children: [
          const Center(child: GridMark()),
          const SizedBox(height: 18),
          const Center(
            child: Chip(
              avatar: Icon(Icons.check_circle, color: AppColors.teal),
              label: Text('PAID — MOCK RECEIPT'),
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              children: [
                _ReceiptLine('Job type', job.summary),
                _ReceiptLine('Customer', job.customerName),
                _ReceiptLine('Area', job.area),
                _ReceiptLine(
                  'Completed',
                  '${formatDate(job.scheduledAt)} • ${formatTime(job.scheduledAt)}',
                ),
                const Divider(height: 30),
                _ReceiptLine('Total amount', formatCurrency(amount)),
                _ReceiptLine('GRID commission', formatCurrency(amount * .15)),
                _ReceiptLine(
                  'Professional earnings',
                  formatCurrency(amount * .85),
                  strong: true,
                ),
                _ReceiptLine('Payment status', 'Paid'),
                _ReceiptLine('Transaction ID', 'GRID-${job.id}-GH'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'This is a sample receipt. No real transaction or payout occurred.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Download/share is a placeholder.')),
            ),
            icon: const Icon(Icons.ios_share),
            label: const Text('Download or share placeholder'),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: () => context.go('/jobs'),
            child: const Text('Return to jobs'),
          ),
        ],
      ),
    );
  }
}

class _QuoteTotals extends StatelessWidget {
  const _QuoteTotals({
    required this.callout,
    required this.labour,
    required this.materials,
    required this.total,
  });
  final double callout, labour, materials, total;
  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.forest,
    child: Column(
      children: [
        _DarkRow('Call-out fee', callout),
        _DarkRow('Labour', labour),
        _DarkRow('Materials', materials),
        const Divider(color: Color(0xFF55796E)),
        Row(
          children: [
            const Text(
              'TOTAL',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Text(
              formatCurrency(total),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 23,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _DarkRow extends StatelessWidget {
  const _DarkRow(this.label, this.amount);
  final String label;
  final double amount;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Text(label, style: const TextStyle(color: AppColors.mint)),
        const Spacer(),
        Text(
          formatCurrency(amount),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow(this.label, this.amount);
  final String label;
  final double amount;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          formatCurrency(amount),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: AppColors.forest),
    title: Text(label),
    trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
  );
}

class _ReceiptLine extends StatelessWidget {
  const _ReceiptLine(this.label, this.value, {this.strong = false});
  final String label, value;
  final bool strong;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: AppColors.muted)),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
              fontSize: strong ? 17 : 14,
              color: strong ? AppColors.forest : null,
            ),
          ),
        ),
      ],
    ),
  );
}
