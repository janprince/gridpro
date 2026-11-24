import 'package:flutter/material.dart';
import 'package:grid_professionals/core/models/models.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';
import 'package:grid_professionals/core/utils/formatters.dart';
import 'package:grid_professionals/core/widgets/patterns.dart';

/// White card with a hairline border — the default container.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.surface,
    this.borderColor,
    this.radius = AppRadius.lg,
    this.onTap,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color color;

  /// Outlines the card instead of lifting it. For cards on a tinted or grey
  /// ground, where a shadow would look dirty.
  final Color? borderColor;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final lifted = borderColor == null && color == AppColors.surface;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: lifted ? AppShadow.card : null,
      ),
      child: Material(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: borderColor == null
              ? BorderSide.none
              : BorderSide(color: borderColor!),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// The service's icon on its solid colour. Stands in for a logo in lists.
class ServiceBadge extends StatelessWidget {
  const ServiceBadge({super.key, required this.service, this.size = 44});
  final ServiceKind service;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: service.label,
    excludeSemantics: true,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: service.palette.badge,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(service.icon, color: Colors.white, size: size * 0.5),
    ),
  );
}

/// A tinted card for one service, with the corner arcs. Used wherever a job
/// or service is the subject of the screen.
class ServiceHeroCard extends StatelessWidget {
  const ServiceHeroCard({
    super.key,
    required this.service,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.selected = false,
  });
  final ServiceKind service;
  final Widget child;
  final EdgeInsets padding;

  /// Draws a navy ring, for when the card is a choice.
  final bool selected;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 160),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: service.palette.tint,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      border: Border.all(
        color: selected ? AppColors.navy : Colors.transparent,
        width: 2,
      ),
    ),
    child: Stack(
      fit: StackFit.passthrough,
      children: [
        CornerArcs(color: service.palette.arc),
        Padding(padding: padding, child: child),
      ],
    ),
  );
}

/// Navy panel with the grid texture: balances and other headline numbers.
class NavyPanel extends StatelessWidget {
  const NavyPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = AppRadius.xl,
  });
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.navyDeep, AppColors.navy, Color(0xFF1D3B68)],
      ),
    ),
    child: Stack(
      fit: StackFit.passthrough,
      children: [
        const GridTexture(),
        Padding(padding: padding, child: child),
      ],
    ),
  );
}

/// Compact white button for use on navy surfaces.
class OnNavyButton extends StatelessWidget {
  const OnNavyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
  });
  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(AppRadius.pill),
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.button.copyWith(
                  color: AppColors.navy,
                  fontSize: 13.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 17, color: AppColors.navy),
          ],
        ),
      ),
    ),
  );
}

/// Outlined status label: a light fill, a coloured edge and coloured text.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.kind});

  factory StatusPill.forJob(Job job) =>
      StatusPill(label: job.stageLabel, kind: job.stage.statusKind);

  final String label;
  final StatusKind kind;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: kind.background,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border: Border.all(color: kind.border),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: kind.foreground,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
    ),
  );
}

extension JobStageStatus on JobStage {
  StatusKind get statusKind => switch (this) {
    JobStage.offer => StatusKind.actionRequired,
    JobStage.accepted || JobStage.completed => StatusKind.neutral,
    JobStage.paid => StatusKind.success,
    JobStage.declined || JobStage.cancelled => StatusKind.danger,
    _ => StatusKind.pending,
  };
}

/// Grey date marker that heads each day in a list.
class DateChip extends StatelessWidget {
  const DateChip(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
        ),
      ),
    ),
  );
}

/// One job in a list: time and status on top, service, title, customer and
/// amount beneath.
class JobTile extends StatelessWidget {
  const JobTile({
    super.key,
    required this.job,
    required this.onTap,
    this.showDay = false,
    this.footer,
  });
  final Job job;
  final VoidCallback onTap;

  /// Prefix the time with "Today" / "Tomorrow" when the list is not grouped.
  final bool showDay;

  /// Optional content under a divider, e.g. the next action.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final subtitle = job.stage == JobStage.offer
        ? job.areaAndDistance
        : '${job.customerName} · ${job.area}';
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        showDay
                            ? formatWhen(job.scheduledAt)
                            : formatTime(job.scheduledAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: StatusPill.forJob(job),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ServiceBadge(service: job.service, size: 42),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.subtitle.copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.caption.copyWith(fontSize: 13.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Amount(job.price),
                  ],
                ),
              ],
            ),
          ),
          if (footer != null) ...[
            const Divider(),
            Padding(padding: const EdgeInsets.all(12), child: footer),
          ],
        ],
      ),
    );
  }
}

