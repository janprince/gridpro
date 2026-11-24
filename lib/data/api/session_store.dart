import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The authenticated session as issued by `POST /auth/otp/verify`.
class Session {
  const Session({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    this.providerAccountId,
  });

  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String refreshToken;
  final String userId;
  final String fullName;
  final String phoneNumber;

  /// Present once the user owns a provider account — the app routes on this.
  final String? providerAccountId;

  Session copyWith({
    String? accessToken,
    DateTime? accessTokenExpiresAt,
    String? refreshToken,
    String? providerAccountId,
  }) => Session(
    accessToken: accessToken ?? this.accessToken,
    accessTokenExpiresAt: accessTokenExpiresAt ?? this.accessTokenExpiresAt,
    refreshToken: refreshToken ?? this.refreshToken,
    userId: userId,
    fullName: fullName,
    phoneNumber: phoneNumber,
    providerAccountId: providerAccountId ?? this.providerAccountId,
  );

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'accessTokenExpiresAt': accessTokenExpiresAt.toIso8601String(),
    'refreshToken': refreshToken,
    'userId': userId,
    'fullName': fullName,
    'phoneNumber': phoneNumber,
    'providerAccountId': providerAccountId,
  };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    accessToken: json['accessToken'] as String,
    accessTokenExpiresAt: DateTime.parse(
      json['accessTokenExpiresAt'] as String,
    ),
    refreshToken: json['refreshToken'] as String,
    userId: json['userId'] as String,
    fullName: json['fullName'] as String? ?? '',
    phoneNumber: json['phoneNumber'] as String? ?? '',
    providerAccountId: json['providerAccountId'] as String?,
  );
}

/// Persists the session in platform secure storage (Keychain / EncryptedSharedPreferences).
///
/// Tokens deliberately do not go in shared_preferences: the product specification requires
/// secure token storage, and refresh tokens are long-lived bearer credentials.
class SessionStore {
  SessionStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  static const _key = 'grid.session';

  final FlutterSecureStorage _storage;
  Session? _cached;

  Session? get current => _cached;

  Future<Session?> load() async {
    if (_cached != null) return _cached;
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      return _cached = Session.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } on FormatException {
      await clear();
      return null;
    }
  }

  Future<void> save(Session session) async {
    _cached = session;
    await _storage.write(key: _key, value: jsonEncode(session.toJson()));
  }

  Future<void> clear() async {
    _cached = null;
    await _storage.delete(key: _key);
  }
}
