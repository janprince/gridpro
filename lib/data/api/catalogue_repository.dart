import 'package:grid_professionals/data/api/api_client.dart';
import 'package:grid_professionals/data/country/country_config.dart';
import 'package:grid_professionals/data/country/ghana_presentation.dart';

/// The GRID catalogue, mapped onto the shapes the onboarding UI already speaks.
///
/// Service categories are hierarchical on the server: top-level rows are the primary services a
/// provider picks and their children are the sub-services. Presentation the API has no opinion
/// about — photography, the experience prompt, how pricing is worded — comes from
/// [ghanaPresentation], keyed by category slug.
class Catalogue {
  const Catalogue({
    required this.services,
    required this.regions,
    this.feePercent,
  });

  final List<ServiceDefinition> services;
  final List<RegionDefinition> regions;

  /// GRID's share of each job, from the booking catalogue.
  final double? feePercent;
}

class CatalogueRepository {
  CatalogueRepository(this._client);

  final ApiClient _client;

  /// Server id for each primary service, keyed by slug — needed to create an offering.
  final Map<String, String> serviceIdBySlug = {};

  /// Skills under each primary service, keyed by slug.
  final Map<String, List<String>> skillsBySlug = {};

  /// Server id for each service area, keyed by area name.
  final Map<String, String> areaIdByName = {};

  Future<Catalogue> load() async {
    final categories = (await _client.get<List<dynamic>>(
      '/service-categories',
    )).cast<Map<String, dynamic>>();
    final areas = (await _client.get<List<dynamic>>(
      '/service-areas',
    )).cast<Map<String, dynamic>>();
    // GRID's prices, which the earnings step shows less the fee.
    final booking = await _client.get<Map<String, dynamic>>(
      '/service-catalogue',
    );
    final rates = <String, List<PackageRate>>{
      for (final section in (booking['sections'] as List).cast<Map>())
        for (final service in (section['services'] as List).cast<Map>())
          service['slug'] as String: [
            for (final p in (service['packages'] as List).cast<Map>())
              PackageRate(
                group: p['group'] as String,
                name: p['name'] as String,
                price: (p['price'] as num).toDouble(),
                unitLabel: p['unitLabel'] as String?,
              ),
          ],
    };

    final services = <ServiceDefinition>[];
    for (final parent in categories.where(
      (c) => c['parentCategoryId'] == null,
    )) {
      final slug = parent['slug'] as String;
      final id = parent['id'] as String;
      serviceIdBySlug[slug] = id;
      // Services still being prepared (no prices yet) aren't offered to providers.
      if (parent['isLaunched'] == false) continue;

      final subServices = [
        for (final child in categories.where(
          (c) => c['parentCategoryId'] == id,
        ))
          child['name'] as String,
      ];
      skillsBySlug[slug] = subServices;

      // GRID Pro offers a curated set of services; the catalogue may hold more.
      final look = ghanaPresentation[slug];
      if (look == null) continue;
      services.add(
        ServiceDefinition(
          id: slug,
          name: look.displayName ?? parent['name'] as String,
          imageAsset: look.imageAsset,
          subServices: subServices,
          rates: rates[slug] ?? const [],
          // The curated model wins; the server's default is the fallback for anything new.
          pricingModel:
              look.pricingModel ??
              _pricingModelFor(parent['defaultPricingMode'] as String?),
          delivery: look.delivery ?? ServiceDelivery.travels,
          experienceHint: look.experienceHint,
          summary: look.summary,
        ),
      );
    }

    // Areas are flat on the server; the picker groups them by region.
    final grouped = <String, List<String>>{};
    for (final area in areas) {
      final name = area['name'] as String;
      areaIdByName[name] = area['id'] as String;
      grouped.putIfAbsent(area['region'] as String, () => []).add(name);
    }
    final regions = [
      for (final entry in grouped.entries)
        RegionDefinition(name: entry.key, towns: entry.value..sort()),
    ]..sort((a, b) => a.name.compareTo(b.name));

    services.sort((a, b) {
      final left = ghanaPresentation[a.id]?.sortOrder ?? 999;
      final right = ghanaPresentation[b.id]?.sortOrder ?? 999;
      return left == right ? a.name.compareTo(b.name) : left.compareTo(right);
    });

    return Catalogue(
      services: services,
      regions: regions,
      feePercent: (booking['feePercent'] as num?)?.toDouble(),
    );
  }

  /// Collapses the API's five pricing modes onto the three the provider app asks about.
  static PricingModel _pricingModelFor(String? apiMode) => switch (apiMode) {
    'PerUnit' => PricingModel.perItem,
    'FixedPrice' || 'StartingFrom' => PricingModel.hourly,
    // InspectionThenQuote and QuoteBeforeVisit both quote per job after seeing it.
    _ => PricingModel.calloutQuote,
  };
}
