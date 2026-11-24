import 'package:grid_professionals/core/models/models.dart';
import 'package:grid_professionals/data/api/api_client.dart';
import 'package:grid_professionals/data/repositories/grid_repository.dart';

/// [GridRepository] against the GRID API.
///
/// GRID decides everything that matters here: which requests a provider is
/// offered, what a job pays, and which step comes next. This class only
/// translates between the API's shapes and the app's models.
class ApiGridRepository implements GridRepository {
  ApiGridRepository(this._client);

  final ApiClient _client;

  // ── Profile ────────────────────────────────────────────────────────────

  @override
  Future<ProviderProfile> profile() async => _profile(
    await _client.get<Map<String, dynamic>>('/provider-accounts/me/summary'),
  );

  @override
  Future<ProviderProfile> setOnline(bool online) async => _profile(
    await _client.put<Map<String, dynamic>>(
      '/provider-accounts/me/operating-status',
      body: {'operatingStatus': online ? 'Online' : 'Offline'},
    ),
  );

  @override
  Future<ProviderProfile> updateDescription(String description) async =>
      _profile(
        await _client.put<Map<String, dynamic>>(
          '/provider-accounts/me/profile',
          body: {'description': description},
        ),
      );

  // ── Requests and jobs ──────────────────────────────────────────────────

  @override
  Future<List<Job>> offers() async {
    final rows = await _client.get<List<dynamic>>(
      '/job-offers',
      query: {'status': 'Pending'},
    );
    return [for (final row in rows.cast<Map<String, dynamic>>()) _offer(row)];
  }

  @override
  Future<List<Job>> jobs() async {
    final (active, done) = await (
      _client.get<List<dynamic>>('/jobs', query: {'status': 'active'}),
      _client.get<List<dynamic>>('/jobs', query: {'status': 'completed'}),
    ).wait;
    return [
      for (final row in [...active, ...done].cast<Map<String, dynamic>>())
        _job(row),
    ];
  }

  @override
  Future<Job> acceptOffer(Job offer) async => _job(
    await _client.post<Map<String, dynamic>>('/job-offers/${offer.id}/accept'),
  );

  @override
  Future<void> declineOffer(Job offer, String reason) => _client.post<dynamic>(
    '/job-offers/${offer.id}/decline',
    body: {'reason': reason},
  );

  @override
  Future<Job> advance(Job job) async {
    final command = job.nextCommand;
    if (command == null) return job;
    return _job(
      await _client.post<Map<String, dynamic>>('/jobs/${job.id}/$command'),
    );
  }

  // ── Earnings ───────────────────────────────────────────────────────────

  @override
  Future<EarningsOverview> earnings() async {
    final (summary, earnings, payouts) = await (
      _client.get<Map<String, dynamic>>('/provider-earnings/summary'),
      _client.get<List<dynamic>>('/provider-earnings'),
      _client.get<List<dynamic>>('/provider-payouts'),
    ).wait;
    return EarningsOverview(
      available: _money(summary['availableAmount']),
      pending: _money(summary['pendingAmount']),
      paid: _money(summary['paidAmount']),
      last7Days: _money(summary['last7Days']),
      last30Days: _money(summary['last30Days']),
      earnings: [
        for (final row in earnings.cast<Map<String, dynamic>>())
          Earning(
            jobCode: row['jobCode'] as String,
            service: _service(row['serviceCategory']),
            title: row['title'] as String? ?? '',
            customer: row['customerName'] as String? ?? '',
            gross: _money(row['gross']),
            fee: _money(row['fee']),
            date: _date(row['earnedAt']),
            status: switch (row['status']) {
              'Pending' => EarningStatus.pending,
              'Available' => EarningStatus.available,
              _ => EarningStatus.paid,
            },
          ),
      ],
      payouts: [
        for (final row in payouts.cast<Map<String, dynamic>>())
          Payout(
            reference: row['reference'] as String,
            amount: _money(row['amount']),
            date: _date(row['paidAt'] ?? row['createdAt']),
            status: switch (row['status']) {
              'Paid' => PayoutStatus.paid,
              'Failed' => PayoutStatus.failed,
              _ => PayoutStatus.scheduled,
            },
            destination: row['destination'] as String? ?? '',
          ),
      ],
    );
  }

