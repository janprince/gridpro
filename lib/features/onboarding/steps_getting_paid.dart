import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';
import 'package:grid_professionals/core/utils/formatters.dart';
import 'package:grid_professionals/core/widgets/app_widgets.dart';
import 'package:grid_professionals/data/country/country_config.dart';
import 'package:grid_professionals/state/onboarding_state.dart';

/// "What you earn": GRID's price for each package and the provider's share,
/// for every service they picked. Read-only; GRID sets one price per job.
class PricingStep extends ConsumerWidget {
  const PricingStep({super.key, required this.showErrors});
  final bool showErrors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingControllerProvider).draft;
    final config = ref.watch(countryConfigProvider);
    final fee = config.feePercent;
    final keep = 100 - fee;
    final services = [
      for (final id in draft.serviceIds) ?config.serviceById(id),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'GRID sets one price for every job, so customers book without '
          'haggling and you never have to quote. You keep ${_pct(keep)} of '
          'it. GRID\'s ${_pct(fee)} pays for finding you customers, taking '
          'payment and support.',
          style: AppText.bodyMuted,
        ),
        const SizedBox(height: 20),
        for (final service in services) ...[
          _EarningsCard(service: service, feePercent: fee),
          const SizedBox(height: 16),
        ],
        const StatusBanner(
          kind: StatusKind.neutral,
          title: 'Paid after every job',
          message:
              'Your earnings go to your payout account once the customer '
              'confirms the job is done.',
        ),
      ],
    );
  }

  static String _pct(double value) => value == value.roundToDouble()
      ? '${value.toStringAsFixed(0)}%'
      : '${value.toStringAsFixed(1)}%';
}

class _EarningsCard extends StatelessWidget {
  const _EarningsCard({required this.service, required this.feePercent});
  final ServiceDefinition service;
  final double feePercent;

  @override
  Widget build(BuildContext context) {
    final kind =
        ServiceKindInfo.fromName(service.id) ??
        ServiceKindInfo.fromName(service.name) ??
        ServiceKind.cleaning;
    final groups = <String, List<PackageRate>>{};
    for (final rate in service.rates) {
      groups.putIfAbsent(rate.group, () => []).add(rate);
    }

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ServiceBadge(service: kind, size: 40),
              const SizedBox(width: 12),
              Expanded(child: Text(service.name, style: AppText.heading)),
            ],
          ),
          const SizedBox(height: 12),
          if (service.rates.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'Prices show here once you\'re online.',
                style: AppText.caption,
              ),
            )
          else ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(child: Text('JOB', style: AppText.overline)),
                  Text('YOU EARN', style: AppText.overline),
                ],
              ),
            ),
            for (final entry in groups.entries) ...[
              if (groups.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 2),
                  child: Text(entry.key, style: AppText.label),
                ),
              for (final rate in entry.value)
                _RateRow(rate: rate, feePercent: feePercent),
            ],
          ],
        ],
      ),
    );
  }
}

class _RateRow extends StatelessWidget {
  const _RateRow({required this.rate, required this.feePercent});
  final PackageRate rate;
  final double feePercent;

  @override
  Widget build(BuildContext context) {
    final per = rate.unitLabel == null ? '' : ' per ${rate.unitLabel}';
    return Semantics(
      label:
          '${rate.name}: customer pays ${formatCurrency(rate.price)}$per, '
          'you earn ${formatCurrency(rate.earning(feePercent))}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rate.name, style: AppText.body),
                  const SizedBox(height: 2),
                  Text(
                    'Customer pays ${formatCurrency(rate.price)}$per',
                    style: AppText.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              formatCurrency(rate.earning(feePercent)),
              style: AppText.subtitle,
            ),
          ],
        ),
      ),
    );
  }
}

class PayoutStep extends ConsumerStatefulWidget {
  const PayoutStep({super.key, required this.showErrors});
  final bool showErrors;

  @override
  ConsumerState<PayoutStep> createState() => _PayoutStepState();
}

