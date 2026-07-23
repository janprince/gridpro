import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_professionals/app/app.dart';
import 'package:grid_professionals/features/jobs/jobs_dashboard.dart';
import 'package:grid_professionals/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('opens the GRID Pro welcome experience', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [preferencesProvider.overrideWithValue(preferences)],
        child: const GridProfessionalsApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    expect(find.text('GRID'), findsOneWidget);
    expect(find.textContaining('Your skills'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    await tester.drag(find.byType(Scrollable), const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(find.text('Log in'), findsOneWidget);
  });

  testWidgets('action-required cards paint their content', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [preferencesProvider.overrideWithValue(preferences)],
        child: const MaterialApp(
          home: Scaffold(body: SafeArea(child: JobsDashboard())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Action required'), findsOneWidget);
    expect(find.text('Start your journey'), findsOneWidget);
    expect(find.text('Approved — ready to work'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
