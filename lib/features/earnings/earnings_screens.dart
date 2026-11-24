import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grid_professionals/core/models/models.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';
import 'package:grid_professionals/core/utils/formatters.dart';
import 'package:grid_professionals/core/widgets/app_widgets.dart';
import 'package:grid_professionals/state/work_state.dart';

/// Balance, recent totals, and every earning and payout by day. GRID pays
/// out; this app only reports.
class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(earningsProvider);
    final payout = ref.watch(profileProvider).value?.payout;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppHeader(title: 'Earnings'),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(earningsProvider.future),
            child: AppPage(
              children: switch (overview) {
                AsyncData(:final value) => _content(context, value, payout),
                AsyncError() => [
                  RetryState(
                    title: 'Could not load your earnings',
                    message: 'Check your connection and try again.',
                    onRetry: () => ref.invalidate(earningsProvider),
                  ),
                ],
                _ => const [
                  LoadingSkeleton(height: 168, radius: AppRadius.xl),
                  SizedBox(height: 12),
                  LoadingSkeleton(height: 76, radius: AppRadius.md),
                ],
              },
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _content(
    BuildContext context,
    EarningsOverview overview,
    PayoutAccount? payout,
  ) {
    final activity = <(DateTime, Widget)>[
      for (final item in overview.earnings)
        (item.date, _EarningTile(earning: item)),
      for (final item in overview.payouts)
        (item.date, _PayoutTile(payout: item)),
    ]..sort((a, b) => b.$1.compareTo(a.$1));

    final rows = <Widget>[];
    String? day;
    for (final (date, tile) in activity) {
      final label = formatDay(date);
      if (label != day) {
        rows.add(DateChip(label));
        day = label;
      }
      rows.add(
        Padding(padding: const EdgeInsets.only(bottom: 12), child: tile),
      );
    }

    return [
      NavyPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AVAILABLE BALANCE',
              style: AppText.overline.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatCurrency(overview.available),
                style: AppText.amountXL.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              payout == null
                  ? 'Add a payout account so GRID can pay you.'
                  : 'GRID pays this out to ${payout.providerName}.',
              style: AppText.caption.copyWith(
                color: Colors.white70,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 18),
            OnNavyButton(
              label: 'Payout account',
              onPressed: () => context.push('/payout-account'),
            ),
          ],
        ),
      ),
      if (overview.pending > 0) ...[
        const SizedBox(height: 12),
        StatusBanner(
          kind: StatusKind.pending,
          title: '${formatCurrency(overview.pending)} waiting on customers',
          message:
              'It joins your balance when each customer confirms the job, '
              'or after a day if they don\'t.',
        ),
      ],
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: StatTile(
              label: 'Last 7 days',
              value: formatCurrency(overview.last7Days),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatTile(
              label: 'Last 30 days',
              value: formatCurrency(overview.last30Days),
            ),
          ),
        ],
      ),
      const SectionHeader('Activity'),
      if (rows.isEmpty)
        const EmptyState(
          title: 'Nothing here yet',
          message:
              'Each finished job shows here with what it paid, followed by '
              'the payouts GRID sends you.',
        )
      else
        ...rows,
    ];
  }
}

class _EarningTile extends StatelessWidget {
  const _EarningTile({required this.earning});
  final Earning earning;

  @override
  Widget build(BuildContext context) => _ActivityTile(
    time: formatTime(earning.date),
    status: switch (earning.status) {
      EarningStatus.pending => const StatusPill(
        label: 'Awaiting customer',
        kind: StatusKind.neutral,
      ),
      EarningStatus.available => const StatusPill(
        label: 'In balance',
        kind: StatusKind.pending,
      ),
      EarningStatus.paid => const StatusPill(
        label: 'Paid out',
        kind: StatusKind.success,
      ),
    },
    leading: ServiceBadge(service: earning.service, size: 42),
    title: earning.title,
    subtitle: '${earning.customer} · fee ${formatCurrency(earning.fee)}',
    amount: earning.net,
  );
}

class _PayoutTile extends StatelessWidget {
  const _PayoutTile({required this.payout});
  final Payout payout;

  @override
  Widget build(BuildContext context) => _ActivityTile(
    time: formatTime(payout.date),
    status: switch (payout.status) {
      PayoutStatus.paid => const StatusPill(
        label: 'Sent',
        kind: StatusKind.success,
      ),
      PayoutStatus.scheduled => const StatusPill(
        label: 'On its way',
        kind: StatusKind.pending,
      ),
      PayoutStatus.failed => const StatusPill(
        label: 'Failed',
        kind: StatusKind.danger,
      ),
    },
    leading: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.navySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.north_east_rounded,
        size: 21,
        color: AppColors.navy,
      ),
    ),
    title: 'Payout ${payout.reference}',
    subtitle: payout.destination,
    amount: payout.amount,
  );
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.time,
    required this.status,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.amount,
  });
  final String time;
  final Widget status;
  final Widget leading;
  final String title;
  final String subtitle;
  final double amount;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(flex: 3, child: Text(time, style: AppText.caption)),
            Flexible(
              flex: 2,
              child: Align(alignment: Alignment.centerRight, child: status),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.subtitle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(fontSize: 13.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Amount(amount),
          ],
        ),
      ],
    ),
  );
}

/// Where GRID sends earnings. Changes go through support so a stolen phone
/// can't redirect someone's pay.
class PayoutAccountScreen extends ConsumerWidget {
  const PayoutAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final account = profile.value?.payout;
    return FocusPage(
      title: 'Payout account',
      onBack: () => context.pop(),
      actions: [
        if (profile.hasValue)
          SecondaryButton(
            label: account == null
                ? 'Ask support to add one'
                : 'Change account',
            onPressed: () => context.push('/report-issue?about=payout'),
          ),
      ],
      children: [
        if (profile.isLoading && !profile.hasValue)
          const LoadingSkeleton(height: 200, radius: AppRadius.xl)
        else if (profile.hasError && !profile.hasValue)
          RetryState(
            title: 'Could not load your payout account',
            message: 'Check your connection and try again.',
            onRetry: () => ref.invalidate(profileProvider),
          )
        else if (account == null)
          const EmptyState(
            title: 'No payout account yet',
            message:
                'GRID needs a Mobile Money wallet or bank account before it '
                'can pay you, and before you can go online.',
          )
        else ...[
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E0),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                const CornerArcs(color: Color(0xFFFCEBB8)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 30),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.navy,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          account.mobileMoney
                              ? Icons.phone_iphone_rounded
                              : Icons.account_balance_rounded,
                          color: AppColors.amber,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        account.providerName,
                        textAlign: TextAlign.center,
                        style: AppText.title,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        account.verified
                            ? 'Verified · Default for payouts'
                            : 'Default for payouts',
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          DetailGroup(
            rows: [
              DetailRow(
                label: 'Name on account',
                value: account.accountName.toUpperCase(),
              ),
              DetailRow(
                label: account.mobileMoney ? 'Wallet number' : 'Account number',
                value: account.maskedNumber,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const StatusBanner(
            kind: StatusKind.neutral,
            title: 'Changes are checked by GRID',
            message:
                'To protect your pay, a new account is confirmed by our '
                'support team before any money goes to it.',
          ),
        ],
      ],
    );
  }
}