class _PayoutStepState extends ConsumerState<PayoutStep> {
  late final TextEditingController _momoNumber;
  late final TextEditingController _momoName;
  late final TextEditingController _accountNumber;
  late final TextEditingController _accountName;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(onboardingControllerProvider).draft;
    _momoNumber = TextEditingController(text: draft.momoNumber);
    _momoName = TextEditingController(text: draft.momoName);
    _accountNumber = TextEditingController(text: draft.bankAccountNumber);
    _accountName = TextEditingController(text: draft.bankAccountName);
  }

  @override
  void dispose() {
    _momoNumber.dispose();
    _momoName.dispose();
    _accountNumber.dispose();
    _accountName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingControllerProvider).draft;
    final controller = ref.read(onboardingControllerProvider.notifier);
    final config = ref.watch(countryConfigProvider);
    final momoProvider = config.mobileMoneyProviders
        .where((item) => item.id == draft.momoProviderId)
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'This is where GRID sends your earnings every Friday.',
          style: AppText.bodyMuted,
        ),
        const SizedBox(height: 20),
        ChoiceCard(
          title: 'Mobile Money',
          subtitle: 'Paid to your MoMo wallet. Most providers choose this.',
          selected: draft.payoutType == PayoutType.mobileMoney,
          leading: const ChoiceIcon(Icons.phone_android),
          onTap: () => controller.updateDraft(
            (draft) => draft.copyWith(payoutType: PayoutType.mobileMoney),
          ),
        ),
        const SizedBox(height: 10),
        ChoiceCard(
          title: 'Bank account',
          subtitle: 'Paid to a Ghanaian bank account.',
          selected: draft.payoutType == PayoutType.bank,
          leading: const ChoiceIcon(Icons.account_balance_outlined),
          onTap: () => controller.updateDraft(
            (draft) => draft.copyWith(payoutType: PayoutType.bank),
          ),
        ),
        if (widget.showErrors && draft.payoutType == null) ...[
          const SizedBox(height: 10),
          const InlineError(message: 'Choose how you want to be paid.'),
        ],
        if (draft.payoutType == PayoutType.mobileMoney) ...[
          const SizedBox(height: 20),
          SelectionRow(
            label: 'Mobile Money provider',
            value: momoProvider?.name,
            placeholder: 'Select provider',
            errorText: widget.showErrors && momoProvider == null
                ? 'Select your Mobile Money provider.'
                : null,
            onTap: () async {
              final choice = await showOptionPicker<MobileMoneyProvider>(
                context,
                title: 'Mobile Money provider',
                options: config.mobileMoneyProviders,
                labelOf: (item) => item.name,
                selected: momoProvider,
              );
              if (choice != null) {
                controller.updateDraft(
                  (draft) => draft.copyWith(momoProviderId: choice.id),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          PhoneNumberField(
            label: 'Mobile Money number',
            controller: _momoNumber,
            helper: 'Double-check this — payouts go to this number.',
            validator: null,
            errorText: widget.showErrors
                ? ghanaPhoneValidator(draft.momoNumber)
                : null,
            onChanged: (value) => controller.updateDraft(
              (draft) => draft.copyWith(momoNumber: value),
            ),
          ),
          const SizedBox(height: 16),
          FormTextField(
            label: 'Registered wallet name',
            controller: _momoName,
            hint: 'Name on the MoMo account',
            helper: 'Must match your Ghana Card name for verification.',
            textCapitalization: TextCapitalization.words,
            errorText: widget.showErrors && draft.momoName.trim().isEmpty
                ? 'Enter the name registered on the wallet.'
                : null,
            onChanged: (value) => controller.updateDraft(
              (draft) => draft.copyWith(momoName: value),
            ),
          ),
        ],
        if (draft.payoutType == PayoutType.bank) ...[
          const SizedBox(height: 20),
          SelectionRow(
            label: 'Bank',
            value: draft.bankName,
            placeholder: 'Select your bank',
            errorText: widget.showErrors && draft.bankName == null
                ? 'Select your bank.'
                : null,
            onTap: () async {
              final choice = await showOptionPicker<String>(
                context,
                title: 'Select your bank',
                options: config.banks,
                labelOf: (bank) => bank,
                selected: draft.bankName,
              );
              if (choice != null) {
                controller.updateDraft(
                  (draft) => draft.copyWith(bankName: choice),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          FormTextField(
            label: 'Account number',
            controller: _accountNumber,
            keyboardType: TextInputType.number,
            maxLength: 16,
            errorText:
                widget.showErrors && draft.bankAccountNumber.trim().length < 8
                ? 'Enter your full account number.'
                : null,
            onChanged: (value) => controller.updateDraft(
              (draft) => draft.copyWith(bankAccountNumber: value),
            ),
          ),
          const SizedBox(height: 16),
          FormTextField(
            label: 'Account name',
            controller: _accountName,
            hint: 'Name on the bank account',
            helper: 'Must match your Ghana Card name for verification.',
            textCapitalization: TextCapitalization.words,
            errorText: widget.showErrors && draft.bankAccountName.trim().isEmpty
                ? 'Enter the name on the account.'
                : null,
            onChanged: (value) => controller.updateDraft(
              (draft) => draft.copyWith(bankAccountName: value),
            ),
          ),
        ],
      ],
    );
  }
}
