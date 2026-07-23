import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';
import 'package:grid_professionals/core/widgets/app_widgets.dart';
import 'package:grid_professionals/data/country/country_config.dart';
import 'package:grid_professionals/state/onboarding_state.dart';

class ServicesStep extends ConsumerWidget {
  const ServicesStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingControllerProvider).draft;
    final controller = ref.read(onboardingControllerProvider.notifier);
    final config = ref.watch(countryConfigProvider);
    final service = config.serviceById(draft.primaryServiceId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose your main service. You can add more services after your '
          'profile is approved.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 130,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.82,
          ),
          itemCount: config.services.length,
          itemBuilder: (context, index) {
            final item = config.services[index];
            return ServiceCard(
              service: item,
              selected: item.id == draft.primaryServiceId,
              onTap: () => controller.updateDraft(
                (draft) => draft.copyWith(
                  primaryServiceId: item.id,
                  // Sub-services belong to the selected service.
                  subServices: item.id == draft.primaryServiceId
                      ? draft.subServices
                      : const [],
                ),
              ),
            );
          },
        ),
        if (service != null) ...[
          const SizedBox(height: 24),
          Text(
            'What do you do within ${service.name.toLowerCase()}?',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Select everything you handle confidently.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final sub in service.subServices)
                FilterChip(
                  label: Text(sub),
                  selected: draft.subServices.contains(sub),
                  onSelected: (value) => controller.updateDraft(
                    (draft) => draft.copyWith(
                      subServices: value
                          ? [...draft.subServices, sub]
                          : draft.subServices
                                .where((item) => item != sub)
                                .toList(),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class ExperienceStep extends ConsumerStatefulWidget {
  const ExperienceStep({super.key, required this.showErrors});
  final bool showErrors;

  @override
  ConsumerState<ExperienceStep> createState() => _ExperienceStepState();
}

class _ExperienceStepState extends ConsumerState<ExperienceStep> {
  late final TextEditingController _summary;
  late final TextEditingController _tools;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(onboardingControllerProvider).draft;
    _summary = TextEditingController(text: draft.experienceSummary);
    _tools = TextEditingController(text: draft.toolsEquipment);
  }

  @override
  void dispose() {
    _summary.dispose();
    _tools.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingControllerProvider).draft;
    final controller = ref.read(onboardingControllerProvider.notifier);
    final config = ref.watch(countryConfigProvider);
    final service = config.serviceById(draft.primaryServiceId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectionRow(
          label: 'Years of experience',
          value: draft.yearsExperience == null
              ? null
              : draft.yearsExperience == 0
              ? 'Less than a year'
              : draft.yearsExperience == 1
              ? '1 year'
              : '${draft.yearsExperience} years',
          placeholder: 'Select years',
          errorText: widget.showErrors && draft.yearsExperience == null
              ? 'Select how long you have been doing this work.'
              : null,
          onTap: () async {
            final choice = await showOptionPicker<int>(
              context,
              title: 'Years of experience',
              options: [for (var y = 0; y <= 30; y++) y],
              labelOf: (y) => y == 0
                  ? 'Less than a year'
                  : y == 30
                  ? '30+ years'
                  : y == 1
                  ? '1 year'
                  : '$y years',
              selected: draft.yearsExperience,
            );
            if (choice != null) {
              controller.updateDraft(
                (draft) => draft.copyWith(yearsExperience: choice),
              );
            }
          },
        ),
        const SizedBox(height: 16),
        FormTextField(
          label: 'Describe your work',
          controller: _summary,
          maxLines: 4,
          maxLength: 300,
          hint:
              service?.experienceHint ??
              'Tell customers what you do best and the work you take on.',
          helper: 'This appears on your public profile.',
          textCapitalization: TextCapitalization.sentences,
          errorText: widget.showErrors && draft.experienceSummary.trim().isEmpty
              ? 'Write one or two sentences about your work.'
              : null,
          onChanged: (value) => controller.updateDraft(
            (draft) => draft.copyWith(experienceSummary: value),
          ),
        ),
        const SizedBox(height: 16),
        FormTextField(
          label: 'Tools and equipment',
          controller: _tools,
          optional: true,
          maxLines: 2,
          hint: 'e.g. Full toolkit, ladder, pressure washer',
          textCapitalization: TextCapitalization.sentences,
          onChanged: (value) => controller.updateDraft(
            (draft) => draft.copyWith(toolsEquipment: value),
          ),
        ),
      ],
    );
  }
}

class ServiceAreaStep extends ConsumerWidget {
  const ServiceAreaStep({super.key, required this.showErrors});
  final bool showErrors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingControllerProvider).draft;
    final controller = ref.read(onboardingControllerProvider.notifier);
    final config = ref.watch(countryConfigProvider);
    final region = config.regionByName(draft.region);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          draft.travelsToCustomers
              ? 'Job offers are matched to the areas you cover.'
              : 'Customers nearby will find your premises through these areas.',
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        SelectionRow(
          label: 'Region',
          value: draft.region,
          placeholder: 'Select your region',
          errorText: showErrors && draft.region == null
              ? 'Select the region where you work.'
              : null,
          onTap: () async {
            final choice = await showOptionPicker<RegionDefinition>(
              context,
              title: 'Select your region',
              options: config.regions,
              labelOf: (region) => region.name,
              selected: region,
            );
            if (choice != null && choice.name != draft.region) {
              controller.updateDraft(
                (draft) => draft.copyWith(region: choice.name, towns: const []),
              );
            }
          },
        ),
        if (region != null) ...[
          const SizedBox(height: 20),
          Text(
            draft.travelsToCustomers ? 'Areas you cover' : 'Your neighbourhood',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            draft.travelsToCustomers
                ? 'Choose the towns and neighbourhoods you can reach.'
                : 'Choose the area closest to your premises.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final town in region.towns)
                FilterChip(
                  label: Text(town),
                  selected: draft.towns.contains(town),
                  onSelected: (value) => controller.updateDraft(
                    (draft) => draft.copyWith(
                      towns: value
                          ? [...draft.towns, town]
                          : draft.towns.where((item) => item != town).toList(),
                    ),
                  ),
                ),
            ],
          ),
          if (showErrors && draft.towns.isEmpty) ...[
            const SizedBox(height: 10),
            const InlineError(message: 'Select at least one area.'),
          ],
        ],
        if (draft.travelsToCustomers && region != null) ...[
          const SizedBox(height: 24),
          Text(
            'Maximum travel distance',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            '${draft.travelRadiusKm.round()} km from your base',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Slider(
            value: draft.travelRadiusKm,
            min: 5,
            max: 60,
            divisions: 11,
            label: '${draft.travelRadiusKm.round()} km',
            onChanged: (value) => controller.updateDraft(
              (draft) => draft.copyWith(travelRadiusKm: value),
            ),
          ),
        ],
      ],
    );
  }
}

