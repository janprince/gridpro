import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grid_professionals/core/models/models.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';
import 'package:grid_professionals/core/widgets/app_widgets.dart';
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
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1100), _continue);
  }

  void _continue() {
    if (!mounted) return;
    final app = ref.read(appControllerProvider);
    final onboarding = ref.read(onboardingControllerProvider);
    if (app.onboardingComplete && app.isAuthenticated) {
      context.go('/jobs');
    } else if (onboarding.status != ApplicationStatus.draft) {
      context.go('/application-status');
    } else if (app.isAuthenticated || onboarding.hasDraftInProgress) {
      context.go('/onboarding');
    } else {
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.forest,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GridMark(light: true),
                    const Spacer(),
                    const Text(
                      'Trusted jobs for\ntrusted professionals.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        height: 1.12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Manage your work. Build your reputation. '
                      'Grow your income.',
                      style: TextStyle(
                        color: AppColors.mint,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const Spacer(),
                    const LinearProgressIndicator(
                      color: Colors.white,
                      backgroundColor: Color(0xFF315F52),
                      semanticsLabel: 'Opening GRID Pro',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _trades = [
    ('assets/images/services/electrical.jpg', 'Electrician at work'),
    ('assets/images/services/plumbing.jpg', 'Plumber at work'),
    ('assets/images/services/cleaning.jpg', 'Cleaner at work'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: AppPage(
        children: [
          const SizedBox(height: 8),
          const GridMark(),
          const SizedBox(height: 32),
          Row(
            children: [
              for (final (asset, label) in _trades)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: (asset, label) == _trades.last ? 0 : 10,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: Image.asset(
                        asset,
                        height: 120,
                        fit: BoxFit.cover,
                        semanticLabel: label,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Your skills, working\nfor you.',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 12),
          const Text(
            'GRID Pro connects skilled professionals and small service '
            'businesses across Ghana with customers who need them.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 15.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          const _ValuePoint(
            icon: Icons.verified_user_outlined,
            text: 'Verified profile that customers can trust',
          ),
          const _ValuePoint(
            icon: Icons.receipt_long_outlined,
            text: 'Quotes, job records and evidence in one place',
          ),
          const _ValuePoint(
            icon: Icons.account_balance_wallet_outlined,
            text: 'Payouts straight to Mobile Money or bank',
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () => context.push('/signup'),
            child: const Text('Get started'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => context.push('/login'),
            child: const Text('Log in'),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => context.push('/login?demo=true'),
              child: const Text('Explore the demo app'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ValuePoint extends StatelessWidget {
  const _ValuePoint({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Icon(icon, size: AppSizes.iconSm, color: AppColors.forest),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14.5, height: 1.4),
          ),
        ),
      ],
    ),
  );
}

/// Phone entry for both account creation and returning-provider login.
class PhoneEntryScreen extends StatefulWidget {
  const PhoneEntryScreen({
    super.key,
    required this.isSignup,
    this.demo = false,
  });
  final bool isSignup;
  final bool demo;

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;
    final flow = widget.isSignup ? 'signup' : (widget.demo ? 'demo' : 'login');
    context.push('/otp?flow=$flow&phone=${Uri.encodeComponent(_phone.text)}');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: AppPage(
          children: [
            Text(
              widget.isSignup ? 'Create your account' : 'Welcome back',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 10),
            Text(
              widget.isSignup
                  ? 'Enter your phone number. We\'ll text you a code to '
                        'confirm it — no password needed.'
                  : 'Use the phone number linked to your provider profile.',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 28),
            PhoneNumberField(
              controller: _phone,
              autofocus: true,
              helper: 'Ghana numbers only for now.',
              onSubmitted: (_) => _continue(),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _continue, child: const Text('Send code')),
            const SizedBox(height: 18),
            const StatusBanner(
              kind: StatusKind.neutral,
              title: 'Your number stays private',
              message:
                  'We only use it to secure your account. GRID will never ask '
                  'for your Mobile Money PIN.',
            ),
          ],
        ),
      ),
    ),
    resizeToAvoidBottomInset: true,
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

  void _resend() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('New code sent to +233 ${widget.phone}.')),
    );
    _startCountdown();
  }

  Future<void> _verify() async {
    if (_code.text.length != 6) {
      setState(
        () => _error =
            'Enter all 6 digits from the SMS. In this demo, '
            'any 6 digits work.',
      );
      return;
    }
    setState(() {
      _error = null;
      _verifying = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final app = ref.read(appControllerProvider.notifier);
    await app.authenticate();
    if (!mounted) return;
    switch (widget.flow) {
      case 'signup':
        ref.read(onboardingControllerProvider.notifier).setPhone(widget.phone);
        context.go('/onboarding/flow');
      case 'demo':
        await app.completeOnboarding();
        if (mounted) context.go('/jobs');
      default:
        // Returning provider in this demo build: straight to the dashboard.
        await app.completeOnboarding();
        if (mounted) context.go('/jobs');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: SafeArea(
      child: AppPage(
        children: [
          Text(
            'Confirm your number',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 10),
          Text(
            'Enter the 6-digit code we sent to +233 ${widget.phone}.',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofocus: true,
            textAlign: TextAlign.center,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 12,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••••',
              errorText: _error,
              errorMaxLines: 2,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _verifying ? null : _verify,
            child: _verifying
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppColors.muted,
                      semanticsLabel: 'Verifying code',
                    ),
                  )
                : const Text('Confirm code'),
          ),
          const SizedBox(height: 12),
          Center(
            child: _resendSeconds > 0
                ? Text(
                    'You can resend the code in '
                    '00:${_resendSeconds.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                : TextButton(
                    onPressed: _resend,
                    child: const Text('Resend code'),
                  ),
          ),
          Center(
            child: TextButton(
              onPressed: () => context.pop(),
              child: const Text('Change phone number'),
            ),
          ),
        ],
      ),
    ),
  );
}
