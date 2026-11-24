// A contract check against a running GRID API: the app's own repository
// drives a booking from request to earning. Skipped unless pointed at a
// development server that has the seeded demo accounts and fixed OTP codes:
//
//   flutter test test/live_api_test.dart \
//     --dart-define=GRID_LIVE_API=true \
//     --dart-define=GRID_API_BASE_URL=http://127.0.0.1:8080/api/v1
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_professionals/core/models/models.dart';
import 'package:grid_professionals/data/api/api_client.dart';
import 'package:grid_professionals/data/api/api_exception.dart';
import 'package:grid_professionals/data/api/api_grid_repository.dart';
import 'package:grid_professionals/data/api/auth_repository.dart';
import 'package:grid_professionals/data/api/session_store.dart';

const _live = bool.fromEnvironment('GRID_LIVE_API');

/// Keeps the session in memory; the real store needs platform secure storage.
class _Sessions extends SessionStore {
  Session? _session;
  @override
  Session? get current => _session;
  @override
  Future<Session?> load() async => _session;
  @override
  Future<void> save(Session session) async => _session = session;
  @override
  Future<void> clear() async => _session = null;
}

Future<ApiClient> _signIn(String phone) async {
  final sessions = _Sessions();
  final client = ApiClient(sessions);
  final auth = AuthRepository(client, sessions);
  // A rerun inside the resend cooldown has to wait for a fresh code: the
  // last one may already be used.
  for (var attempt = 0; ; attempt++) {
    try {
      await auth.requestOtp(phone);
      break;
    } on ApiException catch (error) {
      if (error.code != 'auth.otp_rate_limited' || attempt > 15) rethrow;
      await Future<void>.delayed(const Duration(seconds: 5));
    }
  }
  await auth.verifyOtp(phoneNumber: phone, code: '123456');
  return client;
}

void main() {
  test(
    'a booking reaches the provider and runs through to an earning',
    skip: _live ? false : 'needs a running development API',
    timeout: const Timeout(Duration(minutes: 3)),
    () async {
      final provider = ApiGridRepository(await _signIn('0240000002'));
      final customer = await _signIn('0240000001');

      var profile = await provider.setOnline(true);
      expect(profile.online, isTrue);
      expect(profile.ownerName, 'Efua Asante');
      expect(profile.phoneLabel, '+233 24 000 0002');
      expect(profile.offerings.map((o) => o.service), [
        ServiceKind.cleaning,
        ServiceKind.laundry,
      ]);
      expect(profile.payout?.providerName, 'MTN Mobile Money');
      expect(profile.serviceAreas, contains('East Legon'));

      // Settings round-trip through the same calls the screens make.
      final settings = await provider.workSettings();
      await provider.saveWorkSettings(
        settings.copyWith(
          workingDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
          startHour: 0,
          endHour: 23,
          travelRadiusKm: 20,
        ),
      );
      expect((await provider.workSettings()).travelRadiusKm, 20);
      // GRID sets prices; a service can only be paused or resumed.
      final cleaning = profile.offerings.first;
      await provider.saveOffering(cleaning.copyWith(sameDay: true));
      profile = await provider.profile();
      expect(profile.offerings.first.active, isTrue);

      // The customer books a two-bedroom deep clean at their saved home, at
      // GRID's price. Development pays at once, so dispatch starts right away.
      final homes = await customer.get<List<dynamic>>('/properties');
      final catalogue = await customer.get<Map<String, dynamic>>(
        '/service-catalogue',
      );
      final deep = [
        for (final section in catalogue['sections'] as List)
          for (final service in (section as Map)['services'] as List)
            for (final p in (service as Map)['packages'] as List) p as Map,
      ].firstWhere((p) => p['slug'] == 'cleaning-deep-2-bed');
      expect(deep['price'], 450);
      // Earlier runs that stopped half-way leave bookings that would clash.
      for (final open in await customer.get<List<dynamic>>(
        '/service-requests',
      )) {
        final row = open as Map<String, dynamic>;
        if (row['canCancel'] == true) {
          await customer.post<dynamic>(
            '/service-requests/${row['id']}/cancel',
            body: {'reason': 'Live contract test cleanup.'},
          );
        }
      }
      final before = (await provider.offers()).length;
      final booking = await customer.post<Map<String, dynamic>>(
        '/service-requests',
        headers: {
          'Idempotency-Key': 'live-${DateTime.now().microsecondsSinceEpoch}',
        },
        body: {
          'lines': [
            {'packageId': deep['id'], 'quantity': 1},
          ],
          'propertyId': (homes.first as Map<String, dynamic>)['id'],
          'scheduledAt': DateTime.now()
              .toUtc()
              .add(const Duration(minutes: 90))
              .toIso8601String(),
          'notes': 'Gate code 2468.',
        },
      );
      expect(booking['total'], 450);
      expect(booking['status'], 'Searching');
      expect((booking['payment'] as Map)['status'], 'Paid');

      final offers = await provider.offers();
      expect(offers.length, before + 1);
      final offer = offers.last;
      expect(offer.stage, JobStage.offer);
      expect(offer.title, 'Deep clean · 2 bedrooms');
      expect(offer.price, 450);
      expect(offer.earnings, 382.5);
      expect(offer.area, 'East Legon');
      expect(offer.distanceKm, lessThan(2));
      expect(offer.customerName, isEmpty);
      expect(offer.expiresAt!.isAfter(DateTime.now()), isTrue);

      var job = await provider.acceptOffer(offer);
      expect(job.code, startsWith('GJ-'));
      expect(job.customerName, 'Ama Mensah');
      expect(job.address, '12 Lagos Avenue');
      expect(job.customerPhone, '233240000001');
      expect(job.latitude, isNotNull);

      // Every step the app shows is one GRID accepts, in the same order.
      for (final stage in [
        JobStage.onTheWay,
        JobStage.arrived,
        JobStage.inProgress,
        JobStage.completed,
      ]) {
        expect(job.nextAction?.next, stage);
        job = await provider.advance(job);
        expect(job.stage, stage);
      }
      expect(job.nextAction, isNull);
      expect(
        (await provider.jobs()).any((j) => j.id == job.id && !j.stage.isActive),
        isTrue,
      );

      var earnings = await provider.earnings();
      expect(earnings.pending, greaterThanOrEqualTo(382.5));
      expect(earnings.earnings.first.jobCode, job.code);
      expect(earnings.earnings.first.status, EarningStatus.pending);

      // The customer confirms and rates it; the earning becomes available
      // and the rating shows on the provider's profile.
      final requestId = booking['id'] as String;
      await customer.post<dynamic>(
        '/service-requests/$requestId/confirm-completion',
      );
      final rated = await customer.post<Map<String, dynamic>>(
        '/service-requests/$requestId/review',
        body: {'rating': 5, 'comment': 'Spotless.'},
      );
      expect((rated['review'] as Map)['rating'], 5);
      earnings = await provider.earnings();
      expect(earnings.earnings.first.status, EarningStatus.available);
      expect((await provider.profile()).rating, isNotNull);

      final ticket = await provider.reportProblem(
        reason: 'Payment or payout issue',
        details: 'Contract test.',
        jobId: job.id,
      );
      expect(ticket.reference, startsWith('GRID-'));
    },
  );
}
