import 'package:dio/dio.dart';

/// A failure surfaced by the GRID API or by the network beneath it.
///
/// The API wraps everything in `{success, data, error, traceId, timestamp}` and puts a stable
/// machine-readable identifier in `error.code` — that code is what callers should branch on,
/// never the message. Framework-level failures (malformed body, expired token) come back
/// *outside* that envelope, so this type normalises both shapes.
class ApiException implements Exception {
  ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.fieldErrors = const {},
    this.traceId,
  });

  /// Stable identifier such as `providers.locked` or `jobs.invalid_transition`.
  final String code;
  final String message;
  final int? statusCode;

  /// Field-level validation messages keyed by field name.
  final Map<String, String> fieldErrors;
  final String? traceId;

  bool get isUnauthorized =>
      statusCode == 401 || code == 'auth.unauthenticated';

  /// True when the request never reached the server, so retrying later may succeed.
  bool get isOffline => code == 'network.offline' || code == 'network.timeout';

  bool get isConflict => statusCode == 409;

  @override
  String toString() => fieldErrors.isEmpty
      ? 'ApiException($code, $statusCode): $message'
      : 'ApiException($code, $statusCode): $message $fieldErrors';

  /// Builds an exception from a Dio failure, handling both response shapes.
  factory ApiException.fromDio(DioException error) {
    final response = error.response;

    if (response == null) {
      final offline =
          error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.unknown;
      return ApiException(
        code: offline ? 'network.offline' : 'network.timeout',
        message: offline
            ? 'No connection to GRID. Your work is saved on this device.'
            : 'GRID took too long to respond. Try again.',
      );
    }

    final body = response.data;
    if (body is Map<String, dynamic> && body['error'] is Map<String, dynamic>) {
      final err = body['error'] as Map<String, dynamic>;
      final fields = <String, String>{};
      final rawFields = err['fields'];
      if (rawFields is List) {
        for (final item in rawFields) {
          if (item is Map<String, dynamic>) {
            final field = item['field']?.toString();
            final message = item['message']?.toString();
            if (field != null && message != null) fields[field] = message;
          }
        }
      }
      return ApiException(
        code: err['code']?.toString() ?? 'server.error',
        message: err['message']?.toString() ?? 'Something went wrong.',
        statusCode: response.statusCode,
        fieldErrors: fields,
        traceId: body['traceId']?.toString(),
      );
    }

    // Not enveloped: framework 400/401/415 responses and anything a proxy injects.
    return ApiException(
      code: switch (response.statusCode) {
        401 => 'auth.unauthenticated',
        403 => 'auth.forbidden',
        404 => 'server.not_found',
        _ => 'server.error',
      },
      message: switch (response.statusCode) {
        401 => 'Your session has expired. Sign in again.',
        403 => 'You do not have permission to do that.',
        404 => 'That was not found.',
        _ => 'Something went wrong. Try again.',
      },
      statusCode: response.statusCode,
    );
  }
}