  // ── Services and hours ─────────────────────────────────────────────────

  /// The API replaces the whole offering, so the fields this screen doesn't
  /// edit are read back first and sent again unchanged.
  @override
  Future<void> saveOffering(ServiceOffering offering) async {
    final rows = await _client.get<List<dynamic>>('/provider-offerings');
    final current = rows.cast<Map<String, dynamic>>().firstWhere(
      (row) => row['id'] == offering.id,
    );
    final priceField = switch (current['pricingMode']) {
      'FixedPrice' => 'fixedPrice',
      'StartingFrom' => 'startingPrice',
      'PerUnit' => 'unitPrice',
      _ => 'inspectionFee',
    };
    await _client.put<dynamic>(
      '/provider-offerings/${offering.id}',
      body: {
        ...current,
        priceField: offering.price,
        'supportsSameDay': offering.sameDay,
        'isActive': offering.active,
      },
    );
  }

  static const _days = {
    'Monday': 'Mon',
    'Tuesday': 'Tue',
    'Wednesday': 'Wed',
    'Thursday': 'Thu',
    'Friday': 'Fri',
    'Saturday': 'Sat',
    'Sunday': 'Sun',
  };

  @override
  Future<WorkSettings> workSettings() async {
    final (rules, summary) = await (
      _client.get<List<dynamic>>('/provider-availability/rules'),
      _client.get<Map<String, dynamic>>('/provider-accounts/me/summary'),
    ).wait;
    final working = [
      for (final rule in rules.cast<Map<String, dynamic>>())
        if (rule['isAvailable'] == true) rule,
    ];
    int hour(Object? time, int fallback) =>
        int.tryParse('$time'.split(':').first) ?? fallback;
    return WorkSettings(
      workingDays: [for (final rule in working) _days[rule['dayOfWeek']] ?? ''],
      startHour: working.isEmpty ? 7 : hour(working.first['startTime'], 7),
      endHour: working.isEmpty ? 18 : hour(working.first['endTime'], 18),
      travelRadiusKm: _money(summary['travelRadiusKm']),
    );
  }

  @override
  Future<void> saveWorkSettings(WorkSettings settings) async {
    String time(int hour) => '${hour.toString().padLeft(2, '0')}:00:00';
    await _client.put<dynamic>(
      '/provider-availability/rules',
      body: {
        'rules': [
          for (final day in _days.entries)
            {
              'dayOfWeek': day.key,
              'startTime': time(settings.startHour),
              'endTime': time(settings.endHour),
              'isAvailable': settings.workingDays.contains(day.value),
            },
        ],
      },
    );
    await _client.put<dynamic>(
      '/provider-accounts/me/location',
      body: {'travelRadiusKm': settings.travelRadiusKm},
    );
  }

  // ── Support ────────────────────────────────────────────────────────────

  @override
  Future<SupportTicket> reportProblem({
    required String reason,
    required String details,
    String? jobId,
  }) async {
    final lower = reason.toLowerCase();
    final data = await _client.post<Map<String, dynamic>>(
      '/support-tickets',
      body: {
        'category': lower.contains('safe')
            ? 'Safety'
            : lower.contains('pay')
            ? 'Payment'
            : lower.contains('customer')
            ? 'Customer'
            : lower.contains('job') || lower.contains('item')
            ? 'Job'
            : 'Other',
        'subject': reason,
        'details': details,
        'jobId': jobId,
      },
    );
    return SupportTicket(
      reference: data['reference'] as String,
      status: data['status'] as String? ?? 'Open',
    );
  }

  // ── Mapping ────────────────────────────────────────────────────────────

