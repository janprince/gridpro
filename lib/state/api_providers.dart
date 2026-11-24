import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grid_professionals/data/api/api_client.dart';
import 'package:grid_professionals/data/api/api_config.dart';
import 'package:grid_professionals/data/api/auth_repository.dart';
import 'package:grid_professionals/data/api/catalogue_repository.dart';
import 'package:grid_professionals/data/api/provider_repository.dart';
import 'package:grid_professionals/data/api/session_store.dart';

/// Whether the app talks to a real GRID API. Overridden to false in widget tests, which run
/// without a server or platform secure storage.
final apiEnabledProvider = Provider<bool>((ref) => ApiConfig.useApi);

final sessionStoreProvider = Provider<SessionStore>((ref) => SessionStore());

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(sessionStoreProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(sessionStoreProvider),
  ),
);

final providerRepositoryProvider = Provider<ProviderRepository>(
  (ref) => ProviderRepository(ref.watch(apiClientProvider)),
);

final catalogueRepositoryProvider = Provider<CatalogueRepository>(
  (ref) => CatalogueRepository(ref.watch(apiClientProvider)),
);

/// The GRID catalogue. Falls back to the bundled Ghana configuration when the API cannot be
/// reached, so onboarding still runs offline.
final catalogueProvider = FutureProvider<Catalogue>(
  // Surface a failed request so offline fallbacks and sync queues can proceed.
  // Riverpod's automatic retries otherwise keep .future pending at startup.
  retry: (retryCount, error) => null,
  (ref) async {
    if (!ref.watch(apiEnabledProvider)) {
      return const Catalogue(services: [], regions: []);
    }
    return ref.watch(catalogueRepositoryProvider).load();
  },
);
