import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grid_professionals/core/widgets/app_widgets.dart';
import 'package:grid_professionals/features/account/account_screens.dart';
import 'package:grid_professionals/features/auth/auth_screens.dart';
import 'package:grid_professionals/features/earnings/earnings_screens.dart';
import 'package:grid_professionals/features/home/home_screen.dart';
import 'package:grid_professionals/features/jobs/job_screens.dart';
import 'package:grid_professionals/features/main/main_shell.dart';
import 'package:grid_professionals/features/onboarding/application_status.dart';
import 'package:grid_professionals/features/onboarding/onboarding_flow.dart';
import 'package:grid_professionals/features/onboarding/onboarding_hub.dart';
import 'package:grid_professionals/features/onboarding/onboarding_review.dart';
import 'package:grid_professionals/features/support/support_screens.dart';

final routerProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(
        path: '/login',
        builder: (_, state) => PhoneEntryScreen(
          isSignup: false,
          demo: state.uri.queryParameters['demo'] == 'true',
        ),
      ),
      GoRoute(
        path: '/signup',
        builder: (_, _) => const PhoneEntryScreen(isSignup: true),
      ),
      GoRoute(
        path: '/otp',
        builder: (_, state) => OtpScreen(
          flow: state.uri.queryParameters['flow'] ?? 'login',
          phone: state.uri.queryParameters['phone'] ?? '',
        ),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => const OnboardingHubScreen(),
      ),
      GoRoute(
        path: '/onboarding/flow',
        builder: (_, state) => OnboardingFlowScreen(
          returnToReview: state.uri.queryParameters['from'] == 'review',
        ),
      ),
      GoRoute(
        path: '/onboarding/review',
        builder: (_, _) => const OnboardingReviewScreen(),
      ),
      GoRoute(
        path: '/application-status',
        builder: (_, _) => const ApplicationStatusScreen(),
      ),
      // Legacy paths from the previous flow.
      GoRoute(path: '/apply', redirect: (_, _) => '/signup'),
      GoRoute(path: '/verification', redirect: (_, _) => '/application-status'),
      GoRoute(path: '/setup', redirect: (_, _) => '/application-status'),
      // Paths from earlier versions of the app.
      GoRoute(path: '/schedule', redirect: (_, _) => '/jobs'),
      GoRoute(path: '/profile', redirect: (_, _) => '/account'),
      GoRoute(path: '/payouts', redirect: (_, _) => '/payout-account'),
      GoRoute(path: '/job-history', redirect: (_, _) => '/jobs'),
      ShellRoute(
        builder: (_, _, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          GoRoute(path: '/jobs', builder: (_, _) => const JobsScreen()),
          GoRoute(path: '/earnings', builder: (_, _) => const EarningsScreen()),
          GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
        ],
      ),
      GoRoute(
        path: '/availability',
        builder: (_, _) => const AvailabilityScreen(),
      ),
      GoRoute(path: '/services', builder: (_, _) => const ServicesScreen()),
      GoRoute(
        path: '/payout-account',
        builder: (_, _) => const PayoutAccountScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (_, _) => const EditProfileScreen(),
      ),
      GoRoute(path: '/support', builder: (_, _) => const SupportScreen()),
      GoRoute(
        path: '/report-issue',
        builder: (_, state) => ReportIssueScreen(
          jobId: state.uri.queryParameters['job'],
          about: state.uri.queryParameters['about'],
        ),
      ),
      GoRoute(
        path: '/job/:id/offer',
        builder: (_, state) =>
            JobOfferScreen(jobId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/job/:id',
        builder: (_, state) =>
            JobDetailScreen(jobId: state.pathParameters['id']!),
      ),
    ],
    errorBuilder: (context, state) => FocusPage(
      title: 'Not found',
      actions: [
        PrimaryButton(label: 'Go home', onPressed: () => context.go('/home')),
      ],
      children: const [
        EmptyState(
          title: 'This screen isn\'t available',
          message: 'It may have moved in an update.',
        ),
      ],
    ),
  ),
);
