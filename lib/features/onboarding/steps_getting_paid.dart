import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';
import 'package:grid_professionals/core/widgets/app_widgets.dart';
import 'package:grid_professionals/data/country/country_config.dart';
import 'package:grid_professionals/state/onboarding_state.dart';

class PricingStep extends ConsumerStatefulWidget {
  const PricingStep({super.key, required this.showErrors});
  final bool showErrors;

  @override
  ConsumerState<PricingStep> createState() => _PricingStepState();
}

class _PricingStepState extends ConsumerState<PricingStep> {
  late final TextEditingController _amount;
  late final TextEditingController _minimum;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(onboardingControllerProvider).draft;
    final config = ref.read(countryConfigProvider);
    final model = config.serviceById(draft.primaryServiceId)?.pricingModel;
    final amount = switch (model) {
      PricingModel.hourly => draft.hourlyRate,
      PricingModel.perItem => draft.minimumCharge,
      _ => draft.calloutFee,
    };
    _amount = TextEditingController(
      text: amount == null ? '' : _trimmed(amount),
    );
    _minimum = TextEditingController(
      text: draft.minimumCharge == null || model == PricingModel.perItem
          ? ''
          : _trimmed(draft.minimumCharge!),
    );
    _notes = TextEditingController(text: draft.pricingNotes);
  }

  static String _trimmed(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);

  @override
  void dispose() {
    _amount.dispose();
    _minimum.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingControllerProvider).draft;
    final controller = ref.read(onboardingControllerProvider.notifier);
    final config = ref.watch(countryConfigProvider);
    final service = config.serviceById(draft.primaryServiceId);
    final model = service?.pricingModel ?? PricingModel.calloutQuote;

    final (label, helper, explainer) = switch (model) {
      PricingModel.calloutQuote => (
        'Call-out fee',
        'Covers your travel and inspection. You quote the full job after '
            'inspecting it.',
        'For ${service?.name.toLowerCase() ?? 'your trade'}, customers pay a '
            'call-out fee for you to come and inspect, then approve your '
            'quote before work starts.',
      ),
      PricingModel.hourly => (
        'Hourly rate',
        'What you charge per hour of work.',
        'Customers see your hourly rate before they book you.',
      ),
      PricingModel.perItem => (
        'Starting price',
        'Your lowest price, e.g. wash & fold per basket.',
        'Customers see your starting price. You confirm the full price when '
            'you receive the items.',
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(explainer, style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 20),
        MoneyField(
          label: label,
          controller: _amount,
          helper: helper,
          onChanged: (value) {
            final parsed = _parsed(value);
            controller.updateDraft(
              (draft) => switch (model) {
                PricingModel.hourly => draft.copyWith(hourlyRate: parsed),
                PricingModel.perItem => draft.copyWith(minimumCharge: parsed),
                PricingModel.calloutQuote => draft.copyWith(calloutFee: parsed),
              },
            );
          },
        ),
        if (widget.showErrors && _parsed(_amount.text) == null) ...[
          const SizedBox(height: 8),
          InlineError(
            message: 'Enter your ${label.toLowerCase()} to continue.',
          ),
        ],
        if (model == PricingModel.hourly) ...[
          const SizedBox(height: 16),
          MoneyField(
            label: 'Minimum charge',
            controller: _minimum,
            optional: true,
            helper: 'The least a booking pays, even for short jobs.',
            onChanged: (value) => controller.updateDraft(
              (draft) => draft.copyWith(minimumCharge: _parsed(value)),
            ),
          ),
        ],
        const SizedBox(height: 16),
        FormTextField(
          label: 'Pricing notes',
          controller: _notes,
          optional: true,
          maxLines: 3,
          hint: model == PricingModel.perItem
              ? 'e.g. Wash & fold GH₵ 60 per basket, duvets GH₵ 80'
              : 'e.g. Weekend rates, material costs charged separately',
          textCapitalization: TextCapitalization.sentences,
          onChanged: (value) => controller.updateDraft(
            (draft) => draft.copyWith(pricingNotes: value),
          ),
        ),
      ],
    );
  }

  double? _parsed(String value) {
    final parsed = double.tryParse(value.trim());
    return parsed == null || parsed <= 0 ? null : parsed;
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
          'This is where GRID sends your earnings after each job.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        ChoiceCard(
          title: 'Mobile Money',
          subtitle: 'Paid to your MoMo wallet. Most providers choose this.',
          selected: draft.payoutType == PayoutType.mobileMoney,
          leading: const Icon(
            Icons.phone_android,
            color: AppColors.forest,
            size: 26,
          ),
          onTap: () => controller.updateDraft(
            (draft) => draft.copyWith(payoutType: PayoutType.mobileMoney),
          ),
        ),
        const SizedBox(height: 10),
        ChoiceCard(
          title: 'Bank account',
          subtitle: 'Paid to a Ghanaian bank account.',
          selected: draft.payoutType == PayoutType.bank,
          leading: const Icon(
            Icons.account_balance_outlined,
            color: AppColors.forest,
            size: 26,
          ),
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
