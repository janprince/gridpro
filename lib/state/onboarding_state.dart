import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grid_professionals/core/models/onboarding_models.dart';
import 'package:grid_professionals/data/country/country_config.dart';
import 'package:grid_professionals/data/country/ghana_config.dart';
import 'package:grid_professionals/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Active market configuration. Swap this provider to launch other countries.
final countryConfigProvider = Provider<CountryConfig>((ref) => ghanaConfig);

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
  });

  final OnboardingDraft draft;
  final ApplicationStatus status;
  final bool submitting;
  final bool submitFailed;

  bool get hasDraftInProgress =>
      status == ApplicationStatus.draft &&
      (draft.providerType != null || draft.fullName.isNotEmpty);

  OnboardingState copyWith({
    OnboardingDraft? draft,
    ApplicationStatus? status,
    bool? submitting,
    bool? submitFailed,
  }) => OnboardingState(
    draft: draft ?? this.draft,
    status: status ?? this.status,
    submitting: submitting ?? this.submitting,
    submitFailed: submitFailed ?? this.submitFailed,
  );
}

class OnboardingController extends Notifier<OnboardingState> {
  static const _draftKey = 'onboardingDraft';
  static const _statusKey = 'applicationStatus';

  late SharedPreferences _preferences;
  int _uploadCounter = 0;

  @override
  OnboardingState build() {
    _preferences = ref.read(preferencesProvider);
    return OnboardingState(draft: _restoreDraft(), status: _restoreStatus());
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

  // ---- Mock uploads -------------------------------------------------------
  //
  // Uploads are simulated locally. Every third portfolio upload fails on its
  // first attempt so the failure/retry experience stays demonstrable.

  Future<void> addPortfolioUpload() => _addUpload(
    listOf: (draft) => draft.portfolio,
    write: (draft, items) => draft.copyWith(portfolio: items),
    label: 'Work photo',
    failFirstAttempt: (_uploadCounter + 1) % 3 == 0,
  );

  Future<void> addQualificationUpload(String label) => _addUpload(
    listOf: (draft) => draft.qualifications,
    write: (draft, items) => draft.copyWith(qualifications: items),
    label: label,
    failFirstAttempt: false,
  );

  Future<void> retryUpload(String id) async {
    UploadItem mark(UploadItem item) => item.id == id
        ? item.copyWith(state: UploadState.uploading, progress: 0)
        : item;
    updateDraft(
      (draft) => draft.copyWith(
        portfolio: draft.portfolio.map(mark).toList(),
        qualifications: draft.qualifications.map(mark).toList(),
      ),
    );
    await _animateUpload(id, failFirstAttempt: false);
  }

  void removeUpload(String id) => updateDraft(
    (draft) => draft.copyWith(
      portfolio: draft.portfolio.where((item) => item.id != id).toList(),
      qualifications: draft.qualifications
          .where((item) => item.id != id)
          .toList(),
    ),
  );

  Future<void> _addUpload({
    required List<UploadItem> Function(OnboardingDraft draft) listOf,
    required OnboardingDraft Function(
      OnboardingDraft draft,
      List<UploadItem> items,
    )
    write,
    required String label,
    required bool failFirstAttempt,
  }) async {
    _uploadCounter++;
    final item = UploadItem(
      id: 'upload-$_uploadCounter',
      label: '$label $_uploadCounter',
      state: UploadState.uploading,
    );
    updateDraft((draft) => write(draft, [...listOf(draft), item]));
    await _animateUpload(item.id, failFirstAttempt: failFirstAttempt);
  }

  Future<void> _animateUpload(
    String id, {
    required bool failFirstAttempt,
  }) async {
    for (var tick = 1; tick <= 4; tick++) {
      await Future<void>.delayed(const Duration(milliseconds: 260));
      final failNow = failFirstAttempt && tick == 3;
      UploadItem advance(UploadItem item) {
        if (item.id != id || item.state != UploadState.uploading) return item;
        if (failNow) return item.copyWith(state: UploadState.failed);
        return item.copyWith(
          progress: tick / 4,
          state: tick == 4 ? UploadState.done : UploadState.uploading,
        );
      }

      updateDraft(
        (draft) => draft.copyWith(
          portfolio: draft.portfolio.map(advance).toList(),
          qualifications: draft.qualifications.map(advance).toList(),
          idFront: draft.idFront == null ? null : advance(draft.idFront!),
          idBack: draft.idBack == null ? null : advance(draft.idBack!),
          selfie: draft.selfie == null ? null : advance(draft.selfie!),
        ),
      );
      if (failNow) return;
    }
  }

  /// Simulated identity capture: Ghana Card front/back and selfie.
  Future<void> captureIdentity(String kind) async {
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
    await _animateUpload(item.id, failFirstAttempt: false);
  }

  // ---- Submission ---------------------------------------------------------

  /// Submits (or resubmits) the application. Guards against repeated taps;
  /// the simulated network call moves the status to under review.
  Future<void> submit() async {
    const submittable = {
      ApplicationStatus.draft,
      ApplicationStatus.moreInfoRequired,
      ApplicationStatus.verificationFailed,
    };
    if (state.submitting || !submittable.contains(state.status)) return;
    state = state.copyWith(submitting: true, submitFailed: false);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    _setStatus(ApplicationStatus.underReview);
    state = state.copyWith(submitting: false);
    ref.read(appControllerProvider.notifier).submitApplication();
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
    state = const OnboardingState(
      draft: OnboardingDraft(),
      status: ApplicationStatus.draft,
    );
  }
}
