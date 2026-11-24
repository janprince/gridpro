import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grid_professionals/core/routing/app_router.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';
import 'package:grid_professionals/state/api_providers.dart';
import 'package:grid_professionals/state/app_state.dart';

class GridProfessionalsApp extends ConsumerStatefulWidget {
  const GridProfessionalsApp({super.key});

  @override
  ConsumerState<GridProfessionalsApp> createState() =>
      _GridProfessionalsAppState();
}

class _GridProfessionalsAppState extends ConsumerState<GridProfessionalsApp> {
  @override
  void initState() {
    super.initState();
    // GRID ended the session (signed in elsewhere, or away too long): the
    // tokens are already gone, so send the provider to sign in again rather
    // than leaving them on screens that can no longer load.
    ref.read(apiClientProvider).onSessionExpired = () async {
      if (!mounted || !ref.read(appControllerProvider).isAuthenticated) return;
      await ref.read(appControllerProvider.notifier).sessionEnded();
      if (mounted) ref.read(routerProvider).go('/login');
    };
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'GRID Professionals',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    builder: (context, child) => ColoredBox(
      color: AppColors.surfaceSubtle,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: child,
        ),
      ),
    ),
    routerConfig: ref.watch(routerProvider),
  );
}
