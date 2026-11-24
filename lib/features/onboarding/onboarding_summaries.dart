import 'package:grid_professionals/core/models/models.dart';
import 'package:grid_professionals/data/country/country_config.dart';

/// Short human-readable summary of what a section currently holds, shown on
/// the application hub and the review screen. Payout details are masked.
String? sectionSummary(
  OnboardingDraft draft,
  CountryConfig config,
  OnboardingStep step,
) {
  switch (step) {
    case OnboardingStep.providerType:
      return switch (draft.providerType) {
        ProviderType.individual => 'Independent professional',
        ProviderType.business => 'Small business',
        null => null,
      };
    case OnboardingStep.details:
      final name = draft.isBusiness && draft.businessName.trim().isNotEmpty
          ? draft.businessName.trim()
          : draft.fullName.trim();
      return name.isEmpty ? null : name;
    case OnboardingStep.services:
      final names = [
        for (final id in draft.serviceIds) ?config.serviceById(id)?.name,
      ];
      if (names.isEmpty) return null;
      final subs = draft.subServices.length;
      final chosen = names.join(', ');
      return subs == 0 ? chosen : '$chosen · $subs skills';
    case OnboardingStep.experience:
      if (draft.yearsExperience == null) return null;
      final years = draft.yearsExperience!;
      return years == 0 ? 'Less than a year' : '$years+ years';
    case OnboardingStep.serviceArea:
      if (draft.region == null) return null;
      if (draft.towns.isEmpty) return draft.region;
      final first = draft.towns.take(2).join(', ');
      final more = draft.towns.length - 2;
      return more > 0 ? '$first +$more more' : first;
    case OnboardingStep.availability:
      if (draft.workingDays.isEmpty) return null;
      return '${draft.workingDays.length} days a week';
    case OnboardingStep.pricing:
      if (draft.serviceIds.isEmpty) return null;
      final keep = 100 - config.feePercent;
      return 'You keep ${keep.toStringAsFixed(keep % 1 == 0 ? 0 : 1)}% of each job';
    case OnboardingStep.payout:
      return switch (draft.payoutType) {
        PayoutType.mobileMoney when draft.momoNumber.isNotEmpty =>
          'Mobile Money ${maskedNumber(draft.momoNumber)}',
        PayoutType.bank when draft.bankAccountNumber.isNotEmpty =>
          '${draft.bankName ?? 'Bank'} ${maskedNumber(draft.bankAccountNumber)}',
        _ => null,
      };
    case OnboardingStep.portfolio:
      final photos = draft.portfolio
          .where((item) => item.state == UploadState.done)
          .length;
      final certs = draft.qualifications
          .where((item) => item.state == UploadState.done)
          .length;
      if (photos == 0 && certs == 0) return null;
      final parts = [
        if (photos > 0) '$photos photo${photos == 1 ? '' : 's'}',
        if (certs > 0) '$certs certificate${certs == 1 ? '' : 's'}',
      ];
      return parts.join(' · ');
    case OnboardingStep.identity:
      final done = [
        draft.idFront,
        draft.idBack,
        draft.selfie,
      ].where((item) => item?.state == UploadState.done).length;
      return done == 0 ? null : '$done of 3 captures done';
  }
}

/// Shows only the last four digits of a phone or account number.
String maskedNumber(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length <= 4) return '•••• $digits';
  return '•••• ${digits.substring(digits.length - 4)}';
}
