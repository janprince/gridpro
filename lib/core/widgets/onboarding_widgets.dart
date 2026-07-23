import 'package:flutter/material.dart';
import 'package:grid_professionals/core/models/onboarding_models.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';
import 'package:grid_professionals/data/country/country_config.dart';

/// Compact stage-grouped progress indicator for the onboarding wizard:
/// one bar segment per stage, with a "stage · step x of y" caption.
class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({super.key, required this.step});
  final OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    final totalSteps = OnboardingStep.values.length;
    final position = step.index + 1;
    return Semantics(
      label: 'Progress: ${step.stage.title}, step $position of $totalSteps',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (final stage in OnboardingStage.values) ...[
                Expanded(
                  flex: stage.steps.length,
                  child: _StageSegment(stage: stage, current: step),
                ),
                if (stage != OnboardingStage.values.last)
                  const SizedBox(width: 4),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${step.stage.title} · Step $position of $totalSteps',
            style: Theme.of(context).textTheme.bodySmall,
          ),
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
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(value: fraction, minHeight: 5),
    );
  }
}

/// Service photo with a tonal initial-letter fallback for categories that do
/// not have photography yet.
class ServiceImage extends StatelessWidget {
  const ServiceImage({
    super.key,
    this.imageAsset,
    required this.name,
    this.size = 48,
    this.radius = AppRadius.md,
  });

  /// Thumbnail for legacy job-category names used across job screens.
  factory ServiceImage.forCategory(
    String category, {
    double size = 44,
    double radius = AppRadius.md,
  }) => ServiceImage(
    imageAsset: assetForCategory(category),
    name: category,
    size: size,
    radius: radius,
  );

  /// Photo asset for a job-category name, or null when the category has no
  /// photography yet.
  static String? assetForCategory(String category) {
    final normalized = category.toLowerCase();
    for (final entry in _categoryAssets.entries) {
      if (normalized.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static const _categoryAssets = {
    'electric': 'assets/images/services/electrical.jpg',
    'plumb': 'assets/images/services/plumbing.jpg',
    'clean': 'assets/images/services/cleaning.jpg',
    'ac ': 'assets/images/services/ac_repair.jpg',
    'ac repair': 'assets/images/services/ac_repair.jpg',
    'garden': 'assets/images/services/gardening.jpg',
    'carpent': 'assets/images/services/carpentry.jpg',
  };

  final String? imageAsset;
  final String name;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: imageAsset != null
        ? Image.asset(
            imageAsset!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            semanticLabel: name,
          )
        : Container(
            width: size,
            height: size,
            color: AppColors.mint,
            alignment: Alignment.center,
            child: Text(
              name.isEmpty ? '?' : name[0].toUpperCase(),
              style: TextStyle(
                fontSize: size * 0.4,
                fontWeight: FontWeight.w800,
                color: AppColors.forest,
              ),
            ),
          ),
  );
}

/// Image-led selection card for choosing a primary service.
class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.service,
    required this.selected,
    required this.onTap,
  });

  final ServiceDefinition service;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: service.name,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? AppColors.forest : AppColors.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  service.imageAsset != null
                      ? Image.asset(
                          service.imageAsset!,
                          fit: BoxFit.cover,
                          excludeFromSemantics: true,
                        )
                      : Container(
                          color: AppColors.surfaceSubtle,
                          alignment: Alignment.center,
                          child: Text(
                            service.name[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: AppColors.forest,
                            ),
                          ),
                        ),
                  if (selected)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.forest,
                        child: Icon(Icons.check, size: 15, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Text(
                service.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
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
      Text('Working days', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final day in allDays)
            FilterChip(
              label: Text(day),
              selected: workingDays.contains(day),
              onSelected: (value) {
                final updated = value
                    ? [...workingDays, day]
                    : workingDays.where((item) => item != day).toList();
                onDaysChanged(
                  allDays.where((item) => updated.contains(item)).toList(),
                );
              },
            ),
        ],
      ),
      const SizedBox(height: 20),
      Text('Working hours', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
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
          const SizedBox(width: 12),
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
    child: InkWell(
      onTap: () async {
        final hours = [for (var h = minHour; h <= 22; h++) h];
        final choice = await showModalBottomSheet<int>(
          context: context,
          showDragHandle: true,
          builder: (context) => SafeArea(
            child: SizedBox(
              height: 320,
              child: ListView(
                children: [
                  for (final h in hours)
                    ListTile(
                      title: Text(ScheduleEditor.formatHour(h)),
                      trailing: h == hour
                          ? const Icon(Icons.check, color: AppColors.forest)
                          : null,
                      onTap: () => Navigator.pop(context, h),
                    ),
                ],
              ),
            ),
          ),
        );
        if (choice != null) onSelected(choice);
      },
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        height: AppSizes.controlHeight,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  ScheduleEditor.formatHour(hour),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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
    final (background, border) = switch (item.state) {
      UploadState.failed => (AppColors.dangerBg, AppColors.danger),
      UploadState.done => (AppColors.surfaceSubtle, AppColors.line),
      UploadState.uploading => (AppColors.surfaceSubtle, AppColors.line),
    };
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          switch (item.state) {
            UploadState.done => const Icon(
              Icons.check_circle,
              color: AppColors.success,
            ),
            UploadState.failed => const Icon(
              Icons.error_outline,
              color: AppColors.danger,
            ),
            UploadState.uploading => SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
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
              style: Theme.of(context).textTheme.bodySmall,
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
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.forest),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Row on the application hub and review screens showing a section's status.
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
    final (icon, color, statusLabel) = switch (status) {
      SectionStatus.complete => (
        Icons.check_circle,
        AppColors.success,
        'Complete',
      ),
      SectionStatus.inProgress => (
        Icons.timelapse,
        AppColors.warningText,
        'In progress',
      ),
      SectionStatus.notStarted => (
        Icons.circle_outlined,
        AppColors.muted,
        'Not started',
      ),
    };
    return Semantics(
      button: true,
      label: '$title. $statusLabel.',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                    Text(
                      summary ?? statusLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
