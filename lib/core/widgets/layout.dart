import 'package:flutter/material.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 32),
  });
  final List<Widget> children;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) =>
      ListView(padding: padding, children: children);
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.onTap,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(
    color: color,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(padding: padding, child: child),
    ),
  );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    ),
  );
}

/// Fixed bottom action area with a primary action, optional secondary action
/// and a busy state that blocks repeated presses.
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
  final String? hint;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                hint!,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          Row(
            children: [
              if (secondaryLabel != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : onSecondary,
                    child: Text(secondaryLabel!),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: busy ? null : onPressed,
                  child: busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: AppColors.muted,
                            semanticsLabel: 'Working',
                          ),
                        )
                      : Text(label),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
