import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grid_professionals/core/models/onboarding_models.dart';
import 'package:grid_professionals/data/api/api_exception.dart';
import 'package:grid_professionals/data/api/onboarding_sync.dart';
import 'package:grid_professionals/data/api/provider_repository.dart';
import 'package:grid_professionals/data/country/country_config.dart';
import 'package:grid_professionals/data/country/ghana_config.dart';
import 'package:grid_professionals/state/api_providers.dart';
import 'package:grid_professionals/state/app_state.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Active market configuration.
///
/// The catalogue (services and coverage areas) comes from GRID so the app and the backend can
/// never disagree about what exists; the bundled Ghana configuration supplies market rules —
/// dial code, currency, payout rails — and stands in for the catalogue until it loads or when
/// the device is offline. Swap the source config to launch another country.
final countryConfigProvider = Provider<CountryConfig>((ref) {
  final catalogue = ref.watch(catalogueProvider).value;
  if (catalogue == null) return ghanaConfig;
  return ghanaConfig.withCatalogue(
    services: catalogue.services.isEmpty ? null : catalogue.services,
    regions: catalogue.regions.isEmpty ? null : catalogue.regions,
    feePercent: catalogue.feePercent,
  );
});

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );

class OnboardingState {
  const OnboardingState({
    required this.draft,
    required this.status,
    this.submitting = false,
    this.submitFailed = false,
    this.pendingSync = const {},
    this.syncing = false,
    this.offline = false,
    this.serverRequirements = const [],
  });

  final OnboardingDraft draft;
  final ApplicationStatus status;
  final bool submitting;
  final bool submitFailed;

  /// Sections saved on this device but not yet accepted by GRID.
  final Set<OnboardingStep> pendingSync;
  final bool syncing;

  /// True when the last attempt to reach GRID failed for connectivity reasons.
  final bool offline;

  /// Requirements the server says are still outstanding, shown on the review screen.
  final List<({String code, String message})> serverRequirements;

  bool get hasDraftInProgress =>
      status == ApplicationStatus.draft &&
      (draft.providerType != null || draft.fullName.isNotEmpty);

  bool get hasUnsyncedWork => pendingSync.isNotEmpty;

  OnboardingState copyWith({
    OnboardingDraft? draft,
    ApplicationStatus? status,
    bool? submitting,
    bool? submitFailed,
    Set<OnboardingStep>? pendingSync,
    bool? syncing,
    bool? offline,
    List<({String code, String message})>? serverRequirements,
  }) => OnboardingState(
    draft: draft ?? this.draft,
    status: status ?? this.status,
    submitting: submitting ?? this.submitting,
    submitFailed: submitFailed ?? this.submitFailed,
    pendingSync: pendingSync ?? this.pendingSync,
    syncing: syncing ?? this.syncing,
    offline: offline ?? this.offline,
    serverRequirements: serverRequirements ?? this.serverRequirements,
  );
}

class OnboardingController extends Notifier<OnboardingState> {
  static const _draftKey = 'onboardingDraft';
  static const _statusKey = 'applicationStatus';
  static const _pendingKey = 'onboardingPendingSync';
  static const _offeringKey = 'onboardingOfferingId';
  static const _accountReadyKey = 'onboardingAccountReady';

  late SharedPreferences _preferences;
  int _uploadCounter = 0;
  final _picker = ImagePicker();

  @override
  OnboardingState build() {
    _preferences = ref.read(preferencesProvider);
    return OnboardingState(
      draft: _restoreDraft(),
      status: _restoreStatus(),
      pendingSync: _restorePending(),
    );
  }

  OnboardingSyncService get _sync {
    final service =
        OnboardingSyncService(
            ref.read(providerRepositoryProvider),
            ref.read(catalogueRepositoryProvider),
          )
          ..accountReady = _preferences.getBool(_accountReadyKey) ?? false
          ..offeringId = _preferences.getString(_offeringKey);
    return service;
  }

  void _rememberSyncIds(OnboardingSyncService service) {
    _preferences.setBool(_accountReadyKey, service.accountReady);
    if (service.offeringId != null) {
      _preferences.setString(_offeringKey, service.offeringId!);
    }
  }

  Set<OnboardingStep> _restorePending() {
    final names = _preferences.getStringList(_pendingKey) ?? const [];
    return {
      for (final step in OnboardingStep.values)
        if (names.contains(step.name)) step,
    };
  }

  void _savePending(Set<OnboardingStep> pending) {
    _preferences.setStringList(_pendingKey, [for (final s in pending) s.name]);
  }

  OnboardingDraft _restoreDraft() {
    final raw = _preferences.getString(_draftKey);
    if (raw == null) return const OnboardingDraft();
    try {
      return OnboardingDraft.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return const OnboardingDraft();
    }
  }

