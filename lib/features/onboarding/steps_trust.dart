import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grid_professionals/core/models/models.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';
import 'package:grid_professionals/core/widgets/app_widgets.dart';
import 'package:grid_professionals/state/onboarding_state.dart';

class PortfolioStep extends ConsumerWidget {
  const PortfolioStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingControllerProvider).draft;
    final controller = ref.read(onboardingControllerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photos of finished work help customers choose you. Add at least '
          'one — clear before-and-after shots work best.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        Text('Work photos', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            AddUploadTile(
              label: 'Add photo',
              onTap: controller.addPortfolioUpload,
            ),
            for (final item in draft.portfolio)
              UploadTile(
                item: item,
                onRetry: () => controller.retryUpload(item.id),
                onRemove: () => controller.removeUpload(item.id),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Licences and certificates',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Optional, but they strengthen your application — for example an '
          'Energy Commission licence for electricians.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            AddUploadTile(
              label: 'Add certificate',
              icon: Icons.workspace_premium_outlined,
              onTap: () => controller.addQualificationUpload('Certificate'),
            ),
            for (final item in draft.qualifications)
              UploadTile(
                item: item,
                onRetry: () => controller.retryUpload(item.id),
                onRemove: () => controller.removeUpload(item.id),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Uploads are simulated in this demo build — no files leave your '
          'device.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class IdentityStep extends ConsumerWidget {
  const IdentityStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingControllerProvider).draft;
    final controller = ref.read(onboardingControllerProvider.notifier);
    final config = ref.watch(countryConfigProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verification keeps the network safe for customers and '
          'professionals. You\'ll need your ${config.idDocumentName} and '
          'good lighting.',
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        const StatusBanner(
          kind: StatusKind.neutral,
          title: 'Your ID is only used for verification',
          message:
              'It is never shown to customers and is handled according to '
              'data protection rules.',
        ),
        const SizedBox(height: 20),
        _CaptureRow(
          title: '${config.idDocumentName} — front',
          subtitle: 'The side with your photo.',
          item: draft.idFront,
          onCapture: () => controller.captureIdentity('front'),
        ),
        _CaptureRow(
          title: '${config.idDocumentName} — back',
          subtitle: 'The side with the barcode.',
          item: draft.idBack,
          onCapture: () => controller.captureIdentity('back'),
        ),
        _CaptureRow(
          title: 'Selfie',
          subtitle: 'So we can match your face to your ID.',
          item: draft.selfie,
          onCapture: () => controller.captureIdentity('selfie'),
        ),
        const SizedBox(height: 8),
        Text(
          'Captures are simulated in this demo build.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _CaptureRow extends StatelessWidget {
  const _CaptureRow({
    required this.title,
    required this.subtitle,
    required this.item,
    required this.onCapture,
  });

  final String title;
  final String subtitle;
  final UploadItem? item;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    final state = item?.state;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 3),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 12),
            switch (state) {
              null => OutlinedButton(
                onPressed: onCapture,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Capture'),
              ),
              UploadState.uploading => const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  semanticsLabel: 'Uploading capture',
                ),
              ),
              UploadState.failed => OutlinedButton(
                onPressed: onCapture,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  side: const BorderSide(color: AppColors.danger),
                  foregroundColor: AppColors.danger,
                ),
                child: const Text('Retry'),
              ),
              UploadState.done => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: 4),
                  TextButton(onPressed: onCapture, child: const Text('Retake')),
                ],
              ),
            },
          ],
        ),
      ),
    );
  }
}
