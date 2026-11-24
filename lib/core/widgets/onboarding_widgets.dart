import 'package:flutter/material.dart';
import 'package:grid_professionals/core/models/onboarding_models.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';
import 'package:grid_professionals/core/widgets/cards.dart';
import 'package:grid_professionals/core/widgets/forms.dart';
import 'package:grid_professionals/data/country/country_config.dart';

/// Stage-grouped progress bar for the onboarding wizard. One segment per
/// stage, filling as its steps close.
class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({super.key, required this.step});
  final OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    final totalSteps = OnboardingStep.values.length;
    final position = step.index + 1;
    return Semantics(
      label: 'Progress: ${step.stage.title}, step $position of $totalSteps',
      child: Row(
        children: [
          for (final stage in OnboardingStage.values) ...[
            Expanded(
              flex: stage.steps.length,
              child: _StageSegment(stage: stage, current: step),
            ),
            if (stage != OnboardingStage.values.last) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

class _StageSegment extends StatelessWidget {
  const _StageSegment({required this.stage, required this.current});
  final OnboardingStage stage;
  final OnboardingStep current;

  @override
  Widget build(BuildContext context) {
    final steps = stage.steps;
    final firstIndex = steps.first.index;
    final fraction = ((current.index - firstIndex + 1) / steps.length).clamp(
      0.0,
      1.0,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: fraction, end: fraction),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        builder: (context, value, _) => LinearProgressIndicator(
          value: value,
          minHeight: 4,
          color: AppColors.navy,
          backgroundColor: AppColors.line,
        ),
      ),
    );
  }
}

/// Quiet progress caption above a wizard step title.
class OnboardingStepEyebrow extends StatelessWidget {
  const OnboardingStepEyebrow({super.key, required this.step});
  final OnboardingStep step;

  @override
  Widget build(BuildContext context) => Text(
    '${step.stage.title.toUpperCase()}  ·  '
    'STEP ${step.index + 1} OF ${OnboardingStep.values.length}',
    style: AppText.overline,
  );
}

/// One service as a large selectable card on the services step.
class ServiceOptionCard extends StatelessWidget {
  const ServiceOptionCard({
    super.key,
    required this.service,
    required this.selected,
    required this.onTap,
  });

  final ServiceDefinition service;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kind =
        ServiceKindInfo.fromName(service.id) ??
        ServiceKindInfo.fromName(service.name) ??
        ServiceKind.cleaning;
    return Semantics(
      button: true,
      checked: selected,
      label: service.name,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ServiceHeroCard(
          service: kind,
          selected: selected,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ServiceBadge(service: kind, size: 46),
                  const Spacer(),
                  CheckMark(selected: selected),
                ],
              ),
              const SizedBox(height: 18),
              Text(service.name, style: AppText.title),
              if (service.summary != null) ...[
                const SizedBox(height: 4),
                Text(
                  service.summary!,
                  style: AppText.bodyMuted.copyWith(
                    color: kind.palette.ink.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Working-days and hours editor.
class ScheduleEditor extends StatelessWidget {
  const ScheduleEditor({
    super.key,
    required this.workingDays,
    required this.startHour,
    required this.endHour,
    required this.onDaysChanged,
    required this.onHoursChanged,
  });

  static const allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final List<String> workingDays;
  final int startHour;
  final int endHour;
  final ValueChanged<List<String>> onDaysChanged;
  final void Function(int startHour, int endHour) onHoursChanged;

  static String formatHour(int hour) {
    final display = hour % 12 == 0 ? 12 : hour % 12;
    return '$display:00 ${hour < 12 ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const FieldLabel(label: 'Working days'),
      const SizedBox(height: 10),
      Row(
        children: [
          for (final day in allDays) ...[
            Expanded(
              child: _DayToggle(
                day: day,
                selected: workingDays.contains(day),
                onChanged: (value) {
                  final updated = value
                      ? [...workingDays, day]
                      : workingDays.where((item) => item != day).toList();
                  onDaysChanged(
                    allDays.where((item) => updated.contains(item)).toList(),
                  );
                },
              ),
            ),
            if (day != allDays.last) const SizedBox(width: 6),
          ],
        ],
      ),
      const SizedBox(height: 24),
      const FieldLabel(label: 'Working hours'),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _HourButton(
              label: 'From',
              hour: startHour,
              onSelected: (value) =>
                  onHoursChanged(value, value < endHour ? endHour : value + 1),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _HourButton(
              label: 'To',
              hour: endHour,
              minHour: startHour + 1,
              onSelected: (value) => onHoursChanged(startHour, value),
            ),
          ),
        ],
      ),
    ],
  );
}

class _DayToggle extends StatelessWidget {
  const _DayToggle({
    required this.day,
    required this.selected,
    required this.onChanged,
  });
  final String day;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: day,
    excludeSemantics: true,
    child: InkWell(
      onTap: () => onChanged(!selected),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: selected ? AppColors.navy : AppColors.lineStrong,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            day,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.muted,
            ),
          ),
        ),
      ),
    ),
  );
}

