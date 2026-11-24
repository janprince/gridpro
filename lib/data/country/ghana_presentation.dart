import 'package:grid_professionals/data/country/country_config.dart';

/// Presentation details for a service category that the API has no opinion about.
///
/// The catalogue itself — which services exist, their sub-services, their ids — is server-driven.
/// This overlay only supplies how a category should *look and read* in the provider app, keyed by
/// the category slug so new server categories degrade gracefully to a tonal placeholder.
class ServicePresentation {
  const ServicePresentation({
    required this.sortOrder,
    this.displayName,
    this.imageAsset,
    this.pricingModel,
    this.delivery,
    this.experienceHint,
    this.summary,
  });

  /// Lower sorts first.
  final int sortOrder;

  /// Shorter, friendlier wording than the catalogue name where it helps.
  final String? displayName;
  final String? imageAsset;
  final PricingModel? pricingModel;
  final ServiceDelivery? delivery;

  /// Category-specific prompt on the experience step.
  final String? experienceHint;

  /// One line under the service name on the services step.
  final String? summary;
}

/// Keyed by the API's `ServiceCategory.slug`. Only these services are offered
/// in the provider app; any other category the API returns (plumbing and
/// electrical, until they launch) is left out.
const ghanaPresentation = <String, ServicePresentation>{
  'cleaning': ServicePresentation(
    sortOrder: 1,
    displayName: 'Home cleaning',
    summary: 'Homes and apartments — regular, deep and move-out cleans.',
    pricingModel: PricingModel.hourly,
    experienceHint:
        'e.g. I clean homes and apartments in East Legon, mostly deep '
        'cleans, and bring my own supplies.',
  ),
  'laundry': ServicePresentation(
    sortOrder: 2,
    summary: 'Wash, iron and dry cleaning, with pickup and delivery.',
    pricingModel: PricingModel.perItem,
    delivery: ServiceDelivery.both,
    experienceHint:
        'e.g. I run a laundry in Adenta with two machines and offer '
        'next-day pickup and delivery.',
  ),
  'ac-servicing': ServicePresentation(
    sortOrder: 3,
    summary: 'Split and window units: servicing, deep cleans, gas and repairs.',
    experienceHint:
        'e.g. I service split units across Airport and Cantonments and '
        'carry my own pressure washer and gauges.',
  ),
  'pest-control': ServicePresentation(
    sortOrder: 4,
    summary: 'Fumigation for mosquitoes, cockroaches, rodents and termites.',
    experienceHint:
        'e.g. EPA-licensed fumigator, mostly homes and estates in Tema, '
        'using approved products only.',
  ),
};
