import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grid_professionals/core/models/models.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';
import 'package:grid_professionals/core/utils/formatters.dart';
import 'package:grid_professionals/core/widgets/app_widgets.dart';
import 'package:grid_professionals/data/mock_data.dart';
import 'package:grid_professionals/state/app_state.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref
        .watch(appControllerProvider)
        .jobs
        .where(
          (job) =>
              job.status != JobStatus.paid && job.status != JobStatus.cancelled,
        )
        .toList();
    return AppPage(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Schedule',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            IconButton(
              onPressed: () => context.push('/availability'),
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SegmentedButton(
          segments: const [
            ButtonSegment(value: 0, label: Text('Today')),
            ButtonSegment(value: 1, label: Text('Week')),
          ],
          selected: const {0},
          onSelectionChanged: (_) {},
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 70,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) => Container(
              width: 52,
              decoration: BoxDecoration(
                color: index == 0 ? AppColors.forest : Colors.white,
                border: Border.all(
                  color: index == 0 ? AppColors.forest : AppColors.line,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ['TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN', 'MON'][index],
                    style: TextStyle(
                      color: index == 0 ? AppColors.mint : AppColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${14 + index}',
                    style: TextStyle(
                      color: index == 0 ? Colors.white : AppColors.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SectionHeader('Today’s route'),
        for (final job in jobs.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              onTap: () => context.push('/job/${job.id}'),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 70,
                    child: Text(
                      formatTime(job.scheduledAt),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Container(
                    width: 3,
                    height: 54,
                    color: job.urgency == 'Urgent'
                        ? AppColors.danger
                        : AppColors.teal,
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
                          job.area,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 5),
                        StatusChip(status: job.status),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SectionHeader('Availability'),
        AppCard(
          onTap: () => context.push('/availability'),
          child: const Row(
            children: [
              Icon(Icons.event_available, color: AppColors.forest, size: 30),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mon–Sat • 7:00 AM–6:00 PM',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '5 areas • 25 km maximum travel',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => context.push('/availability'),
          icon: const Icon(Icons.block),
          label: const Text('Mark unavailable'),
        ),
      ],
    );
  }
}

class AvailabilitySettingsScreen extends ConsumerStatefulWidget {
  const AvailabilitySettingsScreen({super.key});
  @override
  ConsumerState<AvailabilitySettingsScreen> createState() =>
      _AvailabilitySettingsScreenState();
}

class _AvailabilitySettingsScreenState
    extends ConsumerState<AvailabilitySettingsScreen> {
  final _days = <String>{'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'};
  double _distance = 25;
  bool _emergency = true;
  bool _sameDay = true;
  bool _vacation = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Availability')),
    body: AppPage(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value:
              ref.watch(appControllerProvider).availability.status ==
              AvailabilityStatus.available,
          onChanged: (value) => ref
              .read(appControllerProvider.notifier)
              .setAvailability(
                value
                    ? AvailabilityStatus.available
                    : AvailabilityStatus.offline,
              ),
          title: const Text(
            'Available now',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: const Text('Receive new GRID job offers'),
        ),
        const SectionHeader('Working days'),
        Wrap(
          spacing: 8,
          children: [
            for (final day in const [
              'Mon',
              'Tue',
              'Wed',
              'Thu',
              'Fri',
              'Sat',
              'Sun',
            ])
              FilterChip(
                label: Text(day),
                selected: _days.contains(day),
                onSelected: (value) =>
                    setState(() => value ? _days.add(day) : _days.remove(day)),
              ),
          ],
        ),
        const SectionHeader('Working hours'),
        const Row(
          children: [
            Expanded(
              child: TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Start',
                  hintText: '7:00 AM',
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Finish',
                  hintText: '6:00 PM',
                ),
              ),
            ),
          ],
        ),
        const SectionHeader('Service areas'),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final item in MockData.professional.serviceAreas)
              Chip(label: Text(item)),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Maximum travel distance: ${_distance.round()} km',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        Slider(
          value: _distance,
          min: 5,
          max: 60,
          divisions: 11,
          onChanged: (value) => setState(() => _distance = value),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _emergency,
          onChanged: (value) => setState(() => _emergency = value),
          title: const Text('Emergency jobs'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _sameDay,
          onChanged: (value) => setState(() => _sameDay = value),
          title: const Text('Same-day jobs'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _vacation,
          onChanged: (value) => setState(() => _vacation = value),
          title: const Text('Vacation / offline mode'),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () => context.pop(),
          child: const Text('Save availability'),
        ),
      ],
    ),
  );
}
