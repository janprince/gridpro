import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_professionals/app/app.dart';
import 'package:grid_professionals/core/models/onboarding_models.dart';
import 'package:grid_professionals/data/api/api_config.dart';
import 'package:grid_professionals/data/api/catalogue_repository.dart';
import 'package:grid_professionals/data/api/provider_repository.dart';
import 'package:grid_professionals/data/api/session_store.dart';
import 'package:grid_professionals/state/api_providers.dart';
import 'package:grid_professionals/state/app_state.dart';
import 'package:grid_professionals/state/onboarding_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Sessions extends SessionStore {
  _Sessions(this.result);
  final Future<Session?> result;
  @override
  Future<Session?> load() => result;
}

class _ProviderRepository implements ProviderRepository {
  _ProviderRepository(this.application);
  final Future<RemoteApplication> application;
  @override
  Future<RemoteApplication> getApplication() => application;
  @override
  Future<List<RemoteDocument>> getDocuments() async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnavailableCatalogue implements CatalogueRepository {
  int attempts = 0;
  @override
  Future<Catalogue> load() async {
    attempts++;
    throw StateError('Server unavailable');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<SharedPreferences> _preferences([
  Map<String, Object> values = const {},
]) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

void main() {
  testWidgets('slow catalogue does not hold a new user on the splash', (
    tester,
  ) async {
    final catalogue = Completer<Catalogue>();
    final preferences = await _preferences();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesProvider.overrideWithValue(preferences),
          apiEnabledProvider.overrideWithValue(true),
          sessionStoreProvider.overrideWithValue(_Sessions(Future.value(null))),
          catalogueProvider.overrideWith((ref) => catalogue.future),
        ],
        child: const GridProfessionalsApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Get started'), findsOneWidget);
    expect(catalogue.isCompleted, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'stalled secure storage opens the saved application after its deadline',
    (tester) async {
      final sessions = Completer<Session?>();
      final preferences = await _preferences({'isAuthenticated': true});
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWithValue(preferences),
            apiEnabledProvider.overrideWithValue(true),
            sessionStoreProvider.overrideWithValue(_Sessions(sessions.future)),
            catalogueProvider.overrideWith(
              (ref) async => const Catalogue(services: [], regions: []),
            ),
          ],
          child: const GridProfessionalsApp(),
        ),
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Your application'), findsOneWidget);
      expect(sessions.isCompleted, isFalse);
      // A platform response arriving after navigation must not use a disposed widget ref.
      sessions.complete(null);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'late server status cannot overwrite state after startup times out',
    (tester) async {
      final application = Completer<RemoteApplication>();
      final preferences = await _preferences({'isAuthenticated': true});
      final session = Session(
        accessToken: 'test',
        refreshToken: 'test',
        accessTokenExpiresAt: DateTime(2030),
        userId: 'test',
        fullName: 'Test Provider',
        phoneNumber: '',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWithValue(preferences),
            apiEnabledProvider.overrideWithValue(true),
            sessionStoreProvider.overrideWithValue(
              _Sessions(Future.value(session)),
            ),
            providerRepositoryProvider.overrideWithValue(
              _ProviderRepository(application.future),
            ),
            catalogueProvider.overrideWith(
              (ref) async => const Catalogue(services: [], regions: []),
            ),
          ],
          child: const GridProfessionalsApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Your application'), findsOneWidget);
      application.complete(
        const RemoteApplication(
          status: 'Approved',
          accountVerificationStatus: 'Approved',
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GridProfessionalsApp)),
      );
      expect(
        container.read(onboardingControllerProvider).status,
        ApplicationStatus.draft,
      );
      expect(tester.takeException(), isNull);
    },
  );

  test('catalogue failure resolves instead of silently retrying', () async {
    final repository = _UnavailableCatalogue();
    final container = ProviderContainer.test(
      overrides: [
        apiEnabledProvider.overrideWithValue(true),
        catalogueRepositoryProvider.overrideWithValue(repository),
      ],
    );
    await expectLater(
      container.read(catalogueProvider.future),
      throwsStateError,
    );
    expect(repository.attempts, 1);
  });

  test('development API uses the host address for each platform', () {
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(ApiConfig.baseUrl, 'http://10.0.2.2:8080/api/v1');
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(ApiConfig.baseUrl, 'http://127.0.0.1:8080/api/v1');
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    expect(ApiConfig.baseUrl, 'http://127.0.0.1:8080/api/v1');
  });
}