class _HourButton extends StatelessWidget {
  const _HourButton({
    required this.label,
    required this.hour,
    required this.onSelected,
    this.minHour = 5,
  });
  final String label;
  final int hour;
  final int minHour;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$label: ${ScheduleEditor.formatHour(hour)}',
    excludeSemantics: true,
    child: InkWell(
      onTap: () async {
        final choice = await showOptionPicker<int>(
          context,
          title: label == 'From' ? 'Start time' : 'Finish time',
          options: [for (var h = minHour; h <= 22; h++) h],
          labelOf: ScheduleEditor.formatHour,
          selected: hour,
        );
        if (choice != null) onSelected(choice);
      },
      borderRadius: BorderRadius.circular(AppRadius.field),
      child: Container(
        height: AppSizes.controlHeight,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.field),
          border: Border.all(color: AppColors.lineStrong),
        ),
        child: Row(
          children: [
            Text(label, style: AppText.caption.copyWith(fontSize: 13)),
            const SizedBox(width: 8),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  ScheduleEditor.formatHour(hour),
                  style: AppText.subtitle.copyWith(
                    fontFeatures: AppText.tabular,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Mock upload tile with uploading, failed and done states.
class UploadTile extends StatelessWidget {
  const UploadTile({
    super.key,
    required this.item,
    this.onRetry,
    this.onRemove,
  });

  final UploadItem item;
  final VoidCallback? onRetry;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final failed = item.state == UploadState.failed;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: failed ? AppColors.dangerBg : AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: failed ? AppColors.dangerLine : AppColors.line,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          switch (item.state) {
            UploadState.done => const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
            ),
            UploadState.failed => const Icon(
              Icons.error_outline_rounded,
              color: AppColors.danger,
            ),
            UploadState.uploading => SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                value: item.progress == 0 ? null : item.progress,
                semanticsLabel: 'Uploading ${item.label}',
              ),
            ),
          },
          const SizedBox(height: 6),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          switch (item.state) {
            UploadState.failed => _TileAction(
              label: 'Retry',
              onTap: onRetry,
              color: AppColors.danger,
            ),
            UploadState.done => _TileAction(
              label: 'Remove',
              onTap: onRemove,
              color: AppColors.muted,
            ),
            UploadState.uploading => Text(
              'Uploading…',
              style: AppText.caption.copyWith(fontSize: 11.5),
            ),
          },
        ],
      ),
    );
  }
}

class _TileAction extends StatelessWidget {
  const _TileAction({
    required this.label,
    required this.onTap,
    required this.color,
  });
  final String label;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppRadius.sm),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    ),
  );
}

/// The tile that starts a new mock upload or capture.
class AddUploadTile extends StatelessWidget {
  const AddUploadTile({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.add_a_photo_outlined,
  });

  final String label;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.navySoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: const Color(0xFFC9D5E6)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.navy),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Row on the application hub showing a section's status.
class SectionStatusTile extends StatelessWidget {
  const SectionStatusTile({
    super.key,
    required this.title,
    required this.status,
    required this.onTap,
    this.summary,
  });

  final String title;
  final SectionStatus status;
  final VoidCallback onTap;
  final String? summary;

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (status) {
      SectionStatus.complete => 'Complete',
      SectionStatus.inProgress => 'In progress',
      SectionStatus.notStarted => 'Not started',
    };
    return Semantics(
      button: true,
      label: '$title. $statusLabel.',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
          child: Row(
            children: [
              _StatusMark(status: status),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.subtitle),
                    // Only a real summary earns a second line.
                    if (summary != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        summary!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusMark extends StatelessWidget {
  const _StatusMark({required this.status});
  final SectionStatus status;

  @override
  Widget build(BuildContext context) => switch (status) {
    SectionStatus.complete => Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: AppColors.success,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
    ),
    SectionStatus.inProgress => Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.warning, width: 2),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.warning,
            shape: BoxShape.circle,
          ),
        ),
      ),
    ),
    SectionStatus.notStarted => Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.lineStrong, width: 1.6),
      ),
    ),
  };
}
