import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_professionals/app/app.dart';
import 'package:grid_professionals/core/models/models.dart';
import 'package:grid_professionals/state/api_providers.dart';
import 'package:grid_professionals/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> preparePreferences([
  Map<String, Object> values = const {},
]) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

Future<void> pumpApp(WidgetTester tester, SharedPreferences preferences) async {
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
  // Let the splash decide the destination.
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
}

/// A draft with every section complete, as persisted JSON.
String completeDraftJson({int currentStep = 9}) {
  const done = UploadState.done;
  final draft = OnboardingDraft(
    phone: '24 555 0192',
    providerType: ProviderType.individual,
    fullName: 'Ama Owusu',
    delivery: ServiceDelivery.travels,
    primaryServiceId: 'cleaning',
    subServices: const ['Deep cleaning'],
    yearsExperience: 6,
    experienceSummary: 'Deep cleans for homes and apartments in Accra.',
    region: 'Greater Accra',
    towns: const ['East Legon', 'Adenta'],
    hourlyRate: 40,
    payoutType: PayoutType.mobileMoney,
    momoProviderId: 'mtn',
    momoNumber: '24 555 0192',
    momoName: 'Ama Owusu',
    portfolio: const [
      UploadItem(id: 'upload-1', label: 'Work photo 1', state: done),
    ],
    idFront: const UploadItem(id: 'id-f', label: 'front', state: done),
    idBack: const UploadItem(id: 'id-b', label: 'back', state: done),
    selfie: const UploadItem(id: 'id-s', label: 'selfie', state: done),
    currentStep: currentStep,
  );
  return jsonEncode(draft.toJson());
}

void main() {
  testWidgets('signup flow blocks empty steps and advances after selection', (
    tester,
  ) async {
    final preferences = await preparePreferences();
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester, preferences);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    // Phone entry with Ghana formatting.
    await tester.enterText(find.byType(TextFormField), '241234567');
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
    expect(find.textContaining('+233 24 123 4567'), findsOneWidget);

    // OTP error state first, then success.
    await tester.tap(find.text('Confirm code'));
    await tester.pump();
    expect(find.textContaining('Enter all 6 digits'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.tap(find.text('Confirm code'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    // Wizard step 1: provider type. Continue without choosing → inline error.
    expect(find.text('How you work'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.textContaining('Choose how you work'), findsOneWidget);

    await tester.tap(find.text('I work on my own'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Your details'), findsOneWidget);

    // Back returns to the provider-type step with the choice preserved.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('How you work'), findsOneWidget);

    // Timers (OTP countdown) may still be pending; let them run out.
    await tester.pump(const Duration(seconds: 31));
  });

  testWidgets('entered data survives an app restart', (tester) async {
    final preferences = await preparePreferences();
    await pumpApp(tester, preferences);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '241234567');
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.tap(find.text('Confirm code'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I run a small business'));
    await tester.pump(const Duration(seconds: 31));

    // Restart: fresh widget tree and provider container, same storage.
    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester, preferences);

    // The splash resumes to the application hub with the choice kept.
    expect(find.text('Your application'), findsOneWidget);
    expect(find.text('Small business'), findsOneWidget);
  });

  testWidgets('OTP resend enables after the countdown', (tester) async {
    final preferences = await preparePreferences();
    await pumpApp(tester, preferences);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '241234567');
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();

    expect(find.textContaining('You can resend the code'), findsOneWidget);
    expect(find.text('Resend code'), findsNothing);
    await tester.pump(const Duration(seconds: 31));
    expect(find.text('Resend code'), findsOneWidget);
  });

  testWidgets('hub shows section statuses and review submits', (tester) async {
    final preferences = await preparePreferences({
      'isAuthenticated': true,
      'onboardingDraft': completeDraftJson(),
    });
    await pumpApp(tester, preferences);

    expect(find.text('Your application'), findsOneWidget);
    expect(find.text('10 of 10'), findsOneWidget);
    await tester.tap(find.text('Review & submit'));
    await tester.pumpAndSettle();

    expect(find.text('Review your application'), findsOneWidget);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
    await tester.pumpAndSettle();
    // Payout details are masked on review.
    expect(find.textContaining('••••'), findsWidgets);

    // Cannot submit before agreeing to standards.
    await tester.tap(find.text('Submit application'));
    await tester.pump();
    expect(
      find.text('Agree to the professional standards to submit.'),
      findsOneWidget,
    );

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.text('Submit application'));
    await tester.pump(const Duration(milliseconds: 100));
    // While submitting the action is disabled (spinner shown).
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    expect(find.text('Your application is under review.'), findsOneWidget);
    // Status survives restart.
    expect(preferences.getString('applicationStatus'), 'underReview');
  });

  testWidgets('every application status state renders', (tester) async {
    for (final status in [
      ApplicationStatus.underReview,
      ApplicationStatus.moreInfoRequired,
      ApplicationStatus.verificationFailed,
      ApplicationStatus.approved,
      ApplicationStatus.rejected,
    ]) {
      final preferences = await preparePreferences({
        'isAuthenticated': true,
        'onboardingDraft': completeDraftJson(),
        'applicationStatus': status.name,
      });
      await pumpApp(tester, preferences);
      expect(
        find.text('Application status'),
        findsOneWidget,
        reason: 'status screen should open for ${status.name}',
      );
      final marker = switch (status) {
        ApplicationStatus.moreInfoRequired => 'We need a little more from you',
        ApplicationStatus.verificationFailed =>
          'Identity verification was unsuccessful',
        ApplicationStatus.approved => 'You\'re approved.',
        ApplicationStatus.rejected => 'Your application was not approved',
        _ => 'Your application is under review.',
      };
      expect(
        find.text(marker),
        findsOneWidget,
        reason: 'expected marker for ${status.name}',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('approved state leads to the first-time dashboard', (
    tester,
  ) async {
    final preferences = await preparePreferences({
      'isAuthenticated': true,
      'onboardingDraft': completeDraftJson(),
      'applicationStatus': ApplicationStatus.approved.name,
    });
    await pumpApp(tester, preferences);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go to your dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome, Ama'), findsOneWidget);
    // No demo earnings or demo identity on a brand-new profile.
    expect(find.text('GH₵ 0.00'), findsOneWidget);
    expect(find.text('Efua'), findsNothing);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('No offers yet'), findsOneWidget);
  });

  testWidgets('compact screens with large text render without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    final preferences = await preparePreferences({
      'isAuthenticated': true,
      'onboardingDraft': completeDraftJson(currentStep: 0),
    });
    await pumpApp(tester, preferences);
    expect(find.text('Your application'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Continue setup'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
