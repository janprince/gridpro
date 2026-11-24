import 'package:grid_professionals/core/models/models.dart';
import 'package:grid_professionals/data/api/api_exception.dart';
import 'package:grid_professionals/data/api/catalogue_repository.dart';
import 'package:grid_professionals/data/api/provider_repository.dart';

/// Pushes one completed onboarding section to GRID.
///
/// The local draft stays the working copy: every method here is best-effort and throws
/// [ApiException] on failure so the caller can queue the section and retry later. The provider
/// account is created lazily on the first section that needs it, because the API requires a
/// display name that only exists once the details step is filled in.
class OnboardingSyncService {
  OnboardingSyncService(this._provider, this._catalogue);

  final ProviderRepository _provider;
  final CatalogueRepository _catalogue;

  /// Cached so a resumed session does not recreate server-side rows.
  bool accountReady = false;
  String? offeringId;

  /// True when the draft holds enough to create the account.
  bool canSync(OnboardingDraft draft) =>
      draft.providerType != null && _displayName(draft).isNotEmpty;

  Future<void> push(OnboardingStep step, OnboardingDraft draft) async {
    if (!canSync(draft)) return;
    await _ensureAccount(draft);

    switch (step) {
      case OnboardingStep.providerType:
      case OnboardingStep.details:
        await _pushAccount(draft);
      case OnboardingStep.services:
      case OnboardingStep.pricing:
        await _pushOffering(draft);
      case OnboardingStep.experience:
        await _pushExperience(draft);
      case OnboardingStep.serviceArea:
        await _pushServiceAreas(draft);
      case OnboardingStep.availability:
        await _pushAvailability(draft);
      case OnboardingStep.payout:
        await _pushPayout(draft);
      case OnboardingStep.portfolio:
      case OnboardingStep.identity:
        // Uploads reach the server as they happen; nothing batched to replay here.
        break;
    }

    await _provider.setCurrentStep(step.index + 1);
  }

  Future<void> _ensureAccount(OnboardingDraft draft) async {
    if (accountReady) return;
    try {
      final existing = await _provider.getAccount();
      if (existing != null) {
        accountReady = true;
        return;
      }
    } on ApiException catch (error) {
      // Anything other than "no account yet" is a real failure worth surfacing.
      if (error.code != 'providers.account_not_found' &&
          error.statusCode != 404) {
        rethrow;
      }
    }

    await _provider.createAccount(
      accountType: draft.isBusiness ? 'Business' : 'Individual',
      displayName: _displayName(draft),
      email: draft.email.isEmpty ? null : draft.email,
    );
    accountReady = true;
  }

  Future<void> _pushAccount(OnboardingDraft draft) async {
    await _provider.updateAccount(
      displayName: _displayName(draft),
      yearsOfExperience: draft.yearsExperience ?? 0,
      legalName: draft.isBusiness ? draft.businessName.trim() : null,
      description: draft.experienceSummary.trim().isEmpty
          ? null
          : draft.experienceSummary.trim(),
      email: draft.email.trim().isEmpty ? null : draft.email.trim(),
      city: _cityFor(draft),
      primaryArea: draft.towns.isEmpty ? null : draft.towns.first,
      deliveryMode: switch (draft.delivery) {
        ServiceDelivery.fixedPremises => 'FixedPremises',
        ServiceDelivery.both => 'Both',
        _ => 'TravelsToCustomer',
      },
      premisesAddress: draft.premisesAddress.trim().isEmpty
          ? null
          : draft.premisesAddress.trim(),
    );
  }

  Future<void> _pushExperience(OnboardingDraft draft) async {
    await _provider.updateExperience(
      mainSkill: draft.primaryServiceId,
      secondarySkills: draft.subServices.isEmpty
          ? null
          : draft.subServices.join(', '),
      toolsNotes: draft.toolsEquipment.trim().isEmpty
          ? null
          : draft.toolsEquipment.trim(),
      experienceDescription: draft.experienceSummary.trim().isEmpty
          ? null
          : draft.experienceSummary.trim(),
      yearsOperating: draft.yearsExperience,
    );
  }

