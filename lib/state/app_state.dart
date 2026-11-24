import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final preferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);
final appControllerProvider = NotifierProvider<AppController, AppState>(
  AppController.new,
);

/// Where this phone is in the journey: signed in or not, through onboarding
/// or not. Everything about the provider's work lives in `work_state.dart`.
class AppState {
  const AppState({
    required this.isAuthenticated,
    required this.onboardingComplete,
    this.isNewProvider = false,
  });
  final bool isAuthenticated;
  final bool onboardingComplete;

  /// True when the account came through real onboarding. False means the
  /// demo, which runs on sample data and never talks to GRID.
  final bool isNewProvider;

  AppState copyWith({
    bool? isAuthenticated,
    bool? onboardingComplete,
    bool? isNewProvider,
  }) => AppState(
    isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    isNewProvider: isNewProvider ?? this.isNewProvider,
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
    );
  }

  /// The session can't be renewed. The application draft and status stay, so
  /// signing back in lands where the provider was.
  Future<void> sessionEnded() async {
    await _preferences.setBool('isAuthenticated', false);
    await _preferences.setBool('onboardingComplete', false);
    state = state.copyWith(isAuthenticated: false, onboardingComplete: false);
  }

  /// Forgets everything on this phone.
  Future<void> signOut() async {
    await _preferences.clear();
    state = const AppState(isAuthenticated: false, onboardingComplete: false);
  }
}