class AvailabilityStep extends ConsumerWidget {
  const AvailabilityStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingControllerProvider).draft;
    final controller = ref.read(onboardingControllerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'You can change this any time — it only sets what you are offered '
          'by default.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        ScheduleEditor(
          workingDays: draft.workingDays,
          startHour: draft.startHour,
          endHour: draft.endHour,
          onDaysChanged: (days) => controller.updateDraft(
            (draft) => draft.copyWith(workingDays: days),
          ),
          onHoursChanged: (start, end) => controller.updateDraft(
            (draft) => draft.copyWith(startHour: start, endHour: end),
          ),
        ),
        const SizedBox(height: 20),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: draft.sameDay,
          title: const Text(
            'Same-day jobs',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
          ),
          subtitle: const Text(
            'Receive jobs that need attention today.',
            style: TextStyle(fontSize: 12.5),
          ),
          onChanged: (value) =>
              controller.updateDraft((draft) => draft.copyWith(sameDay: value)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: draft.emergency,
          title: const Text(
            'Emergency call-outs',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
          ),
          subtitle: const Text(
            'Urgent jobs outside your normal hours, at your own rates.',
            style: TextStyle(fontSize: 12.5),
          ),
          onChanged: (value) => controller.updateDraft(
            (draft) => draft.copyWith(emergency: value),
          ),
        ),
      ],
    );
  }
}
