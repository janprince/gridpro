import 'package:flutter/material.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';

/// A plain scrolling page with the standard gutter.
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.gutter,
      16,
      AppSpacing.gutter,
      32,
    ),
  });
  final List<Widget> children;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) =>
      ListView(padding: padding, children: children);
}

/// Circular grey button used for back and close in page headers.
class NavChip extends StatelessWidget {
  const NavChip({
    super.key,
    required this.onPressed,
    this.icon = Icons.arrow_back_rounded,
    this.tooltip = 'Back',
    this.color = AppColors.chip,
    this.iconColor = AppColors.ink,
  });
  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Semantics(
      button: true,
      label: tooltip,
      excludeSemantics: true,
      child: Material(
        color: color,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox.square(
            dimension: AppSizes.navChip,
            child: Icon(icon, size: AppSizes.iconSm, color: iconColor),
          ),
        ),
      ),
    ),
  );
}

/// The title bar used across the app: a bold left-aligned title, an optional
/// back chip before it and an optional close chip after it, over a hairline.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    this.title,
    this.onBack,
    this.onClose,
    this.trailing,
    this.divider = true,
  });

  final String? title;
  final VoidCallback? onBack;
  final VoidCallback? onClose;
  final Widget? trailing;
  final bool divider;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 60),
    padding: EdgeInsets.fromLTRB(
      onBack != null ? 12 : AppSpacing.gutter,
      8,
      onClose != null || trailing != null ? 12 : AppSpacing.gutter,
      8,
    ),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: divider
          ? const Border(bottom: BorderSide(color: AppColors.line))
          : null,
    ),
    child: Row(
      children: [
        if (onBack != null) ...[
          NavChip(onPressed: onBack!),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: title == null
              ? const SizedBox.shrink()
              : Text(
                  title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.heading,
                ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        if (onClose != null) ...[
          const SizedBox(width: 8),
          NavChip(
            onPressed: onClose!,
            icon: Icons.close_rounded,
            tooltip: 'Close',
          ),
        ],
      ],
    ),
  );
}

/// A large title and an optional line of supporting copy.
///
/// [display] uses the larger heading for welcome and milestone screens.
class ScreenIntro extends StatelessWidget {
  const ScreenIntro({
    super.key,
    required this.title,
    this.subtitle,
    this.display = false,
    this.center = false,
  });
  final String title;
  final String? subtitle;
  final bool display;
  final bool center;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: center
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start,
    children: [
      Text(
        title,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: display ? AppText.display : AppText.headline,
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 10),
        Text(
          subtitle!,
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: AppText.bodyMuted.copyWith(fontSize: 15.5),
        ),
      ],
    ],
  );
}

/// A single-purpose screen: header, top-aligned scrolling content, and
/// actions pinned to the bottom edge.
class FocusPage extends StatelessWidget {
  const FocusPage({
    super.key,
    required this.children,
    this.title,
    this.onBack,
    this.onClose,
    this.trailing,
    this.header,
    this.actions = const [],
    this.footnote,
    this.background = AppColors.surface,
    this.headerDivider = true,
    this.padding,
  });

  final List<Widget> children;
  final String? title;
  final VoidCallback? onBack;
  final VoidCallback? onClose;

  /// Optional control at the end of the header, e.g. "Save & exit".
  final Widget? trailing;

  /// Optional full-width band below the header, e.g. a progress bar.
  final Widget? header;

  /// Stacked full-width buttons pinned above the bottom edge.
  final List<Widget> actions;

  /// Small centred line above the actions, e.g. a terms note.
  final Widget? footnote;
  final Color background;
  final bool headerDivider;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final hasHeader =
        title != null || onBack != null || onClose != null || trailing != null;
    final hasActions = footnote != null || actions.isNotEmpty;
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasHeader)
              AppHeader(
                title: title,
                onBack: onBack,
                onClose: onClose,
                trailing: trailing,
                divider: headerDivider,
              ),
            ?header,
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding:
                        padding ??
                        EdgeInsets.fromLTRB(
                          AppSpacing.gutter,
                          hasHeader ? 24 : 16,
                          AppSpacing.gutter,
                          24,
                        ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children,
                    ),
                  ),
                  if (hasActions) ScrollFade(color: background),
                ],
              ),
            ),
            if (hasActions)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  4,
                  AppSpacing.gutter,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (footnote != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: footnote!,
                      ),
                    for (final action in actions) ...[
                      action,
                      if (action != actions.last) const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Soft fade at the foot of a scrolling area, so content passing under pinned
/// actions dissolves instead of being sliced off mid-row.
class ScrollFade extends StatelessWidget {
  const ScrollFade({
    super.key,
    this.color = AppColors.surface,
    this.height = 28,
  });
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => Positioned(
    left: 0,
    right: 0,
    bottom: 0,
    child: IgnorePointer(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0), color],
          ),
        ),
      ),
    ),
  );
}

