import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grid_professionals/core/models/models.dart';
import 'package:grid_professionals/data/api/api_exception.dart';
import 'package:grid_professionals/data/api/api_grid_repository.dart';
import 'package:grid_professionals/data/repositories/grid_repository.dart';
import 'package:grid_professionals/state/api_providers.dart';
import 'package:grid_professionals/state/app_state.dart';
import 'package:grid_professionals/state/onboarding_state.dart';

/// Where the provider's work comes from: GRID for a real account, sample
/// data for the demo, and an empty account when the app runs without GRID.
final gridRepositoryProvider = Provider<GridRepository>((ref) {
  final real = ref.watch(
    appControllerProvider.select((state) => state.isNewProvider),
  );
  if (!real) return MockGridRepository();
  if (ref.watch(apiEnabledProvider)) {
    return ApiGridRepository(ref.watch(apiClientProvider));
  }
  final draft = ref.read(onboardingControllerProvider).draft;
  return MockGridRepository.empty(
    ProviderProfile(
      ownerName: draft.fullName.trim(),
      displayName: draft.businessName.trim().isNotEmpty
          ? draft.businessName.trim()
          : draft.fullName.trim(),
      phone: draft.phone.isEmpty ? '' : '+233 ${draft.phone}',
      online: true,
      business: draft.isBusiness,
      memberSince: DateTime.now().year,
      serviceAreas: draft.towns,
    ),
  );
});

/// True when the work on screen is live from GRID and worth polling.
final liveWorkProvider = Provider<bool>(
  (ref) => ref.watch(gridRepositoryProvider) is ApiGridRepository,
);

/// What to tell the provider when something they tried didn't go through.
String describeError(Object error) => switch (error) {
  ApiException(isOffline: true) =>
    'No connection. Check your network and try again.',
  ApiException(code: 'jobs.offer_already_accepted') =>
    'Another professional took this request first.',
  ApiException(code: 'jobs.offer_expired') =>
    'This request is no longer available.',
  ApiException(:final message) => message,
  _ => 'Something went wrong. Try again.',
};

// ── Profile ──────────────────────────────────────────────────────────────

final profileProvider =
    AsyncNotifierProvider<ProfileController, ProviderProfile>(
      ProfileController.new,
    );

class ProfileController extends AsyncNotifier<ProviderProfile> {
  @override
  Future<ProviderProfile> build() =>
      ref.watch(gridRepositoryProvider).profile();

  /// Returns null when it worked, or what to tell the provider when not.
  Future<String?> setOnline(bool online) async {
    try {
      state = AsyncData(
        await ref.read(gridRepositoryProvider).setOnline(online),
      );
      return null;
    } on ApiException catch (error) {
      if (error.code != 'providers.not_job_ready') return describeError(error);
      // Re-read so the screen can show exactly what GRID is waiting for.
      await refresh();
      final missing = state.value?.missingToGoOnline ?? const [];
      return missing.isEmpty ? error.message : missing.first;
    }
  }

  Future<String?> saveDescription(String description) async {
    try {
      state = AsyncData(
        await ref.read(gridRepositoryProvider).updateDescription(description),
      );
      return null;
    } on ApiException catch (error) {
      return describeError(error);
    }
  }

  Future<void> refresh() async {
    try {
      state = AsyncData(await ref.read(gridRepositoryProvider).profile());
    } on ApiException {
      // Keep what is on screen; the next refresh will try again.
    }
  }
}

// ── Requests and jobs ────────────────────────────────────────────────────

class WorkState {
  const WorkState({this.offers = const [], this.jobs = const []});

  /// Open requests, soonest to expire first.
  final List<Job> offers;
  final List<Job> jobs;

  List<Job> get active =>
      jobs.where((job) => job.stage.isActive).toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  List<Job> get finished =>
      jobs
          .where(
            (job) =>
                job.stage == JobStage.completed ||
                job.stage == JobStage.paid ||
                job.stage == JobStage.cancelled,
          )
          .toList()
        ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

  Job? offer(String id) => offers.where((job) => job.id == id).firstOrNull;
  Job? job(String id) => jobs.where((job) => job.id == id).firstOrNull;
}

final workProvider = AsyncNotifierProvider<WorkController, WorkState>(
  WorkController.new,
);

class WorkController extends AsyncNotifier<WorkState> {
  @override
  Future<WorkState> build() => _load(ref.watch(gridRepositoryProvider));

  Future<WorkState> _load(GridRepository repository) async {
    final (offers, jobs) = await (repository.offers(), repository.jobs()).wait;
    offers.sort(
      (a, b) => (a.expiresAt ?? a.scheduledAt).compareTo(
        b.expiresAt ?? b.scheduledAt,
      ),
    );
    return WorkState(offers: offers, jobs: jobs);
  }

  /// Re-reads from GRID. A failure leaves what is on screen alone, so a
  /// dropped connection never blanks a job the provider is in the middle of.
  Future<void> refresh() async {
    try {
      final next = await _load(ref.read(gridRepositoryProvider));
      if (ref.mounted) state = AsyncData(next);
    } on Object catch (error, stack) {
      if (ref.mounted && !state.hasValue) state = AsyncError(error, stack);
    }
  }

  /// Throws [ApiException] when GRID refuses, e.g. someone else got there first.
  Future<Job> accept(Job offer) async {
    try {
      final job = await ref.read(gridRepositoryProvider).acceptOffer(offer);
      _put(job, removeOffer: offer.id);
      return job;
    } on ApiException {
      await refresh();
      rethrow;
    }
  }

  Future<void> decline(Job offer, String reason) async {
    await ref.read(gridRepositoryProvider).declineOffer(offer, reason);
    final current = state.value ?? const WorkState();
    state = AsyncData(
      WorkState(
        offers: current.offers.where((item) => item.id != offer.id).toList(),
        jobs: current.jobs,
      ),
    );
  }

  Future<Job> advance(Job job) async {
    try {
      final next = await ref.read(gridRepositoryProvider).advance(job);
      _put(next);
      if (next.stage == JobStage.completed) ref.invalidate(earningsProvider);
      return next;
    } on ApiException {
      await refresh();
      rethrow;
    }
  }

  void _put(Job job, {String? removeOffer}) {
    final current = state.value ?? const WorkState();
    state = AsyncData(
      WorkState(
        offers: current.offers.where((item) => item.id != removeOffer).toList(),
        jobs: [
          for (final item in current.jobs)
            if (item.id != job.id) item,
          job,
        ],
      ),
    );
  }
}

// ── Earnings and settings ────────────────────────────────────────────────

final earningsProvider = FutureProvider<EarningsOverview>(
  (ref) => ref.watch(gridRepositoryProvider).earnings(),
);

final workSettingsProvider = FutureProvider.autoDispose<WorkSettings>(
  (ref) => ref.watch(gridRepositoryProvider).workSettings(),
);
