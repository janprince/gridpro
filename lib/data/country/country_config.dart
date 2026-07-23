/// Country-agnostic configuration models for provider onboarding.
///
/// All localized data (services, regions, payout rails, phone rules) lives in
/// a [CountryConfig] so additional African markets can be added without
/// touching flow logic or widgets.
library;

/// How a provider charges for a service category.
enum PricingModel {
  /// Call-out/inspection fee, then a quote per job (trades).
  calloutQuote,

  /// Hourly rate (cleaning, gardening).
  hourly,

  /// Price per item or per kg (laundry).
  perItem,
}

/// Whether providers in a category travel to customers, work from fixed
/// premises (e.g. a laundry shop), or commonly do both.
enum ServiceDelivery { travels, fixedPremises, both }

class ServiceDefinition {
  const ServiceDefinition({
    required this.id,
    required this.name,
    required this.subServices,
    required this.pricingModel,
    this.imageAsset,
    this.delivery = ServiceDelivery.travels,
    this.experienceHint,
  });

  final String id;
  final String name;

  /// Photo asset for selection cards; null falls back to a tonal placeholder.
  final String? imageAsset;
  final List<String> subServices;
  final PricingModel pricingModel;
  final ServiceDelivery delivery;

  /// Category-specific prompt shown on the experience step.
  final String? experienceHint;
}

class RegionDefinition {
  const RegionDefinition({required this.name, required this.towns});
  final String name;
  final List<String> towns;
}

enum PayoutType { mobileMoney, bank }

class MobileMoneyProvider {
  const MobileMoneyProvider({required this.id, required this.name});
  final String id;
  final String name;
}

class CountryConfig {
  const CountryConfig({
    required this.code,
    required this.name,
    required this.dialCode,
    required this.currencySymbol,
    required this.currencyCode,
    required this.localPhoneDigits,
    required this.idDocumentName,
    required this.services,
    required this.regions,
    required this.mobileMoneyProviders,
    required this.banks,
  });

  final String code;
  final String name;

  /// e.g. "+233".
  final String dialCode;

  /// e.g. "GH₵".
  final String currencySymbol;
  final String currencyCode;

  /// Length of the national number without the leading zero (Ghana: 9).
  final int localPhoneDigits;

  /// The national identity document used for verification (Ghana Card).
  final String idDocumentName;

  final List<ServiceDefinition> services;
  final List<RegionDefinition> regions;
  final List<MobileMoneyProvider> mobileMoneyProviders;
  final List<String> banks;

  ServiceDefinition? serviceById(String? id) {
    if (id == null) return null;
    for (final service in services) {
      if (service.id == id) return service;
    }
    return null;
  }

  RegionDefinition? regionByName(String? name) {
    if (name == null) return null;
    for (final region in regions) {
      if (region.name == name) return region;
    }
    return null;
  }
}
