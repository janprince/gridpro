import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_professionals/app/app.dart';
import 'package:grid_professionals/features/home/home_screen.dart';
import 'package:grid_professionals/state/api_providers.dart';
import 'package:grid_professionals/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('opens the GRID Pro welcome experience', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesProvider.overrideWithValue(preferences),
          // Widget tests run without a server or platform secure storage.
          apiEnabledProvider.overrideWithValue(false),
        ],
        child: const GridProfessionalsApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    expect(find.text('GRID'), findsOneWidget);
    expect(
      find.textContaining('AC servicing and pest control'),
      findsOneWidget,
    );
    expect(find.text('Get started'), findsOneWidget);
    await tester.drag(find.byType(Scrollable), const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(find.text('Log in'), findsOneWidget);
  });

  testWidgets('home shows requests and the next job with its action', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesProvider.overrideWithValue(preferences),
          // Widget tests run without a server or platform secure storage.
          apiEnabledProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SafeArea(child: HomeScreen())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('New requests'), findsOneWidget);
    // Only the soonest-expiring request is shown; the rest are a tap away.
    expect(find.text('Review request'), findsOneWidget);
    expect(find.text('See all 2'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(find.text('Up next'), findsOneWidget);
    // The earliest active job is laundry in the wash; its one action shows.
    expect(find.text('Mark as ready'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
