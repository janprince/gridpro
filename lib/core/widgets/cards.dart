import 'package:flutter/material.dart';
import 'package:grid_professionals/core/models/models.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';
import 'package:grid_professionals/core/utils/formatters.dart';
import 'package:grid_professionals/core/widgets/feedback.dart';
import 'package:grid_professionals/core/widgets/layout.dart';
import 'package:grid_professionals/core/widgets/onboarding_widgets.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.dark = false,
    this.caption,
  });
  final String label;
  final String value;
  final IconData icon;
  final bool dark;
  final String? caption;
  @override
  Widget build(BuildContext context) => AppCard(
    color: dark ? AppColors.forest : Colors.white,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: dark ? AppColors.mint : AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                ),
              ),
            ),
            Icon(icon, size: 18, color: dark ? Colors.white : AppColors.forest),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(
            color: dark ? Colors.white : AppColors.ink,
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 4),
          Text(
            caption!,
            style: TextStyle(
              color: dark ? AppColors.mint : AppColors.muted,
              fontSize: 12,
            ),
          ),
        ],
      ],
    ),
  );
}

class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.job,
    required this.onTap,
    this.offer = false,
  });
  final Job job;
  final VoidCallback onTap;
  final bool offer;
  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ServiceImage.forCategory(job.category),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.summary,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    job.area,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            StatusChip(status: job.status),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Icon(Icons.schedule, size: 16, color: AppColors.muted),
            const SizedBox(width: 6),
            Text(
              '${formatDate(job.scheduledAt)} • ${formatTime(job.scheduledAt)}',
            ),
            const Spacer(),
            Text(
              formatCurrency(job.calloutFee),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        if (offer) ...[
          const Divider(height: 28),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 18),
              const SizedBox(width: 6),
              Text('${job.distanceKm} km away'),
              const Spacer(),
              const Icon(Icons.arrow_forward, size: 18),
            ],
          ),
        ],
      ],
    ),
  );
}

class AvailabilityToggle extends StatelessWidget {
  const AvailabilityToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final AvailabilityStatus value;
  final ValueChanged<AvailabilityStatus> onChanged;
  @override
  Widget build(BuildContext context) => MenuAnchor(
    builder: (context, controller, child) => InkWell(
      onTap: () => controller.isOpen ? controller.close() : controller.open(),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: value == AvailabilityStatus.available
                    ? AppColors.success
                    : value == AvailabilityStatus.busy
                    ? AppColors.warning
                    : AppColors.muted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              value.name[0].toUpperCase() + value.name.substring(1),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 18),
          ],
        ),
      ),
    ),
    menuChildren: [
      for (final item in AvailabilityStatus.values)
        MenuItemButton(
          onPressed: () => onChanged(item),
          child: Text(item.name[0].toUpperCase() + item.name.substring(1)),
        ),
    ],
  );
}

/// Legacy mock upload tile still used by job, quote and support screens.
class PhotoUploadTile extends StatelessWidget {
  const PhotoUploadTile({
    super.key,
    this.label = 'Add photo',
    this.compact = false,
  });
  final String label;
  final bool compact;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mock upload added. No file leaves this device.'),
      ),
    ),
    borderRadius: BorderRadius.circular(AppRadius.md),
    child: Container(
      height: compact ? 86 : 120,
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_a_photo_outlined, color: AppColors.forest),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    ),
  );
}

class SupportActionCard extends StatelessWidget {
  const SupportActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;
  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: danger ? AppColors.dangerBg : AppColors.mint,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            icon,
            color: danger ? AppColors.danger : AppColors.forest,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right),
      ],
    ),
  );
}