  ApplicationStatus _restoreStatus() {
    final name = _preferences.getString(_statusKey);
    return ApplicationStatus.values.firstWhere(
      (status) => status.name == name,
      orElse: () => ApplicationStatus.draft,
    );
  }

  CountryConfig get config => ref.read(countryConfigProvider);

  /// Applies a change to the draft and persists it immediately so entered
  /// data survives route changes and app restarts.
  void updateDraft(OnboardingDraft Function(OnboardingDraft draft) change) {
    final draft = change(state.draft);
    state = state.copyWith(draft: draft);
    _preferences.setString(_draftKey, jsonEncode(draft.toJson()));
  }

  void setPhone(String phone) =>
      updateDraft((draft) => draft.copyWith(phone: phone));

  void goToStep(OnboardingStep step) =>
      updateDraft((draft) => draft.copyWith(currentStep: step.index));

  void nextStep() {
    if (state.draft.currentStep < OnboardingStep.values.length - 1) {
      updateDraft(
        (draft) => draft.copyWith(currentStep: draft.currentStep + 1),
      );
    }
  }

  void previousStep() {
    if (state.draft.currentStep > 0) {
      updateDraft(
        (draft) => draft.copyWith(currentStep: draft.currentStep - 1),
      );
    }
  }

  /// First step that still needs input, for "continue where you left off".
  OnboardingStep get firstIncompleteStep => OnboardingStep.values.firstWhere(
    (step) => state.draft.statusOf(step, config) != SectionStatus.complete,
    orElse: () => OnboardingStep.identity,
  );

  // ---- Sync ---------------------------------------------------------------
  //
  // The local draft is the working copy and is already saved by the time these run. Pushing to
  // GRID is best-effort: a failure queues the section and the provider keeps moving.

  /// Pushes a completed section, plus anything queued from earlier, to GRID.
  Future<void> syncStep(OnboardingStep step) async {
    if (!ref.read(apiEnabledProvider)) return;
    // Offerings and service areas are pushed by server id, so the catalogue must be resolved.
    try {
      // A failed warm-up is retried when the provider next saves a step.
      if (ref.read(catalogueProvider).hasError) {
        ref.invalidate(catalogueProvider);
      }
      await ref.read(catalogueProvider.future);
    } on Object {
      // Offline: the queue below will hold the section until the catalogue is reachable.
    }
    final queue = {...state.pendingSync, step};
    state = state.copyWith(syncing: true, pendingSync: queue);
    _savePending(queue);

    final service = _sync;
    final remaining = <OnboardingStep>{};
    var offline = false;

    // Replay in step order so the account exists before anything that references it.
    for (final queued in OnboardingStep.values.where(queue.contains)) {
      try {
        await service.push(queued, state.draft);
      } on ApiException catch (error) {
        remaining.add(queued);
        offline = offline || error.isOffline;
        // A connectivity failure will hit every later call too — stop and keep the queue.
        if (error.isOffline) {
          remaining.addAll(queue.where((s) => s.index > queued.index));
          break;
        }
      }
    }

    _rememberSyncIds(service);
    _savePending(remaining);
    state = state.copyWith(
      syncing: false,
      pendingSync: remaining,
      offline: offline,
    );
  }

