import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grid_professionals/core/models/models.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';
import 'package:grid_professionals/core/utils/formatters.dart';
import 'package:grid_professionals/core/widgets/app_widgets.dart';
import 'package:grid_professionals/data/mock_data.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});
  @override
  Widget build(BuildContext context) => AppPage(
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              'Earnings',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          IconButton(
            onPressed: () => context.push('/job-history'),
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      const SizedBox(height: 16),
      const AppCard(
        color: AppColors.forest,
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AVAILABLE BALANCE',
              style: TextStyle(
                color: AppColors.mint,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'GH₵ 1,145.00',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Pending payout: GH₵ 780.00',
              style: TextStyle(color: AppColors.mint),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          const Expanded(
            child: MetricCard(
              label: 'Today',
              value: 'GH₵ 320',
              icon: Icons.today,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: MetricCard(
              label: 'This week',
              value: 'GH₵ 1,450',
              icon: Icons.date_range,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      const MetricCard(
        label: 'This month',
        value: 'GH₵ 5,860.00',
        icon: Icons.calendar_month,
        caption: '12 completed jobs',
      ),
      const SectionHeader('Earnings trend'),
      const _TrendChart(),
      SectionHeader(
        'Payouts',
        action: 'View details',
        onAction: () => context.push('/payouts'),
      ),
      AppCard(
        onTap: () => context.push('/payouts'),
        child: const Row(
          children: [
            Icon(Icons.schedule, color: AppColors.warning, size: 32),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next payout',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'GH₵ 780.00 • Fri, 17 Jul',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  Text(
                    'MTN MoMo •••• 0192',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            StatusChip(status: JobStatus.payoutPending),
          ],
        ),
      ),
      const SectionHeader('Job-by-job earnings'),
      for (final item in MockData.earnings)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${item.jobId} • ${formatDate(item.date)}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatCurrency(item.net),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Text(
                      'Gross ${formatCurrency(item.gross)}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'GRID commission ${formatCurrency(item.commission)}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

class _TrendChart extends StatelessWidget {
  const _TrendChart();
  @override
  Widget build(BuildContext context) {
    const values = [30.0, 58.0, 42.0, 86.0, 65.0, 104.0, 78.0];
    return AppCard(
      child: SizedBox(
        height: 150,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < values.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: values[i],
                        decoration: BoxDecoration(
                          color: i == 5 ? AppColors.forest : AppColors.mint,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PayoutDetailsScreen extends StatelessWidget {
  const PayoutDetailsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Payout details')),
    body: AppPage(
      children: [
        const MetricCard(
          label: 'Available payout balance',
          value: 'GH₵ 1,145.00',
          icon: Icons.account_balance_wallet,
          dark: true,
          caption: 'GH₵ 780.00 currently pending',
        ),
        const SectionHeader('Linked payout method'),
        const AppCard(
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFFFFD43B),
                child: Text(
                  'MTN',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MTN Mobile Money',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '+233 24 •••• 0192',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    Text(
                      'Mock payout method',
                      style: TextStyle(color: AppColors.warning, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(Icons.verified_outlined, color: AppColors.teal),
            ],
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.account_balance_outlined),
          label: const Text('Add bank account placeholder'),
        ),
        const SectionHeader('Payout history'),
        for (final payout in MockData.payouts)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              child: Row(
                children: [
                  Icon(
                    payout.status == PayoutStatus.paid
                        ? Icons.check_circle
                        : Icons.schedule,
                    color: payout.status == PayoutStatus.paid
                        ? AppColors.teal
                        : AppColors.warning,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatCurrency(payout.amount),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${payout.id} • ${formatDate(payout.date)}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    payout.status.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        SupportActionCard(
          icon: Icons.support_agent,
          title: 'Payout issue',
          subtitle: 'Report a delay or incorrect payout.',
          onTap: () => context.push('/report-issue'),
        ),
      ],
    ),
  );
}

class JobHistoryScreen extends StatelessWidget {
  const JobHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Job history')),
    body: AppPage(
      children: [
        const Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search jobs',
                ),
              ),
            ),
            SizedBox(width: 10),
            IconButton(onPressed: null, icon: Icon(Icons.filter_list)),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: const [
            ChoiceChip(label: Text('All'), selected: true),
            ChoiceChip(label: Text('Completed'), selected: false),
            ChoiceChip(label: Text('Cancelled'), selected: false),
          ],
        ),
        const SectionHeader('July 2026'),
        for (final job in MockData.jobs.where(
          (item) => item.status == JobStatus.paid,
        ))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: JobCard(
              job: job,
              onTap: () => context.push('/receipt/${job.id}'),
            ),
          ),
        const SectionHeader('Cancelled'),
        const EmptyStateCard(
          icon: Icons.event_busy,
          title: 'No cancelled jobs',
          message:
              'Cancelled and declined work will be listed here with reasons.',
        ),
      ],
    ),
  );
}
