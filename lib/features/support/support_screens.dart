import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';
import 'package:grid_professionals/core/widgets/app_widgets.dart';
import 'package:grid_professionals/state/app_state.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});
  @override
  Widget build(BuildContext context) => AppPage(
    children: [
      Text('Support', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 8),
      const Text(
        'GRID support is here for job, safety and payout issues.',
        style: TextStyle(color: AppColors.muted),
      ),
      const SizedBox(height: 20),
      AppCard(
        color: AppColors.forest,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.headset_mic, color: Colors.white, size: 34),
            const SizedBox(height: 14),
            const Text(
              'Contact GRID Support',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Typical mock response: under 10 minutes',
              style: TextStyle(color: AppColors.mint),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.forest,
              ),
              onPressed: () {},
              child: const Text('Start support chat'),
            ),
          ],
        ),
      ),
      const SectionHeader('Report an issue'),
      SupportActionCard(
        icon: Icons.work_history_outlined,
        title: 'Job issue',
        subtitle: 'Scope, access, materials or completion.',
        onTap: () => context.push('/report-issue'),
      ),
      const SizedBox(height: 10),
      SupportActionCard(
        icon: Icons.payments_outlined,
        title: 'Payment or payout',
        subtitle: 'Incorrect, delayed or missing payout.',
        onTap: () => context.push('/report-issue'),
      ),
      const SizedBox(height: 10),
      SupportActionCard(
        icon: Icons.gavel_outlined,
        title: 'Customer dispute',
        subtitle: 'Create a record and share evidence.',
        onTap: () => context.push('/report-issue'),
      ),
      const SizedBox(height: 10),
      SupportActionCard(
        icon: Icons.health_and_safety_outlined,
        title: 'Safety concern',
        subtitle: 'Leave unsafe areas and report immediately.',
        onTap: () => context.push('/report-issue'),
        danger: true,
      ),
      const SectionHeader('Other help'),
      SupportActionCard(
        icon: Icons.phone_android,
        title: 'Technical help',
        subtitle: 'Login, notifications or app issues.',
        onTap: () {},
      ),
      const SizedBox(height: 10),
      SupportActionCard(
        icon: Icons.quiz_outlined,
        title: 'Frequently asked questions',
        subtitle: 'Jobs, quotes, ratings and payouts.',
        onTap: () {},
      ),
      const SizedBox(height: 10),
      SupportActionCard(
        icon: Icons.chat_outlined,
        title: 'WhatsApp fallback',
        subtitle: 'Mock external support option.',
        onTap: () {},
      ),
      const SizedBox(height: 18),
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: const BorderSide(color: AppColors.danger),
        ),
        onPressed: () => context.push('/report-issue'),
        icon: const Icon(Icons.emergency_outlined),
        label: const Text('Emergency support'),
      ),
    ],
  );
}

class ReportIssueScreen extends ConsumerStatefulWidget {
  const ReportIssueScreen({super.key});
  @override
  ConsumerState<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends ConsumerState<ReportIssueScreen> {
  String? _reason;
  final _details = TextEditingController();
  bool _submitted = false;
  static const reasons = [
    'Customer not available',
    'Customer changed scope',
    'Unsafe location',
    'Payment issue',
    'Wrong job details',
    'Customer complaint',
    'Materials problem',
    'Cannot complete job',
    'Other',
  ];
  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_submitted ? 'Report received' : 'Report an issue'),
    ),
    body: _submitted
        ? AppPage(
            children: [
              const SizedBox(height: 50),
              const Icon(Icons.task_alt, size: 80, color: AppColors.teal),
              const SizedBox(height: 20),
              Text(
                'Your report has been recorded.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              const Text(
                'Mock ticket GRID-2841 is now open. Support will review your notes and evidence.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 26),
              FilledButton(
                onPressed: () => context.go('/support'),
                child: const Text('Return to support'),
              ),
            ],
          )
        : AppPage(
            children: [
              const Text(
                'Choose the closest reason. Detailed records help GRID resolve issues fairly.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _reason,
                decoration: const InputDecoration(labelText: 'Reason'),
                items: [
                  for (final item in reasons)
                    DropdownMenuItem(value: item, child: Text(item)),
                ],
                onChanged: (value) => setState(() => _reason = value),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _details,
                minLines: 5,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'What happened?',
                  hintText:
                      'Include relevant times, scope changes and communication.',
                ),
              ),
              const SizedBox(height: 14),
              const PhotoUploadTile(label: 'Add supporting photo (mock)'),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () {
                  if (_reason == null || _details.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Choose a reason and add details.'),
                      ),
                    );
                    return;
                  }
                  ref
                      .read(appControllerProvider.notifier)
                      .submitSupportTicket(_reason!, _details.text.trim());
                  setState(() => _submitted = true);
                },
                child: const Text('Submit report'),
              ),
            ],
          ),
  );
}
