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

  /// Hourly rate (cleaning).
  hourly,

  /// Price per item or per kg (laundry).
  perItem,
}

/// Whether providers in a category travel to customers, work from fixed
/// premises (e.g. a laundry shop), or commonly do both.
enum ServiceDelivery { travels, fixedPremises, both }

/// One thing customers buy, at GRID's price, e.g. "Standard clean · 2 bedrooms".
class PackageRate {
  const PackageRate({
    required this.group,
    required this.name,
    required this.price,
    this.unitLabel,
  });

  final String group;
  final String name;

  /// What the customer pays, per [unitLabel] when there is one.
  final double price;
  final String? unitLabel;

  /// What the provider keeps after GRID's [feePercent].
  double earning(double feePercent) =>
      (price * (100 - feePercent) / 100 * 100).roundToDouble() / 100;
}

class ServiceDefinition {
  const ServiceDefinition({
    required this.id,
    required this.name,
    required this.subServices,
    required this.pricingModel,
    this.rates = const [],
    this.imageAsset,
    this.delivery = ServiceDelivery.travels,
    this.experienceHint,
    this.summary,
  });

  final String id;
  final String name;

  /// One line under the name on the services step.
  final String? summary;

  /// Photo asset for selection cards; null falls back to a tonal placeholder.
  final String? imageAsset;
  final List<String> subServices;
  final PricingModel pricingModel;
  final ServiceDelivery delivery;

  /// GRID's packages for this service; empty until the catalogue loads.
  final List<PackageRate> rates;

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
    this.feePercent = 15,
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

  /// GRID's share of each job; the provider earns the rest.
  final double feePercent;

  /// Replaces the catalogue portion with what the server returned, keeping the market's
  /// phone, currency and payout configuration.
  CountryConfig withCatalogue({
    List<ServiceDefinition>? services,
    List<RegionDefinition>? regions,
    double? feePercent,
  }) => CountryConfig(
    code: code,
    name: name,
    dialCode: dialCode,
    currencySymbol: currencySymbol,
    currencyCode: currencyCode,
    localPhoneDigits: localPhoneDigits,
    idDocumentName: idDocumentName,
    services: services ?? this.services,
    regions: regions ?? this.regions,
    mobileMoneyProviders: mobileMoneyProviders,
    banks: banks,
    feePercent: feePercent ?? this.feePercent,
  );

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
