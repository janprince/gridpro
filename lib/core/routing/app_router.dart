import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grid_professionals/core/widgets/app_widgets.dart';
import 'package:grid_professionals/features/auth/auth_screens.dart';
import 'package:grid_professionals/features/earnings/earnings_screens.dart';
import 'package:grid_professionals/features/jobs/job_screens.dart';
import 'package:grid_professionals/features/jobs/jobs_dashboard.dart';
import 'package:grid_professionals/features/main/main_shell.dart';
import 'package:grid_professionals/features/onboarding/application_status.dart';
import 'package:grid_professionals/features/onboarding/onboarding_flow.dart';
import 'package:grid_professionals/features/onboarding/onboarding_hub.dart';
import 'package:grid_professionals/features/onboarding/onboarding_review.dart';
import 'package:grid_professionals/features/profile/profile_screens.dart';
import 'package:grid_professionals/features/quote/quote_screens.dart';
import 'package:grid_professionals/features/schedule/schedule_screens.dart';
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
      ShellRoute(
        builder: (_, _, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/jobs', builder: (_, _) => const JobsDashboard()),
          GoRoute(path: '/schedule', builder: (_, _) => const ScheduleScreen()),
          GoRoute(path: '/earnings', builder: (_, _) => const EarningsScreen()),
          GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
          GoRoute(path: '/support', builder: (_, _) => const SupportScreen()),
        ],
      ),
      GoRoute(
        path: '/availability',
        builder: (_, _) => const AvailabilitySettingsScreen(),
      ),
      GoRoute(path: '/payouts', builder: (_, _) => const PayoutDetailsScreen()),
      GoRoute(
        path: '/job-history',
        builder: (_, _) => const JobHistoryScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (_, _) => const EditProfileScreen(),
      ),
      GoRoute(path: '/portfolio', builder: (_, _) => const PortfolioScreen()),
      GoRoute(
        path: '/performance',
        builder: (_, _) => const PerformanceScreen(),
      ),
      GoRoute(path: '/training', builder: (_, _) => const TrainingScreen()),
      GoRoute(
        path: '/report-issue',
        builder: (_, _) => const ReportIssueScreen(),
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
      GoRoute(
        path: '/journey/:id',
        builder: (_, state) =>
            JourneyScreen(jobId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/inspection/:id',
        builder: (_, state) =>
            InspectionScreen(jobId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/quote/:id',
        builder: (_, state) =>
            QuoteBuilderScreen(jobId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/quote-preview/:id',
        builder: (_, state) =>
            QuotePreviewScreen(jobId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/quote-awaiting/:id',
        builder: (_, state) =>
            QuoteAwaitingScreen(jobId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/quote-approved/:id',
        builder: (_, state) =>
            QuoteApprovedScreen(jobId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/work/:id',
        builder: (_, state) =>
            WorkInProgressScreen(jobId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/complete/:id',
        builder: (_, state) =>
            CompletionScreen(jobId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/payment/:id',
        builder: (_, state) =>
            PaymentStatusScreen(jobId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/receipt/:id',
        builder: (_, state) =>
            ReceiptScreen(jobId: state.pathParameters['id']!),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Something went wrong')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: EmptyStateCard(
          icon: Icons.error_outline,
          title: 'Screen unavailable',
          message:
              state.error?.toString() ??
              'The requested screen could not be loaded.',
          action: 'Return to jobs',
          onAction: () => context.go('/jobs'),
        ),
      ),
    ),
  ),
);
