import 'package:grid_professionals/core/models/service_kind.dart';

export 'package:grid_professionals/core/models/onboarding_models.dart';
export 'package:grid_professionals/core/models/service_kind.dart';

/// Where a job is. The codes mirror the GRID API's `ScheduledService`
/// (cleaning) and `PickupAndDelivery` (laundry) workflows, minus the
/// scheduling-only stages a provider never acts on.
enum JobStage {
  offer,
  accepted,
  // Cleaning.
  onTheWay,
  arrived,
  inProgress,
  // Laundry.
  pickedUp,
  processing,
  readyForDelivery,
  outForDelivery,
  // Both.
  completed,
  paid,
  declined,
  cancelled,
}

extension JobStageFlow on JobStage {
  bool get isActive => !{
    JobStage.offer,
    JobStage.completed,
    JobStage.paid,
    JobStage.declined,
    JobStage.cancelled,
  }.contains(this);

  bool get isClosed => {
    JobStage.completed,
    JobStage.paid,
    JobStage.declined,
    JobStage.cancelled,
  }.contains(this);
}

/// The working steps of each service, in order. Drives the progress bar on
/// the job screen and which action comes next.
List<JobStage> stagesFor(ServiceKind service) => switch (service) {
  ServiceKind.cleaning ||
  ServiceKind.acServicing ||
  ServiceKind.pestControl => const [
    JobStage.accepted,
    JobStage.onTheWay,
    JobStage.arrived,
    JobStage.inProgress,
    JobStage.completed,
  ],
  ServiceKind.laundry => const [
    JobStage.accepted,
    JobStage.pickedUp,
    JobStage.processing,
    JobStage.readyForDelivery,
    JobStage.outForDelivery,
    JobStage.completed,
  ],
};

/// One action moves a job forward. Null when the provider has nothing to do.
class StageAction {
  const StageAction(this.label, this.next, {this.confirm});

  /// Button copy, e.g. "Start trip".
  final String label;
  final JobStage next;

  /// When set, the action asks this question before it runs.
  final String? confirm;
}

class Job {
  const Job({
    required this.id,
    required this.service,
    required this.title,
    required this.scope,
    required this.area,
    required this.address,
    required this.customerName,
    required this.scheduledAt,
    required this.price,
    required this.stage,
    String? code,
    double? fee,
    this.distanceKm,
    this.notes = '',
    this.items = const [],
    this.expiresAt,
    this.customerPhone,
    this.latitude,
    this.longitude,
    this.nextCommand,
    this.cancelReason,
  }) : code = code ?? id,
       // ignore: prefer_initializing_formals
       _fee = fee;

  /// GRID's id for the job, or for the offer while [stage] is [JobStage.offer].
  final String id;

  /// What people say out loud: "GJ-1024" for a job, "GR-1042" for a request.
  final String code;
  final ServiceKind service;

  /// What was booked, e.g. "Deep cleaning".
  final String title;

  /// The size of the job, e.g. "3 bedrooms · 2 bathrooms".
  final String scope;

  /// General area, shown before acceptance.
  final String area;

  /// Full address. Empty until the request is accepted.
  final String address;

  /// Empty until the request is accepted.
  final String customerName;

  /// Only while the job is live.
  final String? customerPhone;
  final DateTime scheduledAt;

  /// What the customer pays. GRID's fee comes off this.
  final double price;

  /// Straight-line distance from the provider's base, when GRID knows it.
  final double? distanceKm;
  final JobStage stage;

  /// Customer's instructions.
  final String notes;

  /// Laundry only: what is in the bag.
  final List<String> items;

  /// Offers only: when the request goes to someone else.
  final DateTime? expiresAt;
  final double? latitude;
  final double? longitude;

  /// The step GRID will accept next, e.g. `start-journey`. Null for sample
  /// jobs, and for jobs waiting on the customer.
  final String? nextCommand;
  final String? cancelReason;

  final double? _fee;

  /// Used for sample jobs only; real jobs carry the fee GRID fixed for them.
  static const feeRate = 0.15;
  double get fee => _fee ?? (price * feeRate * 100).roundToDouble() / 100;
  double get earnings => price - fee;
  int get feePercent => price == 0 ? 0 : (fee / price * 100).round();

  String get customerFirstName => customerName.trim().isEmpty
      ? 'The customer'
      : customerName.split(' ').first;

  /// "East Legon · 3.2 km away", or just the area when distance is unknown.
  String get areaAndDistance => distanceKm == null
      ? area
      : '$area · ${distanceKm!.toStringAsFixed(1)} km away';

