import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grid_professionals/core/models/models.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';
import 'package:grid_professionals/core/widgets/app_widgets.dart';
import 'package:grid_professionals/features/onboarding/steps_about_you.dart';
import 'package:grid_professionals/features/onboarding/steps_getting_paid.dart';
import 'package:grid_professionals/features/onboarding/steps_trust.dart';
import 'package:grid_professionals/features/onboarding/steps_your_work.dart';
import 'package:grid_professionals/state/onboarding_state.dart';

/// Wizard host: renders the current step, validates on Continue, and keeps
/// every entry persisted through the onboarding controller.
class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key, this.returnToReview = false});

  /// When true the screen edits a single section and returns to review.
  final bool returnToReview;

  @override
  ConsumerState<OnboardingFlowScreen> createState() =>
      _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  bool _showErrors = false;

  OnboardingStep get _step {
    final index = ref
        .watch(onboardingControllerProvider)
        .draft
        .currentStep
        .clamp(0, OnboardingStep.values.length - 1);
    return OnboardingStep.values[index];
  }

  void _continue() {
    final controller = ref.read(onboardingControllerProvider.notifier);
    final state = ref.read(onboardingControllerProvider);
    final status = state.draft.statusOf(_step, controller.config);
    if (status != SectionStatus.complete) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() => _showErrors = false);
    // Save to GRID in the background; the local draft is already stored, so the provider is
    // never blocked on the network.
    unawaited(controller.syncStep(_step));

    if (widget.returnToReview) {
      context.go('/onboarding/review');
    } else if (_step == OnboardingStep.values.last) {
      context.go('/onboarding/review');
    } else {
      controller.nextStep();
    }
  }

  void _back() {
    setState(() => _showErrors = false);
    if (widget.returnToReview) {
      context.go('/onboarding/review');
    } else if (_step == OnboardingStep.values.first) {
      context.go('/onboarding');
    } else {
      ref.read(onboardingControllerProvider.notifier).previousStep();
    }
  }

  String _errorMessage(OnboardingStep step) => switch (step) {
    OnboardingStep.providerType =>
      'Choose how you work so we can tailor the next questions.',
    OnboardingStep.details =>
      'Fill in the highlighted details above to continue.',
    OnboardingStep.services =>
      'Pick your main service and at least one thing you offer.',
    OnboardingStep.experience =>
      'Add your years of experience and a short description of your work.',
    OnboardingStep.serviceArea =>
      'Choose your region and at least one area you cover.',
    OnboardingStep.availability => 'Select at least one working day.',
    OnboardingStep.pricing =>
      'Enter your pricing so customers know what to expect.',
    OnboardingStep.payout =>
      'Complete your payout details so we know where to send your earnings.',
    OnboardingStep.portfolio =>
      'Add at least one photo of your work. Certificates are optional.',
    OnboardingStep.identity =>
      'Capture your Ghana Card (front and back) and a selfie to continue.',
  };

  @override
  Widget build(BuildContext context) {
    final step = _step;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Column(
            children: [
              // Back, progress and the escape hatch share one quiet row, so
              // the step title is the first thing read.
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 0),
                child: Row(
                  children: [
                    NavChip(onPressed: _back),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 3,
                      child: widget.returnToReview
                          ? const SizedBox.shrink()
                          : OnboardingProgress(step: step),
                    ),
                    const SizedBox(width: 6),
                    if (!widget.returnToReview)
                      // Shrinks rather than overflows at the largest text
                      // sizes, where the label alone can outrun the row.
                      Flexible(
                        flex: 2,
                        child: TextButton(
                          onPressed: () => context.go('/onboarding'),
                          child: const Text(
                            'Save & exit',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      layoutBuilder: (currentChild, previousChildren) => Stack(
                        alignment: Alignment.topCenter,
                        children: [...previousChildren, ?currentChild],
                      ),
                      child: SingleChildScrollView(
                        key: ValueKey(step),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.gutter,
                          24,
                          AppSpacing.gutter,
                          32,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!widget.returnToReview) ...[
                              OnboardingStepEyebrow(step: step),
                              const SizedBox(height: 10),
                            ],
                            Text(step.title, style: AppText.headline),
                            const SizedBox(height: 20),
                            _StepBody(step: step, showErrors: _showErrors),
                            if (_showErrors) ...[
                              const SizedBox(height: 16),
                              InlineError(message: _errorMessage(step)),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const ScrollFade(),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomActionBar(
          label: widget.returnToReview
              ? 'Save changes'
              : step == OnboardingStep.values.last
              ? 'Review application'
              : 'Continue',
          onPressed: _continue,
        ),
      ),
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({required this.step, required this.showErrors});
  final OnboardingStep step;
  final bool showErrors;

  @override
  Widget build(BuildContext context) => switch (step) {
    OnboardingStep.providerType => const ProviderTypeStep(),
    OnboardingStep.details => DetailsStep(showErrors: showErrors),
    OnboardingStep.services => const ServicesStep(),
    OnboardingStep.experience => ExperienceStep(showErrors: showErrors),
    OnboardingStep.serviceArea => ServiceAreaStep(showErrors: showErrors),
    OnboardingStep.availability => const AvailabilityStep(),
    OnboardingStep.pricing => PricingStep(showErrors: showErrors),
    OnboardingStep.payout => PayoutStep(showErrors: showErrors),
    OnboardingStep.portfolio => const PortfolioStep(),
    OnboardingStep.identity => const IdentityStep(),
  };
}