/// Spinner sized to sit inside a button without changing its height.
class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key, required this.label, this.onPrimary = true});
  final String label;

  /// White on a primary action, muted on disabled controls.
  final bool onPrimary;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 22,
    height: 22,
    child: CircularProgressIndicator(
      strokeWidth: 2.4,
      color: onPrimary ? Colors.white : AppColors.muted,
      semanticsLabel: label,
    ),
  );
}

/// The one solid navy action on a screen. Labels are sentence case.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.busyLabel = 'Working',
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final String busyLabel;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: busy ? null : onPressed,
    child: busy
        ? ButtonSpinner(label: busyLabel, onPrimary: false)
        : _ButtonLabel(label: label, icon: icon),
  );
}

/// Quiet grey-filled button, for the alternative to the primary.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.danger = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool danger;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: danger
        ? OutlinedButton.styleFrom(
            foregroundColor: AppColors.danger,
            backgroundColor: AppColors.dangerBg,
          )
        : null,
    child: _ButtonLabel(label: label, icon: icon),
  );
}

class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel({required this.label, this.icon});
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final text = Flexible(
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
    if (icon == null) {
      return Row(mainAxisSize: MainAxisSize.min, children: [text]);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 19), const SizedBox(width: 8), text],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.action,
    this.onAction,
    this.top = 28,
  });
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: top, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: AppText.title.copyWith(fontSize: 20)),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(action!),
          ),
      ],
    ),
  );
}

/// Fixed bottom action area: a primary action with an optional secondary
/// action beneath it, and a busy state that blocks repeated presses.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    super.key,
    required this.label,
    required this.onPressed,
    this.secondaryLabel,
    this.onSecondary,
    this.busy = false,
    this.hint,
  });
  final String label;
  final VoidCallback? onPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool busy;

  /// Short line above the actions, e.g. "Saved just now".
  final Widget? hint;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        10,
        AppSpacing.gutter,
        14,
      ),
      color: AppColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hint != null)
            Padding(padding: const EdgeInsets.only(bottom: 12), child: hint),
          PrimaryButton(label: label, onPressed: onPressed, busy: busy),
          if (secondaryLabel != null) ...[
            const SizedBox(height: 10),
            SecondaryButton(
              label: secondaryLabel!,
              onPressed: busy ? null : onSecondary,
            ),
          ],
        ],
      ),
    ),
  );
}

/// A white pill floating over the page: what it costs or pays on the left,
/// the one action on the right. Use where the decision is about a number —
/// accepting a request, confirming a price.
class FloatingActionBar extends StatelessWidget {
  const FloatingActionBar({
    super.key,
    required this.title,
    required this.label,
    required this.onPressed,
    this.caption,
    this.busy = false,
    this.busyLabel = 'Working',
  });

  /// The headline figure, e.g. "You earn GH₵ 204.00".
  final String title;

  /// One quiet line under it, e.g. "after GRID's 15% fee".
  final String? caption;
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final String busyLabel;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(22, 10, 10, 10),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      boxShadow: AppShadow.float,
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  maxLines: 1,
                  style: AppText.subtitle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFeatures: AppText.tabular,
                  ),
                ),
              ),
              if (caption != null)
                Text(
                  caption!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption,
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: busy ? null : onPressed,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(horizontal: 26),
            shape: const StadiumBorder(),
          ),
          child: busy
              ? ButtonSpinner(label: busyLabel, onPrimary: false)
              : Text(label, maxLines: 1),
        ),
      ],
    ),
  );
}

/// An underlined text action, for the quiet alternative beside a
/// [FloatingActionBar] or under a paragraph.
class TextLink extends StatelessWidget {
  const TextLink({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(foregroundColor: AppColors.ink),
    child: Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.underline,
      ),
    ),
  );
}
