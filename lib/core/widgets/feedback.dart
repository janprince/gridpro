import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';
import 'package:grid_professionals/core/widgets/layout.dart';

/// Semantic status panel. Icon plus text carry the meaning, colour supports
/// it — status is never communicated by colour alone.
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.kind,
    required this.title,
    this.message,
    this.action,
  });

  final StatusKind kind;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
    decoration: BoxDecoration(
      color: kind.background,
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(kind.icon, color: kind.foreground, size: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: kind == StatusKind.neutral
                      ? AppColors.ink
                      : kind.foreground,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                  height: 1.35,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 3),
                Text(
                  message!,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
              ],
              if (action != null) ...[const SizedBox(height: 8), action!],
            ],
          ),
        ),
      ],
    ),
  );
}

/// Segmented progress through a job's stages, with the current step named.
class StageProgress extends StatelessWidget {
  const StageProgress({
    super.key,
    required this.total,
    required this.current,
    required this.label,
  });

  /// Number of steps.
  final int total;

  /// Zero-based index of the step in progress; [total] means finished.
  final int current;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Step ${math.min(current + 1, total)} of $total: $label',
    excludeSemantics: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.subtitle,
              ),
            ),
            Text(
              'Step ${math.min(current + 1, total)} of $total',
              style: AppText.caption,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < total; i++) ...[
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  height: 6,
                  decoration: BoxDecoration(
                    color: i <= current ? AppColors.navy : AppColors.line,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              if (i != total - 1) const SizedBox(width: 4),
            ],
          ],
        ),
      ],
    ),
  );
}

class TimelineStep extends StatelessWidget {
  const TimelineStep({
    super.key,
    required this.label,
    required this.complete,
    this.current = false,
    this.last = false,
    this.caption,
  });
  final String label;
  final bool complete;
  final bool current;
  final bool last;
  final String? caption;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: complete ? AppColors.navy : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: complete || current
                      ? AppColors.navy
                      : AppColors.lineStrong,
                  width: current ? 6 : 1.6,
                ),
              ),
              child: complete
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            if (!last)
              Expanded(
                child: Container(
                  width: 2,
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  color: complete ? AppColors.navy : AppColors.line,
                ),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 1, bottom: last ? 0 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                    color: current || complete
                        ? AppColors.ink
                        : AppColors.muted,
                  ),
                ),
                if (caption != null) ...[
                  const SizedBox(height: 2),
                  Text(caption!, style: AppText.caption),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// A small composed illustration — two stacked job cards — above a title,
/// a message and an optional checklist. Used for every empty list.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.points = const [],
    this.service = ServiceKind.cleaning,
    this.action,
    this.onAction,
  });
  final String title;
  final String message;

  /// Short reassurances shown in a grey box, each with a check.
  final List<String> points;
  final ServiceKind service;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      children: [
        _StackedCards(service: service),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppText.heading.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 6),
        Text(message, textAlign: TextAlign.center, style: AppText.bodyMuted),
        if (points.isNotEmpty) ...[
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              children: [
                for (final point in points)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 21,
                          color: AppColors.navy,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            point,
                            style: AppText.body.copyWith(
                              fontSize: 14.5,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (action != null) ...[
          const SizedBox(height: 18),
          SecondaryButton(label: action!, onPressed: onAction),
        ],
      ],
    ),
  );
}

class _StackedCards extends StatelessWidget {
  const _StackedCards({required this.service});
  final ServiceKind service;

  @override
  Widget build(BuildContext context) {
    final other = service == ServiceKind.cleaning
        ? ServiceKind.laundry
        : ServiceKind.cleaning;
    Widget card(ServiceKind kind, {required bool front}) => Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: front ? Colors.white : kind.palette.tint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: front ? AppColors.lineStrong : kind.palette.arc,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: kind.palette.badge,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(kind.icon, size: 15, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 7,
                  width: 64,
                  decoration: BoxDecoration(
                    color: front ? AppColors.lineStrong : kind.palette.arc,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 7,
                  width: 40,
                  decoration: BoxDecoration(
                    color: front ? AppColors.line : kind.palette.arc,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return ExcludeSemantics(
      child: SizedBox(
        height: 96,
        width: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 6,
              left: 14,
              child: Transform.rotate(
                angle: -0.09,
                child: card(other, front: false),
              ),
            ),
            Positioned(
              bottom: 6,
              right: 14,
              child: Transform.rotate(
                angle: 0.05,
                child: card(service, front: true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Something went wrong and the user can try again.
class RetryState extends StatelessWidget {
  const RetryState({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
    this.retryLabel = 'Try again',
  });

  final String title;
  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      children: [
        const Icon(Icons.wifi_off_rounded, size: 30, color: AppColors.faint),
        const SizedBox(height: 10),
        Text(title, style: AppText.subtitle, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(message, textAlign: TextAlign.center, style: AppText.caption),
        const SizedBox(height: 14),
        SecondaryButton(label: retryLabel, onPressed: onRetry),
      ],
    ),
  );
}

/// Gentle pulsing placeholder used while content loads.
class LoadingSkeleton extends StatefulWidget {
  const LoadingSkeleton({
    super.key,
    this.height = 16,
    this.width = double.infinity,
    this.radius = AppRadius.sm,
  });
  final double height;
  final double width;
  final double radius;

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.45,
    upperBound: 1,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading',
    child: FadeTransition(
      opacity: _controller,
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: AppColors.chip,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    ),
  );
}

/// Bottom sheet that asks before an action runs. An optional [header] — a
/// service card, say — shows what the action applies to.
Future<bool> showConfirmationSheet(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  Widget? header,
}) async {
  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (context) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              4,
              AppSpacing.gutter,
              16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (header != null) ...[header, const SizedBox(height: 20)],
                Text(title, style: AppText.title),
                const SizedBox(height: 8),
                Text(message, style: AppText.bodyMuted),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: confirmLabel,
                  onPressed: () => Navigator.pop(context, true),
                ),
                const SizedBox(height: 10),
                SecondaryButton(
                  label: cancelLabel,
                  onPressed: () => Navigator.pop(context, false),
                ),
              ],
            ),
          ),
        ),
      ) ??
      false;
}