  /// Pulls server state after a resume so the app reflects decisions made by Ops.
  Future<void> refreshFromServer({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (!ref.read(apiEnabledProvider)) return;
    try {
      final repository = ref.read(providerRepositoryProvider);
      final (application, documents) = await (() async {
        final application = await repository.getApplication();
        final documents = await repository.getDocuments();
        return (application, documents);
      })().timeout(timeout);
      // Only apply a response that arrived within the deadline. A late result
      // must not replace local state after the provider starts using the app.
      if (!ref.mounted) return;
      _setStatus(_statusFrom(application, documents));
    } on TimeoutException {
      // Keep the saved application status when the API is slow/unreachable.
    } on ApiException {
      // Keep whatever the app already knows; the status screen stays usable offline.
    }
  }

  /// Maps GRID's application status onto the app's, deriving the identity-failure state from a
  /// rejected identity document rather than treating it as a demo-only screen.
  ApplicationStatus _statusFrom(
    RemoteApplication application,
    List<RemoteDocument> documents,
  ) {
    final identityRejected = documents.any(
      (d) =>
          d.reviewStatus == 'Rejected' &&
          const {
            'GhanaCard',
            'GhanaCardBack',
            'Selfie',
            'ProfilePhoto',
          }.contains(d.documentType),
    );
    return switch (application.status) {
      'Submitted' => ApplicationStatus.submitted,
      'UnderReview' => ApplicationStatus.underReview,
      'MoreInformationRequired' =>
        identityRejected
            ? ApplicationStatus.verificationFailed
            : ApplicationStatus.moreInfoRequired,
      'Approved' => ApplicationStatus.approved,
      'Rejected' => ApplicationStatus.rejected,
      _ => ApplicationStatus.draft,
    };
  }

  // ---- Uploads ------------------------------------------------------------
  //
  // Photos are picked from the device, uploaded to GRID and attached to the application.
  // The tile shows uploading/done/failed from the real outcome; failures are retryable.

  Future<void> addPortfolioUpload() async {
    final file = await _pickImage(ImageSource.gallery);
    if (file == null) return;
    _uploadCounter++;
    final item = UploadItem(
      id: 'portfolio-$_uploadCounter',
      label: 'Work photo $_uploadCounter',
      state: UploadState.uploading,
    );
    updateDraft(
      (draft) => draft.copyWith(portfolio: [...draft.portfolio, item]),
    );
    await _uploadAndAttach(
      item,
      file,
      purpose: 'portfolio',
      attach: _attachPortfolio,
    );
  }

  Future<void> addQualificationUpload(String label) async {
    final file = await _pickImage(ImageSource.gallery);
    if (file == null) return;
    _uploadCounter++;
    final item = UploadItem(
      id: 'certificate-$_uploadCounter',
      label: '$label $_uploadCounter',
      state: UploadState.uploading,
    );
    updateDraft(
      (draft) =>
          draft.copyWith(qualifications: [...draft.qualifications, item]),
    );
    await _uploadAndAttach(
      item,
      file,
      purpose: 'certificates',
      attach: (repo, key, file) => repo.addDocument(
        documentType: 'ProfessionalCertificate',
        storageKey: key,
        fileName: file.name,
        contentType: _contentTypeOf(file.name),
        sizeBytes: File(file.path).lengthSync(),
      ),
    );
  }

  /// Ghana Card front/back and a selfie, captured with the camera where available.
  Future<void> captureIdentity(String kind) async {
    final file = await _pickImage(
      kind == 'selfie' ? ImageSource.camera : ImageSource.camera,
    );
    if (file == null) return;
    _uploadCounter++;
    final item = UploadItem(
      id: 'identity-$kind-$_uploadCounter',
      label: kind,
      state: UploadState.uploading,
    );
    updateDraft(
      (draft) => switch (kind) {
        'front' => draft.copyWith(idFront: item),
        'back' => draft.copyWith(idBack: item),
        _ => draft.copyWith(selfie: item),
      },
    );
    final documentType = switch (kind) {
      'front' => 'GhanaCard',
      'back' => 'GhanaCardBack',
      _ => 'Selfie',
    };
    await _uploadAndAttach(
      item,
      file,
      purpose: 'identity',
      attach: (repo, key, file) => repo.addDocument(
        documentType: documentType,
        storageKey: key,
        fileName: file.name,
        contentType: _contentTypeOf(file.name),
        sizeBytes: File(file.path).lengthSync(),
      ),
    );
  }

  /// The EPA pest control licence; GRID can't approve pest control without it.
  Future<void> captureLicence() async {
    final file = await _pickImage(ImageSource.camera);
    if (file == null) return;
    _uploadCounter++;
    final item = UploadItem(
      id: 'licence-$_uploadCounter',
      label: 'EPA licence',
      state: UploadState.uploading,
    );
    updateDraft((draft) => draft.copyWith(licence: item));
    await _uploadAndAttach(
      item,
      file,
      purpose: 'certificates',
      attach: (repo, key, file) => repo.addDocument(
        documentType: 'EpaPestControlLicence',
        storageKey: key,
        fileName: file.name,
        contentType: _contentTypeOf(file.name),
        sizeBytes: File(file.path).lengthSync(),
      ),
    );
  }

  Future<void> retryUpload(String id) async {
    // The picked file is not retained across a failure, so a retry asks for the photo again.
    removeUpload(id);
    if (id.startsWith('portfolio-')) return addPortfolioUpload();
    if (id.startsWith('certificate-')) {
      return addQualificationUpload('Certificate');
    }
  }

  void removeUpload(String id) => updateDraft(
    (draft) => draft.copyWith(
      portfolio: draft.portfolio.where((item) => item.id != id).toList(),
      qualifications: draft.qualifications
          .where((item) => item.id != id)
          .toList(),
    ),
  );

  Future<XFile?> _pickImage(ImageSource source) async {
    try {
      return await _picker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 2000,
      );
    } on Object {
      // No camera/gallery on this device (or permission refused) — treat as a cancelled pick.
      return null;
    }
  }

