import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grid_professionals/core/models/models.dart';
import 'package:grid_professionals/data/repositories/grid_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

final preferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);
final gridRepositoryProvider = Provider<GridRepository>(
  (ref) => const MockGridRepository(),
);
final appControllerProvider = NotifierProvider<AppController, AppState>(
  AppController.new,
);

class AppState {
  const AppState({
    required this.isAuthenticated,
    required this.onboardingComplete,
    required this.verificationStatus,
    required this.availability,
    required this.jobs,
    this.isNewProvider = false,
    this.supportTickets = const [],
    this.draftQuote,
  });
  final bool isAuthenticated;
  final bool onboardingComplete;

  /// True when the account came through the real onboarding flow, so the
  /// dashboard shows a first-time (empty) experience instead of demo data.
  final bool isNewProvider;
  final VerificationStatus verificationStatus;
  final Availability availability;
  final List<Job> jobs;
  final List<SupportTicket> supportTickets;
  final Quote? draftQuote;

  AppState copyWith({
    bool? isAuthenticated,
    bool? onboardingComplete,
    bool? isNewProvider,
    VerificationStatus? verificationStatus,
    Availability? availability,
    List<Job>? jobs,
    List<SupportTicket>? supportTickets,
    Quote? draftQuote,
  }) => AppState(
    isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    isNewProvider: isNewProvider ?? this.isNewProvider,
    verificationStatus: verificationStatus ?? this.verificationStatus,
    availability: availability ?? this.availability,
    jobs: jobs ?? this.jobs,
    supportTickets: supportTickets ?? this.supportTickets,
    draftQuote: draftQuote ?? this.draftQuote,
  );
}

class AppController extends Notifier<AppState> {
  late SharedPreferences _preferences;

  @override
  AppState build() {
    _preferences = ref.read(preferencesProvider);
    return AppState(
      isAuthenticated: _preferences.getBool('isAuthenticated') ?? false,
      onboardingComplete: _preferences.getBool('onboardingComplete') ?? false,
      isNewProvider: _preferences.getBool('isNewProvider') ?? false,
      verificationStatus: VerificationStatus.notStarted,
      availability: Availability(
        status:
            AvailabilityStatus.values[_preferences.getInt('availability') ?? 0],
      ),
      jobs: ref.read(gridRepositoryProvider).getJobs(),
    );
  }

  Future<void> authenticate() async {
    await _preferences.setBool('isAuthenticated', true);
    state = state.copyWith(isAuthenticated: true);
  }

  Future<void> completeOnboarding({bool asNewProvider = false}) async {
    await _preferences.setBool('onboardingComplete', true);
    await _preferences.setBool('isNewProvider', asNewProvider);
    state = state.copyWith(
      onboardingComplete: true,
      isNewProvider: asNewProvider,
      verificationStatus: VerificationStatus.approved,
    );
  }

  /// Switches a first-time provider dashboard over to the demo data set.
  Future<void> loadDemoData() async {
    await _preferences.setBool('isNewProvider', false);
    state = state.copyWith(isNewProvider: false);
  }

  void submitApplication() =>
      state = state.copyWith(verificationStatus: VerificationStatus.submitted);
  void approveDemoApplication() =>
      state = state.copyWith(verificationStatus: VerificationStatus.approved);

  Future<void> setAvailability(AvailabilityStatus value) async {
    await _preferences.setInt('availability', value.index);
    state = state.copyWith(
      availability: state.availability.copyWith(status: value),
    );
  }

  Job job(String id) => state.jobs.firstWhere((item) => item.id == id);

  void updateJob(String id, JobStatus status, {double? quoteTotal}) {
    state = state.copyWith(
      jobs: [
        for (final item in state.jobs)
          if (item.id == id)
            item.copyWith(status: status, quoteTotal: quoteTotal)
          else
            item,
      ],
    );
  }

  void saveQuote(Quote quote) {
    state = state.copyWith(draftQuote: quote);
    updateJob(quote.jobId, JobStatus.quoteDraft, quoteTotal: quote.total);
  }

  void submitQuote(Quote quote) {
    state = state.copyWith(draftQuote: quote);
    updateJob(
      quote.jobId,
      JobStatus.awaitingCustomerApproval,
      quoteTotal: quote.total,
    );
  }

  void submitSupportTicket(String reason, String details) {
    final ticket = SupportTicket(
      id: 'GRID-${2841 + state.supportTickets.length}',
      reason: reason,
      details: details,
      createdAt: DateTime.now(),
      status: 'Open',
    );
    state = state.copyWith(supportTickets: [...state.supportTickets, ticket]);
  }

  Future<void> resetDemo() async {
    await _preferences.clear();
    state = AppState(
      isAuthenticated: false,
      onboardingComplete: false,
      verificationStatus: VerificationStatus.notStarted,
      availability: const Availability(),
      jobs: ref.read(gridRepositoryProvider).getJobs(),
    );
  }
}
