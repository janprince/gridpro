import 'package:flutter/foundation.dart';

/// Where the app talks to the GRID API.
///
/// Override at build time:
/// `flutter run --dart-define=GRID_API_BASE_URL=http://192.168.1.10:8080/api/v1`
abstract final class ApiConfig {
  static const _configuredBaseUrl = String.fromEnvironment('GRID_API_BASE_URL');

  /// Android emulator uses its host bridge; iOS simulator, desktop and web
  /// reach the development API on localhost. Physical devices need an override.
  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : '127.0.0.1';
    return 'http://$host:8080/api/v1';
  }

  /// Set false to run entirely on bundled mock data (useful for demos offline).
  static const useApi = bool.fromEnvironment(
    'GRID_USE_API',
    defaultValue: true,
  );

  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 30);

  /// Absolute URL for a media object identified by its storage key.
  static String mediaUrl(String storageKey) => '$baseUrl/media/$storageKey';
}