  Future<void> _uploadAndAttach(
    UploadItem item,
    XFile file, {
    required String purpose,
    required Future<void> Function(
      ProviderRepository repo,
      String storageKey,
      XFile file,
    )
    attach,
  }) async {
    if (!ref.read(apiEnabledProvider)) {
      _markUpload(item.id, UploadState.done);
      return;
    }
    try {
      final repository = ref.read(providerRepositoryProvider);
      await _sync.push(OnboardingStep.details, state.draft);
      final bytes = await file.readAsBytes();
      final storageKey = await repository.uploadFile(
        purpose: purpose,
        fileName: file.name,
        contentType: _contentTypeOf(file.name),
        bytes: bytes,
      );
      await attach(repository, storageKey, file);
      _markUpload(item.id, UploadState.done);
    } on ApiException {
      _markUpload(item.id, UploadState.failed);
    }
  }

  Future<void> _attachPortfolio(
    ProviderRepository repo,
    String key,
    XFile file,
  ) => repo.addPortfolioItem(
    title: 'Completed work',
    storageKey: key,
    contentType: _contentTypeOf(file.name),
  );

  void _markUpload(String id, UploadState result) {
    UploadItem advance(UploadItem item) =>
        item.id == id ? item.copyWith(state: result, progress: 1) : item;
    updateDraft(
      (draft) => draft.copyWith(
        portfolio: draft.portfolio.map(advance).toList(),
        qualifications: draft.qualifications.map(advance).toList(),
        idFront: draft.idFront == null ? null : advance(draft.idFront!),
        idBack: draft.idBack == null ? null : advance(draft.idBack!),
        selfie: draft.selfie == null ? null : advance(draft.selfie!),
        licence: draft.licence == null ? null : advance(draft.licence!),
      ),
    );
  }

  static String _contentTypeOf(String fileName) {
    final name = fileName.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.heic')) return 'image/heic';
    if (name.endsWith('.pdf')) return 'application/pdf';
    return 'image/jpeg';
  }

  // ---- Submission ---------------------------------------------------------

  /// Checks the server's own view of completeness, so the review screen reflects what
  /// submission will actually accept rather than only local validation.
  Future<void> refreshReadiness() async {
    if (!ref.read(apiEnabledProvider)) return;
    try {
      final readiness = await _sync.readiness();
      state = state.copyWith(
        serverRequirements: readiness.missing,
        offline: false,
      );
    } on ApiException catch (error) {
      state = state.copyWith(offline: error.isOffline);
    }
  }

  /// Submits (or resubmits) the application. Guards against repeated taps.
  Future<void> submit() async {
    const submittable = {
      ApplicationStatus.draft,
      ApplicationStatus.moreInfoRequired,
      ApplicationStatus.verificationFailed,
    };
    if (state.submitting || !submittable.contains(state.status)) return;
    state = state.copyWith(submitting: true, submitFailed: false);

    if (!ref.read(apiEnabledProvider)) {
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      _setStatus(ApplicationStatus.underReview);
      state = state.copyWith(submitting: false);
      return;
    }

    try {
      // Flush anything still queued, accept the standards, then submit.
      final service = _sync;
      for (final step in OnboardingStep.values.where(
        state.pendingSync.contains,
      )) {
        await service.push(step, state.draft);
      }
      _rememberSyncIds(service);
      _savePending(const {});

      if (state.draft.agreedToStandards) await service.acceptStandards();
      await service.submit();

      _setStatus(ApplicationStatus.submitted);
      state = state.copyWith(
        submitting: false,
        pendingSync: const {},
        offline: false,
        submitFailed: false,
      );
    } on ApiException catch (error) {
      state = state.copyWith(
        submitting: false,
        submitFailed: true,
        offline: error.isOffline,
        serverRequirements: [(code: error.code, message: error.message)],
      );
    }
  }

  /// Demo-only: preview any application status without a backend.
  void setDemoStatus(ApplicationStatus status) => _setStatus(status);

  /// Called from the approved state to enter the app as a new provider.
  Future<void> enterApp() async {
    await ref
        .read(appControllerProvider.notifier)
        .completeOnboarding(asNewProvider: true);
  }

  /// Re-opens the section named in a "more information required" request or
  /// a failed verification. Keeps the application status so the provider
  /// resubmits from review once the fix is made.
  void resumeForCorrections(OnboardingStep step) => goToStep(step);

  void _setStatus(ApplicationStatus status) {
    state = state.copyWith(status: status);
    _preferences.setString(_statusKey, status.name);
  }

  Future<void> reset() async {
    await _preferences.remove(_draftKey);
    await _preferences.remove(_statusKey);
    await _preferences.remove(_pendingKey);
    await _preferences.remove(_offeringKey);
    await _preferences.remove(_accountReadyKey);
    // Signing out clears the tokens too, so a restart starts from a clean session.
    await ref.read(authRepositoryProvider).logout();
    state = const OnboardingState(
      draft: OnboardingDraft(),
      status: ApplicationStatus.draft,
    );
  }
}
