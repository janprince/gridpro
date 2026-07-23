import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grid_professionals/core/routing/app_router.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';

class GridProfessionalsApp extends ConsumerWidget {
  const GridProfessionalsApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'GRID Professionals',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    routerConfig: ref.watch(routerProvider),
  );
}