/// A money value that scales down rather than clipping when space is short.
class Amount extends StatelessWidget {
  const Amount(this.value, {super.key, this.style = AppText.amount});
  final num value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxWidth: MediaQuery.textScalerOf(context).scale(112),
    ),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Text(formatCurrency(value), style: style),
    ),
  );
}

/// Soft grey panel of label/value rows separated by hairlines.
class DetailGroup extends StatelessWidget {
  const DetailGroup({super.key, required this.rows});
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surfaceSubtle,
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    child: Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          rows[i],
          if (i != rows.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(),
            ),
        ],
      ],
    ),
  );
}

class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.stacked = false,
    this.emphasis = false,
    this.valueColor,
    this.trailing,
  });
  final String label;
  final String value;

  /// Puts the value under the label, for addresses and notes.
  final bool stacked;

  /// Bolder, larger value, e.g. a total.
  final bool emphasis;
  final Color? valueColor;

  /// Optional control at the end of a stacked row, e.g. a call button.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final valueStyle = TextStyle(
      fontSize: emphasis ? 16 : 15,
      fontWeight: emphasis ? FontWeight.w800 : FontWeight.w500,
      color: valueColor ?? AppColors.ink,
      height: 1.4,
      fontFeatures: AppText.tabular,
    );
    const labelStyle = TextStyle(
      fontSize: 14,
      color: AppColors.muted,
      height: 1.4,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: stacked
          ? Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: labelStyle),
                      const SizedBox(height: 3),
                      Text(value, style: valueStyle),
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 12), trailing!],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: labelStyle),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: valueStyle,
                  ),
                ),
              ],
            ),
    );
  }
}

/// Small round icon button used inside rows, e.g. call or directions.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: AppColors.navySoft,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox.square(
          dimension: 40,
          child: Icon(icon, size: 19, color: AppColors.navy),
        ),
      ),
    ),
  );
}

/// A settings-style list: rows with an icon tile, a label and a chevron.
class MenuGroup extends StatelessWidget {
  const MenuGroup({super.key, required this.children});
  final List<Widget> children;

  /// Rows sit straight on the page with a hairline between them; no box.
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < children.length; i++) ...[
        children[i],
        if (i != children.length - 1) const Divider(),
      ],
    ],
  );
}

/// Bordered card holding rows separated by full-width hairlines.
class MenuGroupShell extends StatelessWidget {
  const MenuGroupShell({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1) const Divider(),
        ],
      ],
    ),
  );
}

class MenuRow extends StatelessWidget {
  const MenuRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    this.danger = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Current setting shown before the chevron, e.g. "MTN MoMo".
  final String? value;
  final bool danger;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(2, 17, 0, 17),
      child: Row(
        children: [
          Icon(
            icon,
            size: 25,
            color: danger ? AppColors.danger : AppColors.ink,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body.copyWith(
                fontSize: 16,
                color: danger ? AppColors.danger : AppColors.ink,
              ),
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: 8),
            // Capped rather than flexible, so the value hugs the chevron.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(
                value!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: AppText.caption.copyWith(fontSize: 13.5),
              ),
            ),
          ],
          if (!danger) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.faint,
              size: 22,
            ),
          ],
        ],
      ),
    ),
  );
}

/// Soft grey tile with a small label and an amount.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
    decoration: BoxDecoration(
      color: AppColors.surfaceSubtle,
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.caption,
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: AppText.amount.copyWith(fontSize: 18)),
        ),
      ],
    ),
  );
}

/// "Online" switch shown on the home screen. Offline providers get no offers.
class OnlineToggle extends StatelessWidget {
  const OnlineToggle({super.key, required this.value, required this.onChanged});
  final bool value;

  /// Null while a change is on its way to GRID; the toggle then ignores taps.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final online = value;
    return Semantics(
      toggled: online,
      label: online ? 'Online, receiving requests' : 'Offline',
      excludeSemantics: true,
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!online),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
          decoration: BoxDecoration(
            color: online ? AppColors.successBg : AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: online ? AppColors.successLine : AppColors.line,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                online ? 'Online' : 'Offline',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: online ? AppColors.success : AppColors.muted,
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 34,
                height: 20,
                padding: const EdgeInsets.all(2),
                alignment: online
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: online ? AppColors.success : AppColors.lineStrong,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Initials in a circle — the provider's avatar until photos exist.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.initials,
    this.size = 44,
    this.onNavy = false,
  });
  final String initials;
  final double size;
  final bool onNavy;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: onNavy ? Colors.white : AppColors.navySoft,
      shape: BoxShape.circle,
    ),
    child: Text(
      initials,
      style: TextStyle(
        fontSize: size * 0.36,
        fontWeight: FontWeight.w800,
        color: AppColors.navy,
        letterSpacing: 0.3,
      ),
    ),
  );
}
