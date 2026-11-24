import 'package:grid_professionals/data/country/country_config.dart';

/// Ghana market configuration: services, regions, payout rails.
///
/// GRID Pro launches with four services: home cleaning, laundry, AC
/// servicing and pest control. The API's catalogue replaces this list when
/// it loads.
const ghanaConfig = CountryConfig(
  code: 'GH',
  name: 'Ghana',
  dialCode: '+233',
  currencySymbol: 'GH₵',
  currencyCode: 'GHS',
  localPhoneDigits: 9,
  idDocumentName: 'Ghana Card',
  services: [
    ServiceDefinition(
      id: 'cleaning',
      name: 'Home cleaning',
      summary: 'Homes and apartments — regular, deep and move-out cleans.',
      pricingModel: PricingModel.hourly,
      subServices: [
        'Standard cleaning',
        'Deep cleaning',
        'Move-in / move-out cleaning',
        'After-party cleaning',
        'Sofa & carpet cleaning',
        'Window cleaning',
      ],
      experienceHint:
          'e.g. I clean homes and apartments in East Legon, mostly deep '
          'cleans, and bring my own supplies.',
    ),
    ServiceDefinition(
      id: 'laundry',
      name: 'Laundry',
      summary: 'Wash, iron and dry cleaning, with pickup and delivery.',
      pricingModel: PricingModel.perItem,
      delivery: ServiceDelivery.both,
      subServices: [
        'Wash & fold',
        'Wash & iron',
        'Ironing only',
        'Dry cleaning',
        'Duvets & bulky items',
        'Pickup & delivery',
      ],
      experienceHint:
          'e.g. I run a laundry in Adenta with two machines and offer '
          'next-day pickup and delivery.',
    ),
    ServiceDefinition(
      id: 'ac-servicing',
      name: 'AC servicing',
      summary:
          'Split and window units: servicing, deep cleans, gas and repairs.',
      pricingModel: PricingModel.perItem,
      subServices: [
        'General servicing',
        'Deep foam cleaning',
        'Gas top-up',
        'Fault diagnosis',
        'Installation',
      ],
      experienceHint:
          'e.g. I service split units across Airport and Cantonments and '
          'carry my own pressure washer and gauges.',
    ),
    ServiceDefinition(
      id: 'pest-control',
      name: 'Pest control',
      summary: 'Fumigation for mosquitoes, cockroaches, rodents and termites.',
      pricingModel: PricingModel.perItem,
      subServices: [
        'General fumigation',
        'Rodent control',
        'Termite treatment',
        'Bed bugs',
      ],
      experienceHint:
          'e.g. EPA-licensed fumigator, mostly homes and estates in Tema, '
          'using approved products only.',
    ),
  ],
  regions: [
    RegionDefinition(
      name: 'Greater Accra',
      towns: [
        'East Legon',
        'Spintex',
        'Adenta',
        'Madina',
        'Tema',
        'Osu',
        'Labone',
        'Cantonments',
        'Airport Residential',
        'Dansoman',
        'Achimota',
        'Lapaz',
        'Dome',
        'Ashaley Botwe',
        'Teshie',
        'Nungua',
        'Kasoa',
        'Weija',
        'Oyarifa',
        'Pokuase',
      ],
    ),
    RegionDefinition(
      name: 'Ashanti',
      towns: [
        'Ahodwo',
        'Asokwa',
        'Bantama',
        'Suame',
        'Tafo',
        'Ejisu',
        'Santasi',
        'Kwadaso',
        'Atonsu',
        'Obuasi',
      ],
    ),
    RegionDefinition(
      name: 'Western',
      towns: [
        'Takoradi',
        'Sekondi',
        'Anaji',
        'Airport Ridge',
        'Effia',
        'Tarkwa',
      ],
    ),
    RegionDefinition(
      name: 'Central',
      towns: ['Cape Coast', 'Elmina', 'Mankessim', 'Winneba', 'Swedru'],
    ),
    RegionDefinition(
      name: 'Eastern',
      towns: ['Koforidua', 'Nsawam', 'Suhum', 'Akosombo', 'Nkawkaw'],
    ),
    RegionDefinition(
      name: 'Northern',
      towns: ['Tamale', 'Sagnarigu', 'Savelugu', 'Yendi'],
    ),
  ],
  mobileMoneyProviders: [
    MobileMoneyProvider(id: 'mtn', name: 'MTN Mobile Money'),
    MobileMoneyProvider(id: 'telecel', name: 'Telecel Cash'),
    MobileMoneyProvider(id: 'at', name: 'AT Money'),
  ],
  banks: [
    'GCB Bank',
    'Ecobank Ghana',
    'Absa Bank Ghana',
    'Stanbic Bank',
    'Fidelity Bank',
    'CalBank',
    'Zenith Bank',
    'Standard Chartered',
    'Agricultural Development Bank',
    'UBA Ghana',
    'Consolidated Bank Ghana',
    'Republic Bank',
  ],
);
