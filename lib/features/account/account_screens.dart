import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grid_professionals/core/models/models.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';
import 'package:grid_professionals/core/widgets/app_widgets.dart';
import 'package:grid_professionals/data/country/country_config.dart';
import 'package:grid_professionals/state/app_state.dart';
import 'package:grid_professionals/state/onboarding_state.dart';
import 'package:grid_professionals/state/work_state.dart';

void _say(BuildContext context, String message) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(message)));

/// Who the provider is, as customers see them, and everything they can set.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final pro = profile.value;
    final services = pro?.offerings
        .where((item) => item.active)
        .map(
          (item) =>
              item.service == ServiceKind.cleaning ? 'Cleaning' : 'Laundry',
        )
        .join(', ');

    return ColoredBox(
      color: AppColors.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          20,
          AppSpacing.gutter,
          28,
        ),
        children: [
          const Text('Profile', style: AppText.headline),
          const SizedBox(height: 20),
          if (profile.hasError && pro == null)
            RetryState(
              title: 'Could not load your profile',
              message: 'Check your connection and try again.',
              onRetry: () => ref.invalidate(profileProvider),
            )
          else
            _ProfileCard(profile: pro),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextLink(
                label: 'Edit profile',
                onPressed: () => context.push('/edit-profile'),
              ),
              TextLink(
                label: 'Availability',
                onPressed: () => context.push('/availability'),
              ),
            ],
          ),
          const SectionHeader('Your work', top: 24),
          MenuGroup(
            children: [
              MenuRow(
                icon: Icons.sell_outlined,
                label: 'Services',
                value: services == null
                    ? null
                    : services.isEmpty
                    ? 'Paused'
                    : services,
                onTap: () => context.push('/services'),
              ),
              MenuRow(
                icon: Icons.schedule_rounded,
                label: 'Availability',
                value: pro == null
                    ? null
                    : pro.online
                    ? 'Online'
                    : 'Offline',
                onTap: () => context.push('/availability'),
              ),
              MenuRow(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Payout account',
                value: pro == null
                    ? null
                    : pro.payout == null
                    ? 'Not set'
                    : pro.payout!.mobileMoney
                    ? 'MoMo'
                    : 'Bank',
                onTap: () => context.push('/payout-account'),
              ),
            ],
          ),
          const SectionHeader('Help'),
          MenuGroup(
            children: [
              MenuRow(
                icon: Icons.support_agent_rounded,
                label: 'Help & support',
                onTap: () => context.push('/support'),
              ),
              MenuRow(
                icon: Icons.flag_outlined,
                label: 'Report a problem',
                onTap: () => context.push('/report-issue'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          MenuGroup(
            children: [
              MenuRow(
                icon: Icons.logout_rounded,
                label: 'Log out',
                danger: true,
                onTap: () => _logOut(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text('GRID Pro · Version 1.0', style: AppText.caption),
          ),
        ],
      ),
    );
  }

  Future<void> _logOut(BuildContext context, WidgetRef ref) async {
    final online = ref.read(profileProvider).value?.online ?? false;
    final yes = await showConfirmationSheet(
      context,
      title: 'Log out of GRID Pro?',
      message: online
          ? 'You\'ll be taken offline, so no new requests reach you until '
                'you log back in.'
          : 'You won\'t receive new requests on this phone until you log '
                'back in.',
      confirmLabel: 'Log out',
    );
    if (!yes) return;
    // Nobody is watching this phone once it is signed out, so stop offers
    // going to it. Best effort: signing out must work with no connection.
    if (online) await ref.read(profileProvider.notifier).setOnline(false);
    await ref.read(onboardingControllerProvider.notifier).reset();
    await ref.read(appControllerProvider.notifier).signOut();
    if (context.mounted) context.go('/welcome');
  }
}

/// Who the provider is at a glance: avatar and name on the left, the three
/// numbers customers judge them by on the right.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});
  final ProviderProfile? profile;

  @override
  Widget build(BuildContext context) {
    final pro = profile;
    Widget stat(String value, String label) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: AppText.title.copyWith(fontFeatures: AppText.tabular),
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.caption.copyWith(color: AppColors.ink),
        ),
      ],
    );
    const rule = Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Divider(),
    );
    return AppCard(
      radius: AppRadius.xl,
      padding: const EdgeInsets.fromLTRB(16, 22, 20, 22),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InitialsAvatar(initials: pro?.initials ?? '', size: 84),
                const SizedBox(height: 12),
                Text(
                  pro?.ownerName ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title,
                ),
                const SizedBox(height: 2),
                Text(
                  pro == null
                      ? ''
                      : pro.business
                      ? pro.displayName
                      : 'Independent professional',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  pro?.phoneLabel ?? '',
                  style: AppText.caption.copyWith(
                    fontFeatures: AppText.tabular,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                stat(
                  pro?.rating == null
                      ? 'New'
                      : '★ ${pro!.rating!.toStringAsFixed(1)}',
                  'Rating',
                ),
                rule,
                stat('${pro?.completedJobs ?? 0}', 'Jobs done'),
                rule,
                stat(
                  '${pro?.memberSince ?? DateTime.now().year}',
                  'On GRID since',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Which services the provider takes and what they charge.
class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  List<ServiceOffering>? _offerings;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    final offerings = _offerings ?? const [];
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repository = ref.read(gridRepositoryProvider);
      for (final item in offerings) {
        await repository.saveOffering(item);
      }
      await ref.read(profileProvider.notifier).refresh();
      if (!mounted) return;
      _say(context, 'Services updated.');
      context.pop();
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = describeError(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final config = ref.watch(countryConfigProvider);
    if (profile.hasValue) _offerings ??= [...profile.value!.offerings];
    final offerings = _offerings;
    return FocusPage(
      title: 'Services',
      onBack: () => context.pop(),
      actions: [
        if (offerings != null && offerings.isNotEmpty)
          PrimaryButton(
            label: 'Save changes',
            busy: _saving,
            busyLabel: 'Saving',
            onPressed: _save,
          ),
      ],
      children: [
        if (offerings == null)
          profile.hasError
              ? RetryState(
                  title: 'Could not load your services',
                  message: 'Check your connection and try again.',
                  onRetry: () => ref.invalidate(profileProvider),
                )
              : const LoadingSkeleton(height: 180, radius: AppRadius.xl)
        else if (offerings.isEmpty)
          const EmptyState(
            title: 'No services yet',
            message: 'The services you applied with will show here.',
          )
        else ...[
          const Text(
            'GRID sets the price of every job and sends you requests for the '
            'services switched on here. Pause one any time.',
            style: AppText.bodyMuted,
          ),
          const SizedBox(height: 20),
          if (_error != null) ...[
            InlineError(message: _error!),
            const SizedBox(height: 14),
          ],
          for (final (index, item) in offerings.indexed) ...[
            ServiceHeroCard(
              service: item.service,
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      ServiceBadge(service: item.service, size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.service.label, style: AppText.subtitle),
                            Text(
                              item.active
                                  ? _earningsLine(config, item.service) ??
                                        'Taking requests'
                                  : 'Paused',
                              style: AppText.caption,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: item.active,
                        onChanged: (value) => setState(
                          () => offerings[index] = item.copyWith(active: value),
                        ),
                      ),
                    ],
                  ),
                  if (item.active) ...[
                    const SizedBox(height: 6),
                    SwitchRow(
                      title: 'Same-day requests',
                      subtitle: 'Jobs booked for today, at short notice.',
                      value: item.sameDay,
                      onChanged: (value) => setState(
                        () => offerings[index] = item.copyWith(sameDay: value),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 4),
          MenuGroup(
            children: [
              MenuRow(
                icon: Icons.add_circle_outline_rounded,
                label: 'Add a service',
                value: 'GRID reviews it first',
                onTap: () => context.push('/report-issue?about=service'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// "You earn GH₵ 153 – 714 a job", from GRID's prices less its fee.
  static String? _earningsLine(CountryConfig config, ServiceKind kind) {
    final rates = config.serviceById(kind.id)?.rates ?? const [];
    if (rates.isEmpty) return null;
    final earnings = [for (final r in rates) r.earning(config.feePercent)]
      ..sort();
    String money(double v) => '${config.currencySymbol} ${v.round()}';
    return earnings.first == earnings.last
        ? 'You earn ${money(earnings.first)} a job'
        : 'You earn ${money(earnings.first)}–${money(earnings.last)} a job';
  }
}

/// Hours, days, distance and whether requests come in at all.
class AvailabilityScreen extends ConsumerStatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  ConsumerState<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends ConsumerState<AvailabilityScreen> {
  WorkSettings? _draft;
  bool? _online;
  bool _saving = false;

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null) return;
    if (draft.workingDays.isEmpty) {
      _say(context, 'Choose at least one working day.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(gridRepositoryProvider).saveWorkSettings(draft);
      final profile = ref.read(profileProvider.notifier);
      final wasOnline = ref.read(profileProvider).value?.online;
      if (_online != null && _online != wasOnline) {
        final problem = await profile.setOnline(_online!);
        if (problem != null) {
          if (mounted) {
            setState(() {
              _saving = false;
              _online = wasOnline;
            });
            _say(context, problem);
          }
          return;
        }
      } else {
        await profile.refresh();
      }
      ref.invalidate(workSettingsProvider);
      if (mounted) context.pop();
    } on Object catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        _say(context, describeError(error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(workSettingsProvider);
    final profile = ref.watch(profileProvider).value;
    _draft ??= settings.value;
    _online ??= profile?.online;
    final draft = _draft;
    final online = _online ?? false;
    return FocusPage(
      title: 'Availability',
      onBack: () => context.pop(),
      actions: [
        if (draft != null)
          PrimaryButton(
            label: 'Save',
            busy: _saving,
            busyLabel: 'Saving',
            onPressed: _save,
          ),
      ],
      children: [
        if (draft == null)
          settings.hasError
              ? RetryState(
                  title: 'Could not load your hours',
                  message: 'Check your connection and try again.',
                  onRetry: () => ref.invalidate(workSettingsProvider),
                )
              : const LoadingSkeleton(height: 220, radius: AppRadius.lg)
        else ...[
          SwitchRow(
            title: 'Receive requests',
            subtitle: online
                ? 'You\'re online during your hours.'
                : 'You\'re offline. No new requests.',
            value: online,
            onChanged: (value) => setState(() => _online = value),
          ),
          const SizedBox(height: 24),
          ScheduleEditor(
            workingDays: draft.workingDays,
            startHour: draft.startHour,
            endHour: draft.endHour,
            onDaysChanged: (days) =>
                setState(() => _draft = draft.copyWith(workingDays: days)),
            onHoursChanged: (start, end) => setState(
              () => _draft = draft.copyWith(startHour: start, endHour: end),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: FieldLabel(label: 'How far you\'ll travel'),
              ),
              Text(
                '${draft.travelRadiusKm.round()} km',
                style: AppText.subtitle.copyWith(fontFeatures: AppText.tabular),
              ),
            ],
          ),
          Slider(
            value: draft.travelRadiusKm.clamp(5, 40),
            min: 5,
            max: 40,
            divisions: 7,
            label: '${draft.travelRadiusKm.round()} km',
            onChanged: (value) =>
                setState(() => _draft = draft.copyWith(travelRadiusKm: value)),
          ),
          const Text(
            'You\'re offered jobs in the areas below, and anything else '
            'within this distance.',
            style: AppText.caption,
          ),
          const SizedBox(height: 24),
          const FieldLabel(label: 'Areas you cover'),
          const SizedBox(height: 10),
          if (profile == null || profile.serviceAreas.isEmpty)
            const Text('No areas yet.', style: AppText.caption)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final area in profile.serviceAreas)
                  Chip(label: Text(area)),
              ],
            ),
          const SizedBox(height: 10),
          const Text(
            'To add or remove an area, contact GRID support.',
            style: AppText.caption,
          ),
        ],
      ],
    );
  }
}

/// The provider's own words to customers. Their name and business name were
/// verified by GRID, so those are shown but not editable here.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  TextEditingController? _about;
  bool _saving = false;

  @override
  void dispose() {
    _about?.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final problem = await ref
        .read(profileProvider.notifier)
        .saveDescription(_about!.text.trim());
    if (!mounted) return;
    setState(() => _saving = false);
    if (problem != null) {
      _say(context, problem);
    } else {
      _say(context, 'Profile saved.');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final pro = profile.value;
    if (pro != null) _about ??= TextEditingController(text: pro.description);
    return FocusPage(
      title: 'Edit profile',
      onBack: () => context.pop(),
      actions: [
        if (pro != null)
          PrimaryButton(
            label: 'Save changes',
            busy: _saving,
            busyLabel: 'Saving',
            onPressed: _save,
          ),
      ],
      children: [
        if (pro == null)
          profile.hasError
              ? RetryState(
                  title: 'Could not load your profile',
                  message: 'Check your connection and try again.',
                  onRetry: () => ref.invalidate(profileProvider),
                )
              : const LoadingSkeleton(height: 220, radius: AppRadius.lg)
        else ...[
          Center(child: InitialsAvatar(initials: pro.initials, size: 84)),
          const SizedBox(height: 28),
          FormTextField(
            label: 'Full name',
            initialValue: pro.ownerName,
            enabled: false,
            helper: 'Matches your Ghana Card. Contact support to change it.',
          ),
          if (pro.business) ...[
            const SizedBox(height: 18),
            FormTextField(
              label: 'Business name',
              initialValue: pro.displayName,
              enabled: false,
              helper: 'Checked by GRID. Contact support to change it.',
            ),
          ],
          const SizedBox(height: 18),
          FormTextField(
            label: 'About you',
            controller: _about,
            optional: true,
            maxLines: 4,
            maxLength: 300,
            hint:
                'What customers should know — your experience, what you bring.',
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ],
    );
  }
}