  String get stageLabel => switch (stage) {
    JobStage.offer => 'New request',
    JobStage.accepted =>
      service == ServiceKind.laundry ? 'Pickup scheduled' : 'Scheduled',
    JobStage.onTheWay => 'On the way',
    JobStage.arrived => 'Arrived',
    JobStage.inProgress =>
      service == ServiceKind.cleaning ? 'Cleaning' : 'Working',
    JobStage.pickedUp => 'Picked up',
    JobStage.processing => 'Washing',
    JobStage.readyForDelivery => 'Ready',
    JobStage.outForDelivery => 'Out for delivery',
    JobStage.completed => 'Awaiting confirmation',
    JobStage.paid => 'Paid',
    JobStage.declined => 'Declined',
    JobStage.cancelled => 'Cancelled',
  };

  /// The single next step for the provider.
  StageAction? get nextAction => service.collected
      ? switch (stage) {
          JobStage.accepted => const StageAction(
            'Confirm pickup',
            JobStage.pickedUp,
            confirm: 'Have you collected the items?',
          ),
          JobStage.pickedUp => const StageAction(
            'Start washing',
            JobStage.processing,
          ),
          JobStage.processing => const StageAction(
            'Mark as ready',
            JobStage.readyForDelivery,
          ),
          JobStage.readyForDelivery => const StageAction(
            'Start delivery',
            JobStage.outForDelivery,
          ),
          JobStage.outForDelivery => const StageAction(
            'Confirm delivery',
            JobStage.completed,
            confirm: 'Has the customer received everything?',
          ),
          _ => null,
        }
      : switch (stage) {
          JobStage.accepted => const StageAction(
            'Start trip',
            JobStage.onTheWay,
          ),
          JobStage.onTheWay => const StageAction(
            'I\'ve arrived',
            JobStage.arrived,
          ),
          JobStage.arrived => StageAction(
            service == ServiceKind.cleaning ? 'Start cleaning' : 'Start work',
            JobStage.inProgress,
          ),
          JobStage.inProgress => StageAction(
            'Finish job',
            JobStage.completed,
            confirm: service == ServiceKind.cleaning
                ? 'Is the cleaning done?'
                : 'Is the job done?',
          ),
          _ => null,
        };

  Job copyWith({JobStage? stage, String? address, String? customerName}) => Job(
    id: id,
    code: code,
    service: service,
    title: title,
    scope: scope,
    area: area,
    address: address ?? this.address,
    customerName: customerName ?? this.customerName,
    customerPhone: customerPhone,
    scheduledAt: scheduledAt,
    price: price,
    fee: _fee,
    distanceKm: distanceKm,
    stage: stage ?? this.stage,
    notes: notes,
    items: items,
    expiresAt: expiresAt,
    latitude: latitude,
    longitude: longitude,
    nextCommand: nextCommand,
    cancelReason: cancelReason,
  );
}

/// One service the provider sells, with the price customers are quoted from.
class ServiceOffering {
  const ServiceOffering({
    required this.id,
    required this.service,
    required this.active,
    this.price,
    this.pricingMode = 'PerUnit',
    this.unitName,
    this.sameDay = true,
  });
  final String id;
  final ServiceKind service;
  final bool active;
  final double? price;

  /// The API's pricing mode, kept so a save sends back what was there.
  final String pricingMode;
  final String? unitName;
  final bool sameDay;

  /// "Hourly rate" for cleaning by the hour, and so on.
  String get priceLabel => switch (pricingMode) {
    'PerUnit' =>
      unitName == 'hour' ? 'Hourly rate' : 'Price per ${unitName ?? 'unit'}',
    'StartingFrom' =>
      service == ServiceKind.laundry
          ? 'Starting price per load'
          : 'Starting price',
    'FixedPrice' => 'Fixed price',
    _ => 'Call-out fee',
  };

  ServiceOffering copyWith({bool? active, double? price, bool? sameDay}) =>
      ServiceOffering(
        id: id,
        service: service,
        active: active ?? this.active,
        price: price ?? this.price,
        pricingMode: pricingMode,
        unitName: unitName,
        sameDay: sameDay ?? this.sameDay,
      );
}

/// Where GRID sends the provider's earnings. Only ever the masked number.
class PayoutAccount {
  const PayoutAccount({
    required this.providerName,
    required this.accountName,
    required this.maskedNumber,
    this.mobileMoney = true,
    this.verified = false,
  });
  final String providerName;
  final String accountName;
  final String maskedNumber;
  final bool mobileMoney;
  final bool verified;
}

