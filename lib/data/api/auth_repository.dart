import 'package:grid_professionals/data/api/api_client.dart';
import 'package:grid_professionals/data/api/session_store.dart';

/// Result of asking GRID to text a verification code.
class OtpChallenge {
  const OtpChallenge({
    required this.phoneNumber,
    required this.expiresInSeconds,
    this.developmentCode,
  });

  final String phoneNumber;
  final int expiresInSeconds;

  /// Only populated when the API runs in development mode — lets local testing skip the SMS.
  final String? developmentCode;
}

/// Passwordless phone + OTP authentication.
class AuthRepository {
  AuthRepository(this._client, this._sessions);

  final ApiClient _client;
  final SessionStore _sessions;

  Future<OtpChallenge> requestOtp(String phoneNumber) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/auth/otp/request',
      body: {'phoneNumber': phoneNumber},
    );
    return OtpChallenge(
      phoneNumber: data['phoneNumber'] as String,
      expiresInSeconds: data['expiresInSeconds'] as int,
      developmentCode: data['developmentCode'] as String?,
    );
  }

  /// Verifies the code and stores the resulting session. [fullName] is only applied by the
  /// server when the account is brand new.
  Future<Session> verifyOtp({
    required String phoneNumber,
    required String code,
    String? fullName,
  }) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/auth/otp/verify',
      body: {
        'phoneNumber': phoneNumber,
        'code': code,
        if (fullName != null && fullName.trim().isNotEmpty)
          'fullName': fullName.trim(),
      },
    );
    final session = _sessionFrom(data);
    await _sessions.save(session);
    return session;
  }

  /// Re-reads the current user so `providerAccountId` reflects an account created since sign-in.
  Future<Session?> refreshUser() async {
    final session = await _sessions.load();
    if (session == null) return null;
    final user = await _client.get<Map<String, dynamic>>('/auth/me');
    final updated = session.copyWith(
      providerAccountId: user['providerAccountId'] as String?,
    );
    await _sessions.save(updated);
    return updated;
  }

  Future<void> logout() async {
    final session = await _sessions.load();
    if (session != null) {
      try {
        await _client.post<void>(
          '/auth/logout',
          body: {'refreshToken': session.refreshToken},
        );
      } on Object {
        // Signing out locally must succeed even when the server cannot be reached.
      }
    }
    await _sessions.clear();
  }

  Session _sessionFrom(Map<String, dynamic> data) {
    final user = data['user'] as Map<String, dynamic>;
    return Session(
      accessToken: data['accessToken'] as String,
      accessTokenExpiresAt: DateTime.parse(
        data['accessTokenExpiresAt'] as String,
      ),
      refreshToken: data['refreshToken'] as String,
      userId: user['id'] as String,
      fullName: user['fullName'] as String? ?? '',
      phoneNumber: user['phoneNumber'] as String? ?? '',
      providerAccountId: user['providerAccountId'] as String?,
    );
  }
}