  /// One offering per chosen service. GRID sets prices, so offerings carry no rates; a service
  /// the provider unticked is switched off rather than deleted, keeping its history.
  Future<void> _pushOffering(OnboardingDraft draft) async {
    final chosen = <String, String>{
      for (final slug in draft.serviceIds)
        if (_catalogue.serviceIdBySlug[slug] != null)
          _catalogue.serviceIdBySlug[slug]!: slug,
    };
    if (chosen.isEmpty) return;

    final existing = {
      for (final o in await _provider.getOfferings())
        o['serviceCategoryId'] as String: o['id'] as String,
    };

    for (final MapEntry(key: categoryId, value: slug) in chosen.entries) {
      final skills = draft.subServices
          .where((s) => _catalogue.skillsBySlug[slug]?.contains(s) ?? false)
          .toList();
      final body = <String, dynamic>{
        'serviceCategoryId': categoryId,
        'customServiceName': null,
        'description': skills.isEmpty ? null : skills.join(', '),
        'supportsEmergency': draft.emergency,
        'supportsSameDay': draft.sameDay,
        'isActive': true,
      };
      final id = existing[categoryId];
      if (id != null) {
        await _provider.updateOffering(id, body);
      } else {
        existing[categoryId] = await _provider.createOffering(body);
      }
    }

    for (final MapEntry(key: categoryId, value: id) in existing.entries) {
      if (chosen.containsKey(categoryId)) continue;
      await _provider.updateOffering(id, {
        'serviceCategoryId': categoryId,
        'isActive': false,
      });
    }
    offeringId = existing[chosen.keys.first];
  }

  Future<void> _pushServiceAreas(OnboardingDraft draft) async {
    final selected = <String, String>{
      for (final town in draft.towns)
        if (_catalogue.areaIdByName[town] != null)
          town: _catalogue.areaIdByName[town]!,
    };

    final existing = await _provider.getServiceAreas();
    final existingIds = {
      for (final area in existing)
        area['serviceAreaId'] as String: area['id'] as String,
    };

    for (final entry in existingIds.entries) {
      if (!selected.containsValue(entry.key)) {
        await _provider.removeServiceArea(entry.value);
      }
    }
    for (final areaId in selected.values) {
      if (existingIds.containsKey(areaId)) continue;
      await _provider.addServiceArea(
        serviceAreaId: areaId,
        maximumTravelDistanceKm: draft.travelsToCustomers
            ? draft.travelRadiusKm
            : null,
        supportsEmergency: draft.emergency,
        supportsSameDay: draft.sameDay,
      );
    }
  }

  Future<void> _pushAvailability(OnboardingDraft draft) async {
    const dayNames = {
      'Mon': 'Monday',
      'Tue': 'Tuesday',
      'Wed': 'Wednesday',
      'Thu': 'Thursday',
      'Fri': 'Friday',
      'Sat': 'Saturday',
      'Sun': 'Sunday',
    };
    final rules = [
      for (final entry in dayNames.entries)
        {
          'dayOfWeek': entry.value,
          'startTime': _time(draft.startHour),
          'endTime': _time(draft.endHour),
          'isAvailable': draft.workingDays.contains(entry.key),
        },
    ];
    await _provider.setAvailability(rules);
  }

  Future<void> _pushPayout(OnboardingDraft draft) async {
    switch (draft.payoutType) {
      case PayoutType.mobileMoney:
        if (draft.momoNumber.isEmpty || draft.momoName.isEmpty) return;
        await _provider.addPayoutMethod(
          methodType: 'MobileMoney',
          providerName: switch (draft.momoProviderId) {
            'mtn' => 'MTN Mobile Money',
            'telecel' => 'Telecel Cash',
            'at' => 'AT Money',
            _ => 'Mobile Money',
          },
          accountName: draft.momoName.trim(),
          accountNumber: draft.momoNumber.replaceAll(RegExp(r'\D'), ''),
        );
      case PayoutType.bank:
        if (draft.bankAccountNumber.isEmpty || draft.bankName == null) return;
        await _provider.addPayoutMethod(
          methodType: 'BankAccount',
          providerName: draft.bankName!,
          accountName: draft.bankAccountName.trim(),
          accountNumber: draft.bankAccountNumber.trim(),
        );
      case null:
        return;
    }
  }

  Future<void> acceptStandards() => _provider.acceptStandards();

  Future<Readiness> readiness() => _provider.getReadiness();

  Future<void> submit() => _provider.submitApplication();

  static String _time(int hour) => '${hour.toString().padLeft(2, '0')}:00:00';

  static String _displayName(OnboardingDraft draft) =>
      draft.isBusiness && draft.businessName.trim().isNotEmpty
      ? draft.businessName.trim()
      : draft.fullName.trim();

  /// The API models a city plus an area; the app collects towns, so the first town's city is
  /// the closest honest answer available without another lookup.
  static String? _cityFor(OnboardingDraft draft) =>
      draft.region == 'Greater Accra' ? 'Accra' : draft.region;
}
