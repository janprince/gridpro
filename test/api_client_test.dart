import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_professionals/data/api/api_client.dart';
import 'package:grid_professionals/data/api/api_exception.dart';
import 'package:grid_professionals/data/api/session_store.dart';

/// In-memory session store so these tests need no platform channel.
class _FakeSessionStore implements SessionStore {
  _FakeSessionStore([this._session]);

  Session? _session;
  int saves = 0;

  @override
  Session? get current => _session;

  @override
  Future<Session?> load() async => _session;

  @override
  Future<void> save(Session session) async {
    saves++;
    _session = session;
  }

  @override
  Future<void> clear() async => _session = null;
}

Session _session({String access = 'access-1', String refresh = 'refresh-1'}) =>
    Session(
      accessToken: access,
      accessTokenExpiresAt: DateTime.now().add(const Duration(minutes: 30)),
      refreshToken: refresh,
      userId: 'user-1',
      fullName: 'Ama Owusu',
      phoneNumber: '+233241234567',
    );

/// Serves canned responses and records what the client sent.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8ListLike>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

typedef Uint8ListLike = List<int>;

ResponseBody _json(Map<String, dynamic> body, int status) =>
    ResponseBody.fromString(
      _encode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

String _encode(Map<String, dynamic> body) {
  final buffer = StringBuffer('{');
  var first = true;
  body.forEach((key, value) {
    if (!first) buffer.write(',');
    first = false;
    buffer.write('"$key":');
    if (value == null) {
      buffer.write('null');
    } else if (value is String) {
      buffer.write('"$value"');
    } else if (value is Map) {
      buffer.write(_encode(value.cast<String, dynamic>()));
    } else {
      buffer.write('$value');
    }
  });
  buffer.write('}');
  return buffer.toString();
}

void main() {
  test('unwraps the response envelope', () async {
    final dio = Dio();
    dio.httpClientAdapter = _StubAdapter(
      (_) => _json({
        'success': true,
        'data': {'id': 'abc'},
        'error': null,
      }, 200),
    );
    final client = ApiClient(_FakeSessionStore(_session()), dio: dio);

    final data = await client.get<Map<String, dynamic>>(
      '/provider-accounts/me',
    );

    expect(data['id'], 'abc');
  });

  test('tolerates a command response that carries no data key', () async {
    final dio = Dio();
    dio.httpClientAdapter = _StubAdapter(
      (_) => _json({'success': true, 'error': null}, 200),
    );
    final client = ApiClient(_FakeSessionStore(_session()), dio: dio);

    await expectLater(
      client.post<void>('/provider-applications/me/submit'),
      completes,
    );
  });

  test('turns an enveloped error into its stable code', () async {
    final dio = Dio();
    dio.httpClientAdapter = _StubAdapter(
      (_) => _json({
        'success': false,
        'error': {
          'code': 'providers.locked',
          'message': 'Locked while under review.',
        },
      }, 409),
    );
    final client = ApiClient(_FakeSessionStore(_session()), dio: dio);

    final error = await client
        .put<void>('/provider-accounts/me', body: {})
        .then<ApiException?>(
          (_) => null,
          onError: (Object e) => e as ApiException,
        );

    expect(error!.code, 'providers.locked');
    expect(error.isConflict, isTrue);
  });

  test('reads a non-enveloped framework 401 as an expired session', () async {
    final dio = Dio();
    dio.httpClientAdapter = _StubAdapter(
      (_) => ResponseBody.fromString('', 401),
    );
    final store = _FakeSessionStore();
    final client = ApiClient(store, dio: dio);

    final error = await client
        .get<void>('/jobs')
        .then<ApiException?>(
          (_) => null,
          onError: (Object e) => e as ApiException,
        );

    expect(error!.isUnauthorized, isTrue);
  });

  test('refreshes once and replays the original request after a 401', () async {
    final dio = Dio();
    var protectedCalls = 0;
    var refreshCalls = 0;
    final adapter = _StubAdapter((options) {
      if (options.path.contains('tokens/refresh')) {
        refreshCalls++;
        return _json({
          'success': true,
          'data': {
            'accessToken': 'access-2',
            'accessTokenExpiresAt': DateTime.now()
                .add(const Duration(minutes: 30))
                .toIso8601String(),
            'refreshToken': 'refresh-2',
          },
        }, 200);
      }
      protectedCalls++;
      // Fail the first attempt only, so a successful refresh must drive the retry.
      if (protectedCalls == 1) return ResponseBody.fromString('', 401);
      return _json({
        'success': true,
        'data': {'id': 'job-1'},
      }, 200);
    });
    dio.httpClientAdapter = adapter;
    final store = _FakeSessionStore(_session());
    final client = ApiClient(store, dio: dio);

    final data = await client.get<Map<String, dynamic>>('/jobs/1');

    expect(data['id'], 'job-1');
    expect(
      refreshCalls,
      1,
      reason: 'refresh tokens rotate, so exactly one refresh may run',
    );
    expect(protectedCalls, 2, reason: 'the original request is replayed once');
    expect(store.current!.refreshToken, 'refresh-2');
  });

  test(
    'reports a connection failure as offline rather than an auth problem',
    () async {
      final dio = Dio();
      dio.httpClientAdapter = _StubAdapter((options) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });
      final client = ApiClient(_FakeSessionStore(_session()), dio: dio);

      final error = await client
          .get<void>('/jobs')
          .then<ApiException?>(
            (_) => null,
            onError: (Object e) => e as ApiException,
          );

      expect(error!.isOffline, isTrue);
      expect(error.isUnauthorized, isFalse);
    },
  );
}
