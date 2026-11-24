import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';
import 'package:grid_professionals/core/widgets/app_widgets.dart';
import 'package:grid_professionals/core/models/models.dart';
import 'package:grid_professionals/state/work_state.dart';
import 'package:url_launcher/url_launcher.dart';

/// GRID's support line. Replace both before release if the number changes.
const supportPhone = '+233300000000';
const supportPhoneLabel = '030 000 0000';

const _answers = {
  'When do I get paid?':
      'An earning joins your balance when the customer confirms the job, or '
      'a day after you finish if they don\'t. GRID then pays your balance '
      'out to your payout account.',
  'How is the GRID fee worked out?':
      'GRID keeps a percentage of what the customer pays. Every request '
      'shows the fee and what you earn before you accept, and that amount '
      'doesn\'t change afterwards.',
  'What if a customer cancels?':
      'A customer can cancel until you set off. The job then shows as '
      'cancelled and nothing is owed either way. Once you\'re on the way, '
      'changes go through GRID support.',
};

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) => FocusPage(
    title: 'Help & support',
    onBack: context.canPop() ? () => context.pop() : null,
    children: [
      const ScreenIntro(
        title: 'How can we help?',
        subtitle: 'GRID support is open every day, 7 AM to 9 PM.',
      ),
      const SizedBox(height: 22),
      _ContactTile(
        icon: Icons.call_outlined,
        label: 'Call GRID support',
        detail: supportPhoneLabel,
        onTap: () async {
          var opened = false;
          try {
            opened = await launchUrl(Uri(scheme: 'tel', path: supportPhone));
          } on Object {
            opened = false;
          }
          if (!opened && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Call $supportPhoneLabel.')),
            );
          }
        },
      ),
      const SectionHeader('Report a problem'),
      MenuGroup(
        children: [
          MenuRow(
            icon: Icons.event_note_outlined,
            label: 'Problem with a job',
            onTap: () => context.push('/report-issue?about=job'),
          ),
          MenuRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Payment or payout',
            onTap: () => context.push('/report-issue?about=payout'),
          ),
          MenuRow(
            icon: Icons.person_outline_rounded,
            label: 'Issue with a customer',
            onTap: () => context.push('/report-issue?about=customer'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      MenuGroup(
        children: [
          MenuRow(
            icon: Icons.health_and_safety_outlined,
            label: 'I feel unsafe',
            danger: true,
            onTap: () => context.push('/report-issue?about=safety'),
          ),
        ],
      ),
      const SectionHeader('Common questions'),
      MenuGroup(
        children: [
          for (final entry in _answers.entries)
            MenuRow(
              icon: Icons.help_outline_rounded,
              label: entry.key,
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (context) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      4,
                      AppSpacing.gutter,
                      24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.key, style: AppText.title),
                        const SizedBox(height: 10),
                        Text(entry.value, style: AppText.bodyMuted),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ],
  );
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.detail,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    color: AppColors.surfaceSubtle,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
        const SizedBox(height: 14),
        Text(label, style: AppText.subtitle),
        const SizedBox(height: 2),
        Text(
          detail,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.caption,
        ),
      ],
    ),
  );
}

class ReportIssueScreen extends ConsumerStatefulWidget {
  const ReportIssueScreen({super.key, this.jobId, this.about});

  /// The job the report is about, when opened from one.
  final String? jobId;

  /// Preselects a reason: `job`, `payout`, `customer` or `safety`.
  final String? about;
  @override
  ConsumerState<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends ConsumerState<ReportIssueScreen> {
  late String? _reason = switch (widget.about) {
    'payout' => 'Payment or payout issue',
    'customer' => 'Customer not available',
    'safety' => 'Safety concern',
    'job' => 'Job different from the request',
    'service' => 'Add another service',
    _ => null,
  };
  final _details = TextEditingController();
  SupportTicket? _ticket;
  bool _showErrors = false;
  bool _sending = false;
  String? _failure;

  static const reasons = [
    'Customer not available',
    'Job different from the request',
    'Payment or payout issue',
    'Damaged or missing items',
    'Safety concern',
    'Add another service',
    'Something else',
  ];

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason == null || _details.text.trim().isEmpty) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() {
      _sending = true;
      _failure = null;
    });
    try {
      final ticket = await ref
          .read(gridRepositoryProvider)
          .reportProblem(
            reason: _reason!,
            details: _details.text.trim(),
            jobId: widget.jobId,
          );
      if (mounted) setState(() => _ticket = ticket);
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _sending = false;
          _failure = describeError(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = _ticket;
    if (ticket != null) {
      return FocusPage(
        onClose: () => context.pop(),
        actions: [PrimaryButton(label: 'Done', onPressed: () => context.pop())],
        children: [
          const SizedBox(height: 40),
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.successBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 38,
                color: AppColors.success,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ScreenIntro(
            title: 'We\'re on it',
            subtitle:
                'Ticket ${ticket.reference} is open. Support will call or '
                'message you on the number you signed in with.',
            center: true,
          ),
          if (_reason == 'Safety concern') ...[
            const SizedBox(height: 20),
            const StatusBanner(
              kind: StatusKind.danger,
              title: 'If you\'re in danger now',
              message:
                  'Leave if you can and call the police on 191 or 112. Then '
                  'call GRID support on $supportPhoneLabel.',
            ),
          ],
        ],
      );
    }
    return FocusPage(
      title: widget.about == 'service' ? 'Add a service' : 'Report a problem',
      onBack: () => context.pop(),
      actions: [
        PrimaryButton(
          label: 'Send report',
          busy: _sending,
          busyLabel: 'Sending',
          onPressed: _submit,
        ),
      ],
      children: [
        const Text(
          'Tell us what happened. A clear record helps us sort it out '
          'fairly for everyone.',
          style: AppText.bodyMuted,
        ),
        const SizedBox(height: 22),
        if (_failure != null) ...[
          InlineError(message: _failure!),
          const SizedBox(height: 14),
        ],
        SelectionRow(
          label: 'What\'s it about?',
          value: _reason,
          placeholder: 'Choose a reason',
          errorText: _showErrors && _reason == null ? 'Choose a reason.' : null,
          onTap: () async {
            final choice = await showOptionPicker<String>(
              context,
              title: 'What\'s it about?',
              options: reasons,
              labelOf: (reason) => reason,
              selected: _reason,
            );
            if (choice != null) setState(() => _reason = choice);
          },
        ),
        const SizedBox(height: 18),
        FormTextField(
          label: 'What happened?',
          controller: _details,
          maxLines: 5,
          hint: 'Include times, names and anything the customer said.',
          textCapitalization: TextCapitalization.sentences,
          errorText: _showErrors && _details.text.trim().isEmpty
              ? 'Add a few details.'
              : null,
          onChanged: (_) {
            if (_showErrors) setState(() {});
          },
        ),
      ],
    );
  }
}