/// The signed-in provider as GRID knows them.
class ProviderProfile {
  const ProviderProfile({
    required this.ownerName,
    required this.displayName,
    required this.phone,
    required this.online,
    this.business = false,
    this.description = '',
    this.rating,
    this.completedJobs = 0,
    this.memberSince,
    this.offerings = const [],
    this.serviceAreas = const [],
    this.travelRadiusKm = 10,
    this.payout,
    this.canGoOnline = true,
    this.missingToGoOnline = const [],
  });

  /// The person's own name.
  final String ownerName;

  /// What customers see: the business name, or the person's name.
  final String displayName;
  final String phone;
  final bool online;
  final bool business;
  final String description;

  /// Null until the provider has reviews.
  final double? rating;
  final int completedJobs;
  final int? memberSince;
  final List<ServiceOffering> offerings;
  final List<String> serviceAreas;
  final double travelRadiusKm;
  final PayoutAccount? payout;
  final bool canGoOnline;

  /// What GRID still needs before this provider can go online, in its words.
  final List<String> missingToGoOnline;

  String get firstName =>
      ownerName.trim().isEmpty ? 'there' : ownerName.trim().split(' ').first;

  String get initials {
    final parts = ownerName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  /// "+233 24 555 0192" from GRID's `233245550192`.
  String get phoneLabel {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 12 || !digits.startsWith('233')) return phone;
    return '+233 ${digits.substring(3, 5)} ${digits.substring(5, 8)} '
        '${digits.substring(8)}';
  }

  ProviderProfile copyWith({bool? online, String? description}) =>
      ProviderProfile(
        ownerName: ownerName,
        displayName: displayName,
        phone: phone,
        online: online ?? this.online,
        business: business,
        description: description ?? this.description,
        rating: rating,
        completedJobs: completedJobs,
        memberSince: memberSince,
        offerings: offerings,
        serviceAreas: serviceAreas,
        travelRadiusKm: travelRadiusKm,
        payout: payout,
        canGoOnline: canGoOnline,
        missingToGoOnline: missingToGoOnline,
      );
}

/// When and how far the provider works.
class WorkSettings {
  const WorkSettings({
    this.workingDays = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
    this.startHour = 7,
    this.endHour = 18,
    this.travelRadiusKm = 10,
  });
  final List<String> workingDays;
  final int startHour;
  final int endHour;
  final double travelRadiusKm;

  WorkSettings copyWith({
    List<String>? workingDays,
    int? startHour,
    int? endHour,
    double? travelRadiusKm,
  }) => WorkSettings(
    workingDays: workingDays ?? this.workingDays,
    startHour: startHour ?? this.startHour,
    endHour: endHour ?? this.endHour,
    travelRadiusKm: travelRadiusKm ?? this.travelRadiusKm,
  );
}

enum EarningStatus { pending, available, paid }

/// What a finished job paid the provider.
class Earning {
  const Earning({
    required this.jobCode,
    required this.service,
    required this.title,
    required this.customer,
    required this.gross,
    required this.fee,
    required this.date,
    this.status = EarningStatus.paid,
  });
  final String jobCode;
  final ServiceKind service;
  final String title;
  final String customer;
  final double gross;
  final double fee;
  final DateTime date;
  final EarningStatus status;

  double get net => gross - fee;
}

enum PayoutStatus { scheduled, paid, failed }

class Payout {
  const Payout({
    required this.reference,
    required this.amount,
    required this.date,
    required this.status,
    required this.destination,
  });
  final String reference;
  final double amount;
  final DateTime date;
  final PayoutStatus status;

  /// Where it went, masked, e.g. "MTN Mobile Money •••• 0192".
  final String destination;
}

/// Balance, totals and the activity behind them.
class EarningsOverview {
  const EarningsOverview({
    this.available = 0,
    this.pending = 0,
    this.paid = 0,
    this.last7Days = 0,
    this.last30Days = 0,
    this.earnings = const [],
    this.payouts = const [],
  });
  final double available;
  final double pending;
  final double paid;
  final double last7Days;
  final double last30Days;
  final List<Earning> earnings;
  final List<Payout> payouts;
}

class SupportTicket {
  const SupportTicket({required this.reference, required this.status});

  /// "GRID-2841".
  final String reference;
  final String status;
}
