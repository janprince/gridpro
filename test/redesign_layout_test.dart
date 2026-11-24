import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';
import 'package:grid_professionals/features/account/account_screens.dart';
import 'package:grid_professionals/features/earnings/earnings_screens.dart';
import 'package:grid_professionals/features/home/home_screen.dart';
import 'package:grid_professionals/features/jobs/job_screens.dart';
import 'package:grid_professionals/state/api_providers.dart';
import 'package:grid_professionals/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final entry in <String, Widget>{
    'Home': const HomeScreen(),
    'Jobs': const JobsScreen(),
    'Earnings': const EarningsScreen(),
    'Account': const AccountScreen(),
  }.entries) {
    testWidgets('${entry.key} scrolls at 320px with enlarged text', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWithValue(preferences),
            apiEnabledProvider.overrideWithValue(false),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(body: SafeArea(child: entry.value)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final page = find.byType(ListView).first;
      for (var i = 0; i < 8; i++) {
        await tester.drag(page, const Offset(0, -450));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }
}
