import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grid_professionals/core/models/models.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';
import 'package:grid_professionals/core/widgets/app_widgets.dart';
import 'package:grid_professionals/state/onboarding_state.dart';

class ProviderTypeStep extends ConsumerWidget {
  const ProviderTypeStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingControllerProvider).draft;
    final controller = ref.read(onboardingControllerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'This shapes the questions we ask next. You can offer the same '
          'services either way.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        ChoiceCard(
          title: 'I work on my own',
          subtitle: 'An independent professional, like a plumber or cleaner.',
          selected: draft.providerType == ProviderType.individual,
          leading: const Icon(
            Icons.person_outline,
            color: AppColors.forest,
            size: 28,
          ),
          onTap: () => controller.updateDraft(
            (draft) => draft.copyWith(providerType: ProviderType.individual),
          ),
        ),
        const SizedBox(height: 12),
        ChoiceCard(
          title: 'I run a small business',
          subtitle: 'A registered or informal business, like a laundry shop.',
          selected: draft.providerType == ProviderType.business,
          leading: const Icon(
            Icons.storefront_outlined,
            color: AppColors.forest,
            size: 28,
          ),
          onTap: () => controller.updateDraft(
            (draft) => draft.copyWith(providerType: ProviderType.business),
          ),
        ),
      ],
    );
  }
}

class DetailsStep extends ConsumerStatefulWidget {
  const DetailsStep({super.key, required this.showErrors});
  final bool showErrors;

  @override
  ConsumerState<DetailsStep> createState() => _DetailsStepState();
}

class _DetailsStepState extends ConsumerState<DetailsStep> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _business;
  late final TextEditingController _premises;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(onboardingControllerProvider).draft;
    _name = TextEditingController(text: draft.fullName);
    _email = TextEditingController(text: draft.email);
    _business = TextEditingController(text: draft.businessName);
    _premises = TextEditingController(text: draft.premisesAddress);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _business.dispose();
    _premises.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingControllerProvider).draft;
    final controller = ref.read(onboardingControllerProvider.notifier);
    final isBusiness = draft.isBusiness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isBusiness) ...[
          FormTextField(
            label: 'Business name',
            controller: _business,
            hint: 'e.g. Mensah Electrical Works',
            textCapitalization: TextCapitalization.words,
            errorText: widget.showErrors && draft.businessName.trim().isEmpty
                ? 'Enter your business name.'
                : null,
            onChanged: (value) => controller.updateDraft(
              (draft) => draft.copyWith(businessName: value),
            ),
          ),
          const SizedBox(height: 16),
        ],
        FormTextField(
          label: isBusiness ? 'Your full name' : 'Full name',
          controller: _name,
          hint: 'As it appears on your Ghana Card',
          textCapitalization: TextCapitalization.words,
          helper: 'Must match your ID for verification.',
          errorText: widget.showErrors && draft.fullName.trim().length < 3
              ? 'Enter your full name as it appears on your ID.'
              : null,
          onChanged: (value) => controller.updateDraft(
            (draft) => draft.copyWith(fullName: value),
          ),
        ),
        const SizedBox(height: 16),
        FormTextField(
          label: 'Email',
          controller: _email,
          optional: true,
          keyboardType: TextInputType.emailAddress,
          hint: 'name@example.com',
          onChanged: (value) =>
              controller.updateDraft((draft) => draft.copyWith(email: value)),
        ),
        const SizedBox(height: 24),
        Text(
          'How do you serve customers?',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 10),
        ChoiceCard(
          title: 'I travel to customers',
          subtitle: 'You work at the customer\'s home or premises.',
          selected: draft.delivery == ServiceDelivery.travels,
          onTap: () => controller.updateDraft(
            (draft) => draft.copyWith(delivery: ServiceDelivery.travels),
          ),
        ),
        const SizedBox(height: 10),
        ChoiceCard(
          title: 'Customers come to me',
          subtitle: 'You work from a fixed place, like a laundry or workshop.',
          selected: draft.delivery == ServiceDelivery.fixedPremises,
          onTap: () => controller.updateDraft(
            (draft) => draft.copyWith(delivery: ServiceDelivery.fixedPremises),
          ),
        ),
        const SizedBox(height: 10),
        ChoiceCard(
          title: 'Both',
          subtitle: 'You have premises and also travel out for jobs.',
          selected: draft.delivery == ServiceDelivery.both,
          onTap: () => controller.updateDraft(
            (draft) => draft.copyWith(delivery: ServiceDelivery.both),
          ),
        ),
        if (widget.showErrors && draft.delivery == null) ...[
          const SizedBox(height: 10),
          const InlineError(message: 'Choose how you serve customers.'),
        ],
        if (draft.servesAtPremises) ...[
          const SizedBox(height: 16),
          FormTextField(
            label: 'Premises address',
            controller: _premises,
            hint: 'e.g. Shop 4, Boundary Road, Spintex',
            textCapitalization: TextCapitalization.words,
            errorText: widget.showErrors && draft.premisesAddress.trim().isEmpty
                ? 'Enter where customers can find you.'
                : null,
            onChanged: (value) => controller.updateDraft(
              (draft) => draft.copyWith(premisesAddress: value),
            ),
          ),
        ],
      ],
    );
  }
}
