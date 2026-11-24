import 'package:grid_professionals/core/models/models.dart';
import 'package:grid_professionals/data/mock_data.dart';

/// Everything the app does once a provider is approved: who they are, the
/// requests and jobs in front of them, what they've earned, and getting help.
///
/// The screens only know this contract. [MockGridRepository] backs the demo
/// and the widget tests; the API implementation is in `data/api`.
abstract interface class GridRepository {
  Future<ProviderProfile> profile();

  /// Going online can be refused; the error says what is still missing.
  Future<ProviderProfile> setOnline(bool online);
  Future<ProviderProfile> updateDescription(String description);

  /// Open requests, soonest to expire first.
  Future<List<Job>> offers();

  /// Live jobs and finished ones.
  Future<List<Job>> jobs();

  /// Returns the job the offer became, now with the customer's details.
  Future<Job> acceptOffer(Job offer);
  Future<void> declineOffer(Job offer, String reason);

  /// Takes the job's next step and returns it as GRID now has it.
  Future<Job> advance(Job job);

  Future<EarningsOverview> earnings();

  Future<void> saveOffering(ServiceOffering offering);
  Future<WorkSettings> workSettings();
  Future<void> saveWorkSettings(WorkSettings settings);

  Future<SupportTicket> reportProblem({
    required String reason,
    required String details,
    String? jobId,
  });
}

/// Sample data that behaves like the real thing: accepting, declining and
/// moving jobs forward all stick for as long as the app is open.
class MockGridRepository implements GridRepository {
  MockGridRepository({ProviderProfile? profile, List<Job>? jobs})
    : _profile = profile ?? MockData.profile,
      _jobs = jobs ?? List<Job>.from(MockData.jobs),
      _sample = profile == null;

  /// A provider with nothing yet: used when the app runs without GRID and
  /// someone has just finished onboarding.
  MockGridRepository.empty(ProviderProfile profile)
    : this(profile: profile, jobs: []);

  ProviderProfile _profile;
  final List<Job> _jobs;
  final bool _sample;
  WorkSettings _settings = const WorkSettings(travelRadiusKm: 15);
  int _tickets = 0;

  @override
  Future<ProviderProfile> profile() async => _profile;

  @override
  Future<ProviderProfile> setOnline(bool online) async =>
      _profile = _profile.copyWith(online: online);

  @override
  Future<ProviderProfile> updateDescription(String description) async =>
      _profile = _profile.copyWith(description: description);

  @override
  Future<List<Job>> offers() async => [
    for (final job in _jobs)
      if (job.stage == JobStage.offer) job,
  ];

  @override
  Future<List<Job>> jobs() async => [
    for (final job in _jobs)
      if (job.stage != JobStage.offer && job.stage != JobStage.declined) job,
  ];

  @override
  Future<Job> acceptOffer(Job offer) async =>
      _replace(offer.copyWith(stage: JobStage.accepted));

  @override
  Future<void> declineOffer(Job offer, String reason) async {
    _replace(offer.copyWith(stage: JobStage.declined));
  }

  @override
  Future<Job> advance(Job job) async {
    final next = job.nextAction?.next;
    return next == null ? job : _replace(job.copyWith(stage: next));
  }

  Job _replace(Job job) {
    final index = _jobs.indexWhere((item) => item.id == job.id);
    if (index >= 0) _jobs[index] = job;
    return job;
  }

  @override
  Future<EarningsOverview> earnings() async {
    if (!_sample) return const EarningsOverview();
    final earnings = MockData.earnings;
    final now = DateTime.now();
    double total(EarningStatus status) => earnings
        .where((item) => item.status == status)
        .fold(0, (sum, item) => sum + item.net);
    double since(int days) => earnings
        .where((item) => now.difference(item.date).inDays < days)
        .fold(0, (sum, item) => sum + item.net);
    return EarningsOverview(
      available: total(EarningStatus.available),
      pending: total(EarningStatus.pending),
      paid: total(EarningStatus.paid),
      last7Days: since(7),
      last30Days: since(30),
      earnings: earnings,
      payouts: MockData.payouts,
    );
  }

  @override
  Future<void> saveOffering(ServiceOffering offering) async {
    _profile = ProviderProfile(
      ownerName: _profile.ownerName,
      displayName: _profile.displayName,
      phone: _profile.phone,
      online: _profile.online,
      business: _profile.business,
      description: _profile.description,
      rating: _profile.rating,
      completedJobs: _profile.completedJobs,
      memberSince: _profile.memberSince,
      offerings: [
        for (final item in _profile.offerings)
          if (item.id == offering.id) offering else item,
      ],
      serviceAreas: _profile.serviceAreas,
      travelRadiusKm: _profile.travelRadiusKm,
      payout: _profile.payout,
    );
  }

  @override
  Future<WorkSettings> workSettings() async => _settings;

  @override
  Future<void> saveWorkSettings(WorkSettings settings) async =>
      _settings = settings;

  @override
  Future<SupportTicket> reportProblem({
    required String reason,
    required String details,
    String? jobId,
  }) async =>
      SupportTicket(reference: 'GRID-${2841 + _tickets++}', status: 'Open');
}