  static ProviderProfile _profile(Map<String, dynamic> data) {
    final payout = data['payoutMethod'] as Map<String, dynamic>?;
    return ProviderProfile(
      ownerName: data['ownerName'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      phone: data['phoneNumber'] as String? ?? '',
      online: data['operatingStatus'] == 'Online',
      business: data['accountType'] == 'Business',
      description: data['description'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble(),
      completedJobs: (data['completedJobs'] as num?)?.toInt() ?? 0,
      memberSince: data['memberSince'] == null
          ? null
          : _date(data['memberSince']).year,
      offerings: [
        for (final row
            in (data['offerings'] as List? ?? const [])
                .cast<Map<String, dynamic>>())
          ServiceOffering(
            id: row['id'] as String,
            service: _service(row['serviceCategory']),
            active: row['isActive'] as bool? ?? true,
            price: (row['price'] as num?)?.toDouble(),
            pricingMode: row['pricingMode'] as String? ?? 'PerUnit',
            unitName: row['unitName'] as String?,
            sameDay: row['supportsSameDay'] as bool? ?? true,
          ),
      ],
      serviceAreas: [
        for (final area in (data['serviceAreas'] as List? ?? const []))
          area as String,
      ],
      travelRadiusKm: _money(data['travelRadiusKm']),
      payout: payout == null
          ? null
          : PayoutAccount(
              providerName: payout['providerName'] as String? ?? '',
              accountName: payout['accountName'] as String? ?? '',
              maskedNumber: payout['maskedAccountNumber'] as String? ?? '',
              mobileMoney: payout['methodType'] == 'MobileMoney',
              verified: payout['verificationStatus'] == 'Verified',
            ),
      canGoOnline: data['canGoOnline'] as bool? ?? false,
      missingToGoOnline: [
        for (final item
            in (data['missingToGoOnline'] as List? ?? const [])
                .cast<Map<String, dynamic>>())
          item['message'] as String? ?? '',
      ],
    );
  }

  /// A request before acceptance. GRID withholds who and exactly where.
  static Job _offer(Map<String, dynamic> row) => Job(
    id: row['id'] as String,
    code: row['requestReference'] as String? ?? '',
    service: _service(row['serviceCategory']),
    title: row['title'] as String? ?? '',
    scope: row['scope'] as String? ?? '',
    area: row['generalArea'] as String? ?? '',
    address: '',
    customerName: '',
    scheduledAt: _date(row['scheduledAt']),
    price: _money(row['price']),
    fee: _money(row['fee']),
    distanceKm: (row['distanceKm'] as num?)?.toDouble(),
    stage: JobStage.offer,
    notes: row['notes'] as String? ?? '',
    items: [for (final item in (row['items'] as List? ?? const [])) '$item'],
    expiresAt: _date(row['expiresAt']),
  );

  static Job _job(Map<String, dynamic> row) => Job(
    id: row['id'] as String,
    code: row['jobCode'] as String? ?? '',
    service: _service(row['serviceCategory']),
    title: row['title'] as String? ?? '',
    scope: row['scope'] as String? ?? '',
    area: row['area'] as String? ?? '',
    address: row['address'] as String? ?? '',
    customerName: row['customerName'] as String? ?? '',
    customerPhone: row['customerPhone'] as String?,
    scheduledAt: _date(row['scheduledAt']),
    price: _money(row['price']),
    fee: _money(row['fee']),
    distanceKm: (row['distanceKm'] as num?)?.toDouble(),
    stage: _stage(row['stage'] as String?),
    notes: row['notes'] as String? ?? '',
    items: [for (final item in (row['items'] as List? ?? const [])) '$item'],
    latitude: (row['latitude'] as num?)?.toDouble(),
    longitude: (row['longitude'] as num?)?.toDouble(),
    nextCommand: row['nextCommand'] as String?,
    cancelReason: row['cancelReason'] as String?,
  );

  /// GRID's `awaitingConfirmation` is the app's "done, waiting on the
  /// customer", and its `completed` is the app's "paid into your earnings".
  static JobStage _stage(String? code) => switch (code) {
    'onTheWay' => JobStage.onTheWay,
    'arrived' => JobStage.arrived,
    'inProgress' => JobStage.inProgress,
    'pickedUp' => JobStage.pickedUp,
    'processing' => JobStage.processing,
    'readyForDelivery' => JobStage.readyForDelivery,
    'outForDelivery' => JobStage.outForDelivery,
    'awaitingConfirmation' => JobStage.completed,
    'completed' => JobStage.paid,
    'cancelled' => JobStage.cancelled,
    _ => JobStage.accepted,
  };

  static ServiceKind _service(Object? slug) =>
      ServiceKindInfo.fromName('$slug') ?? ServiceKind.cleaning;

  static double _money(Object? value) => (value as num?)?.toDouble() ?? 0;

  /// GRID sends UTC; the app shows the phone's local time.
  static DateTime _date(Object? value) =>
      DateTime.parse(value as String).toLocal();
}
