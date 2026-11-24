import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grid_professionals/core/models/models.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';
import 'package:grid_professionals/core/widgets/app_widgets.dart';
import 'package:grid_professionals/data/api/api_exception.dart';
import 'package:grid_professionals/state/api_providers.dart';
import 'package:grid_professionals/state/app_state.dart';
import 'package:grid_professionals/state/onboarding_state.dart';

/// Decides where the app opens based on persisted auth and application state,
/// so a provider always resumes where they left off.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  // Local startup is brief; platform storage and server reconciliation each
  // get a deadline. Public catalogue requests never gate navigation.
  static const _splashDuration = Duration(milliseconds: 600);
  static const _restoreTimeout = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final minimumDisplay = Future<void>.delayed(_splashDuration);
    if (ref.read(apiEnabledProvider)) {
      unawaited(_warmCatalogue());
      try {
        final session = await ref
            .read(sessionStoreProvider)
            .load()
            .timeout(_restoreTimeout);
        if (!mounted) return;
        if (session != null) {
          await ref
              .read(onboardingControllerProvider.notifier)
              .refreshFromServer(timeout: _restoreTimeout);
        }
      } on Object {
        // Storage/network failures must not trap a provider on the splash.
        // Existing local draft and application state decide the destination.
      }
    }
    await minimumDisplay;
    _continue();
  }

  Future<void> _warmCatalogue() async {
    try {
      await ref.read(catalogueProvider.future);
    } on Object {
      // countryConfigProvider supplies bundled services while offline.
    }
  }

  void _continue() {
    if (!mounted) return;
    final app = ref.read(appControllerProvider);
    final onboarding = ref.read(onboardingControllerProvider);
    if (app.onboardingComplete && app.isAuthenticated) {
      context.go('/home');
    } else if (onboarding.status != ApplicationStatus.draft) {
      context.go('/application-status');
    } else if (app.isAuthenticated || onboarding.hasDraftInProgress) {
      context.go('/onboarding');
    } else {
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: AppColors.navyDeep,
    ),
    child: Scaffold(
      backgroundColor: AppColors.navyDeep,
      body: Stack(
        children: [
          const GridTexture(opacity: 1.2, cell: 32),
          const Center(child: GridMark(light: true)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 48,
            child: Center(
              child: SizedBox(
                width: 56,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: const LinearProgressIndicator(
                    minHeight: 3,
                    color: AppColors.amber,
                    backgroundColor: Color(0x33FFFFFF),
                    semanticsLabel: 'Opening GRID Pro',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
    ),
    child: Scaffold(
      backgroundColor: AppColors.navyDeep,
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        const GridTexture(cell: 30),
                        SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.gutter,
                              16,
                              AppSpacing.gutter,
                              28,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const GridMark(light: true, compact: true),
                                const SizedBox(height: 32),
                                const Expanded(child: _ProductPreview()),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      30,
                      AppSpacing.gutter,
                      12,
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const ScreenIntro(
                            title: 'Get booked for home services.',
                            display: true,
                            subtitle:
                                'Cleaning, laundry, AC servicing and pest '
                                'control near you. Paid after every job.',
                          ),
                          const SizedBox(height: 28),
                          PrimaryButton(
                            label: 'Get started',
                            onPressed: () => context.push('/signup'),
                          ),
                          const SizedBox(height: 10),
                          SecondaryButton(
                            label: 'Log in',
                            onPressed: () => context.push('/login'),
                          ),
                          // Sample data for development and design reviews;
                          // never in a release build.
                          if (kDebugMode) ...[
                            const SizedBox(height: 6),
                            TextButton(
                              onPressed: () => context.push('/login?demo=true'),
                              child: const Text('Explore the demo'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Two job cards as they appear in the app, overlapping on the navy hero.
/// Shows the product instead of describing it.
class _ProductPreview extends StatelessWidget {
  const _ProductPreview();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 330),
        child: SizedBox(
          height: 236,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 28,
                child: Transform.rotate(
                  angle: -0.035,
                  child: const _PreviewCard(
                    service: ServiceKind.laundry,
                    time: 'Today · 4:00 PM',
                    title: 'Wash & iron',
                    meta: 'Airport Residential · 4.8 km',
                    price: 'GH₵ 165.00',
                    status: 'New request',
                    kind: StatusKind.actionRequired,
                  ),
                ),
              ),
              Positioned(
                top: 108,
                left: 28,
                right: 0,
                child: Transform.rotate(
                  angle: 0.025,
                  child: const _PreviewCard(
                    service: ServiceKind.cleaning,
                    time: 'Tomorrow · 9:00 AM',
                    title: 'Deep cleaning',
                    meta: 'East Legon · 3 bedrooms',
                    price: 'GH₵ 420.00',
                    status: 'Accepted',
                    kind: StatusKind.success,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.service,
    required this.time,
    required this.title,
    required this.meta,
    required this.price,
    required this.status,
    required this.kind,
  });
  final ServiceKind service;
  final String time;
  final String title;
  final String meta;
  final String price;
  final String status;
  final StatusKind kind;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      boxShadow: const [
        BoxShadow(
          color: Color(0x40000000),
          blurRadius: 30,
          offset: Offset(0, 14),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                time,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption,
              ),
            ),
            StatusPill(label: status, kind: kind),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            ServiceBadge(service: service, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.subtitle,
                  ),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(price, style: AppText.amount.copyWith(fontSize: 14)),
          ],
        ),
      ],
    ),
  );
}

/// Phone entry for both account creation and returning-provider login.
class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({
    super.key,
    required this.isSignup,
    this.demo = false,
  });
  final bool isSignup;
  final bool demo;

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final _phone = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final invalid = ghanaPhoneValidator(_phone.text);
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }
    final flow = widget.isSignup ? 'signup' : (widget.demo ? 'demo' : 'login');
    final target = '/otp?flow=$flow&phone=${Uri.encodeComponent(_phone.text)}';

    if (!ref.read(apiEnabledProvider) || widget.demo) {
      context.push(target);
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
      await ref.read(authRepositoryProvider).requestOtp('+233$digits');
      if (mounted) context.push(target);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => FocusPage(
    title: widget.isSignup ? 'Create your account' : 'Log in',
    onBack: () => context.pop(),
    footnote: const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shield_outlined, size: 15, color: AppColors.muted),
        SizedBox(width: 7),
        Flexible(
          child: Text(
            'GRID will never ask for your Mobile Money PIN.',
            style: AppText.caption,
          ),
        ),
      ],
    ),
    actions: [
      PrimaryButton(
        label: 'Send code',
        busy: _sending,
        busyLabel: 'Sending code',
        onPressed: _continue,
      ),
    ],
    children: [
      PhoneHeroField(
        controller: _phone,
        autofocus: true,
        errorText: _error,
        onSubmitted: (_) => _continue(),
      ),
      const SizedBox(height: 16),
      Text(
        widget.isSignup
            ? 'We\'ll text you a 6-digit code to confirm it\'s yours.'
            : 'Use the number linked to your GRID Pro account.',
        textAlign: TextAlign.center,
        style: AppText.bodyMuted,
      ),
    ],
  );
}

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.flow, required this.phone});
  final String flow;
  final String phone;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _code = TextEditingController();
  String? _error;
  bool _verifying = false;
  int _resendSeconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _resendSeconds = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _resendSeconds--;
        if (_resendSeconds <= 0) timer.cancel();
      });
    });
  }

  Future<void> _resend() async {
    _startCountdown();
    if (!ref.read(apiEnabledProvider) || widget.flow == 'demo') {
      _notify('New code sent to +233 ${widget.phone}.');
      return;
    }
    // The API has no dedicated resend route; requesting again issues a fresh code.
    try {
      await ref.read(authRepositoryProvider).requestOtp(_e164);
      if (mounted) _notify('New code sent to +233 ${widget.phone}.');
    } on ApiException catch (error) {
      if (mounted) _notify(error.message);
    }
  }

  void _notify(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  String get _e164 => '+233${widget.phone.replaceAll(RegExp(r'\D'), '')}';

  Future<void> _verify() async {
    if (_code.text.length != 6) {
      setState(() => _error = 'Enter all 6 digits from the SMS.');
      return;
    }
    setState(() {
      _error = null;
      _verifying = true;
    });

    final app = ref.read(appControllerProvider.notifier);

    if (!ref.read(apiEnabledProvider) || widget.flow == 'demo') {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      await app.authenticate();
      if (!mounted) return;
      if (widget.flow == 'signup') {
        ref.read(onboardingControllerProvider.notifier).setPhone(widget.phone);
        context.go('/onboarding/flow');
      } else {
        await app.completeOnboarding();
        if (mounted) context.go('/home');
      }
      return;
    }

    try {
      final session = await ref
          .read(authRepositoryProvider)
          .verifyOtp(phoneNumber: _e164, code: _code.text);
      if (!mounted) return;
      await app.authenticate();
      if (!mounted) return;

      final onboarding = ref.read(onboardingControllerProvider.notifier);
      onboarding.setPhone(widget.phone);

      // A user who already owns a provider account resumes wherever their application stands.
      if (session.providerAccountId != null) {
        await onboarding.refreshFromServer();
        if (!mounted) return;
        final status = ref.read(onboardingControllerProvider).status;
        if (status == ApplicationStatus.approved) {
          await app.completeOnboarding(asNewProvider: true);
          if (mounted) context.go('/home');
        } else if (status == ApplicationStatus.draft) {
          context.go('/onboarding');
        } else {
          context.go('/application-status');
        }
        return;
      }
      context.go('/onboarding/flow');
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _verifying = false;
        });
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) => FocusPage(
    title: 'Verify your number',
    onBack: () => context.pop(),
    actions: [
      PrimaryButton(
        label: 'Confirm code',
        busy: _verifying,
        busyLabel: 'Verifying code',
        onPressed: _verify,
      ),
    ],
    children: [
      ScreenIntro(
        title: 'Enter the 6-digit code',
        subtitle: 'Sent by SMS to +233 ${widget.phone}',
      ),
      const SizedBox(height: 28),
      OtpCodeField(
        controller: _code,
        hasError: _error != null,
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        onCompleted: (_) => _verify(),
      ),
      if (_error != null) ...[
        const SizedBox(height: 12),
        InlineError(message: _error!),
      ],
      const SizedBox(height: 22),
      Row(
        children: [
          Expanded(
            child: _resendSeconds > 0
                ? Text(
                    'You can resend the code in '
                    '0:${_resendSeconds.toString().padLeft(2, '0')}',
                    style: AppText.caption.copyWith(
                      fontSize: 13.5,
                      fontFeatures: AppText.tabular,
                    ),
                  )
                : Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _resend,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 40),
                      ),
                      child: const Text('Resend code'),
                    ),
                  ),
          ),
          TextButton(
            onPressed: () => context.pop(),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 40),
            ),
            child: const Text('Change number'),
          ),
        ],
      ),
    ],
  );
}
