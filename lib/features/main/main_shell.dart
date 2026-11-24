import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';
import 'package:grid_professionals/state/work_state.dart';

/// The four tabs. While it is on screen it also keeps requests fresh: GRID
/// has no push channel yet, and an offer only lasts a few minutes.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  static const _pollEvery = Duration(seconds: 30);
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Sample data never changes behind the app's back, so only live work polls.
    if (ref.read(liveWorkProvider)) {
      _poll = Timer.periodic(_pollEvery, (_) => _refresh());
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && ref.read(liveWorkProvider)) {
      _refresh();
      ref.read(profileProvider.notifier).refresh();
    }
  }

  void _refresh() {
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused) {
      return;
    }
    ref.read(workProvider.notifier).refresh();
  }

  static const _tabs = [
    (
      path: '/home',
      label: 'Home',
      icon: Icons.home_outlined,
      active: Icons.home_rounded,
    ),
    (
      path: '/jobs',
      label: 'Jobs',
      icon: Icons.event_note_outlined,
      active: Icons.event_note_rounded,
    ),
    (
      path: '/earnings',
      label: 'Earnings',
      icon: Icons.account_balance_wallet_outlined,
      active: Icons.account_balance_wallet_rounded,
    ),
    (
      path: '/account',
      label: 'Account',
      icon: Icons.person_outline_rounded,
      active: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = _tabs.indexWhere((tab) => location.startsWith(tab.path));
    final offers = ref.watch(
      workProvider.select((work) => work.value?.offers.length ?? 0),
    );
    return Scaffold(
      body: SafeArea(bottom: false, child: widget.child),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _NavItem(
                      label: _tabs[i].label,
                      badge: i == 1 ? offers : 0,
                      icon: i == index ? _tabs[i].active : _tabs[i].icon,
                      selected: i == index,
                      onTap: () => context.go(_tabs[i].path),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  /// A count shown on the icon, e.g. requests waiting for an answer.
  final int badge;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.navy : AppColors.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: badge > 0 ? '$label, $badge new' : label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge(
                isLabelVisible: badge > 0,
                label: Text('$badge'),
                backgroundColor: AppColors.warning,
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: color,
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
