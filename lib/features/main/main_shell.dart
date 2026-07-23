import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = location.startsWith('/schedule')
        ? 1
        : location.startsWith('/earnings')
        ? 2
        : location.startsWith('/profile')
        ? 3
        : location.startsWith('/support')
        ? 4
        : 0;
    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        height: 72,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.mint,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (value) => context.go(
          const [
            '/jobs',
            '/schedule',
            '/earnings',
            '/profile',
            '/support',
          ][value],
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'Jobs',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Earnings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.support_agent_outlined),
            selectedIcon: Icon(Icons.support_agent),
            label: 'Support',
          ),
        ],
      ),
    );
  }
}
