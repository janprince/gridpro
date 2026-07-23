import 'package:flutter/material.dart';
import 'package:grid_professionals/core/models/models.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';
import 'package:grid_professionals/core/widgets/layout.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});
  final JobStatus status;

  @override
  Widget build(BuildContext context) {
    final kind = switch (status) {
      JobStatus.newOffer || JobStatus.offerExpired => StatusKind.actionRequired,
      JobStatus.declined ||
      JobStatus.cancelled ||
      JobStatus.disputed => StatusKind.danger,
      JobStatus.paid ||
      JobStatus.quoteApproved ||
      JobStatus.workCompleted => StatusKind.success,
      JobStatus.awaitingCustomerApproval ||
      JobStatus.payoutPending ||
      JobStatus.paymentProcessing => StatusKind.pending,
      _ => StatusKind.neutral,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kind.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: kind.foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

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
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: kind.background,
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(kind.icon, color: kind.foreground, size: AppSizes.iconMd),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: kind.foreground,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 3),
                Text(
                  message!,
                  style: TextStyle(
                    color: kind.foreground,
                    fontSize: 13,
                    height: 1.4,
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
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: complete || current ? AppColors.forest : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: complete || current ? AppColors.forest : AppColors.line,
                width: 2,
              ),
            ),
            child: complete
                ? const Icon(Icons.check, size: 15, color: Colors.white)
                : current
                ? const Center(
                    child: CircleAvatar(
                      radius: 3,
                      backgroundColor: Colors.white,
                    ),
                  )
                : null,
          ),
          if (!last)
            Container(
              width: 2,
              height: caption == null ? 34 : 46,
              color: complete ? AppColors.forest : AppColors.line,
            ),
        ],
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: current ? FontWeight.w800 : FontWeight.w600,
                  color: current || complete ? AppColors.ink : AppColors.muted,
                ),
              ),
              if (caption != null)
                Text(caption!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    ],
  );
}

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(28),
    child: Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: AppColors.mint,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.forest, size: 30),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted),
        ),
        if (action != null) ...[
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onAction, child: Text(action!)),
        ],
      ],
    ),
  );
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
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        const Icon(Icons.wifi_off, size: 34, color: AppColors.muted),
        const SizedBox(height: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 14),
        OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
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
          color: AppColors.neutralBg,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    ),
  );
}

Future<bool> showConfirmationSheet(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
}) async {
  return await showModalBottomSheet<bool>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 10),
                Text(message, style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(confirmLabel),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Center(child: Text('Cancel')),
                ),
              ],
            ),
          ),
        ),
      ) ??
      false;
}
