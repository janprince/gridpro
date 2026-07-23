import 'package:grid_professionals/data/country/country_config.dart';

export 'package:grid_professionals/data/country/country_config.dart'
    show PayoutType, PricingModel, ServiceDelivery;

/// Whether the applicant works alone or runs a small business.
enum ProviderType { individual, business }

/// Lifecycle of a provider application.
enum ApplicationStatus {
  draft,
  submitted,
  underReview,
  moreInfoRequired,
  verificationFailed,
  approved,
  rejected,
}

/// The wizard steps, in order. The hub and progress indicator group them by
/// [OnboardingStage].
enum OnboardingStep {
  providerType,
  details,
  services,
  experience,
  serviceArea,
  availability,
  pricing,
  payout,
  portfolio,
  identity,
}

enum OnboardingStage { aboutYou, yourWork, gettingPaid, trust }

extension OnboardingStageInfo on OnboardingStage {
  String get title => switch (this) {
    OnboardingStage.aboutYou => 'About you',
    OnboardingStage.yourWork => 'Your work',
    OnboardingStage.gettingPaid => 'Getting paid',
    OnboardingStage.trust => 'Trust & verification',
  };

  List<OnboardingStep> get steps => switch (this) {
    OnboardingStage.aboutYou => const [
      OnboardingStep.providerType,
      OnboardingStep.details,
    ],
    OnboardingStage.yourWork => const [
      OnboardingStep.services,
      OnboardingStep.experience,
      OnboardingStep.serviceArea,
      OnboardingStep.availability,
    ],
    OnboardingStage.gettingPaid => const [
      OnboardingStep.pricing,
      OnboardingStep.payout,
    ],
    OnboardingStage.trust => const [
      OnboardingStep.portfolio,
      OnboardingStep.identity,
    ],
  };
}

extension OnboardingStepInfo on OnboardingStep {
  OnboardingStage get stage => switch (this) {
    OnboardingStep.providerType ||
    OnboardingStep.details => OnboardingStage.aboutYou,
    OnboardingStep.services ||
    OnboardingStep.experience ||
    OnboardingStep.serviceArea ||
    OnboardingStep.availability => OnboardingStage.yourWork,
    OnboardingStep.pricing ||
    OnboardingStep.payout => OnboardingStage.gettingPaid,
    OnboardingStep.portfolio ||
    OnboardingStep.identity => OnboardingStage.trust,
  };

  String get title => switch (this) {
    OnboardingStep.providerType => 'How you work',
    OnboardingStep.details => 'Your details',
    OnboardingStep.services => 'Your services',
    OnboardingStep.experience => 'Your experience',
    OnboardingStep.serviceArea => 'Where you work',
    OnboardingStep.availability => 'When you work',
    OnboardingStep.pricing => 'Your pricing',
    OnboardingStep.payout => 'How you get paid',
    OnboardingStep.portfolio => 'Your work & qualifications',
    OnboardingStep.identity => 'Identity verification',
  };
}

enum SectionStatus { notStarted, inProgress, complete }

/// Mock upload lifecycle for portfolio, qualification and identity captures.
enum UploadState { uploading, failed, done }

class UploadItem {
  const UploadItem({
    required this.id,
    required this.label,
    required this.state,
    this.progress = 0,
  });

  final String id;
  final String label;
  final UploadState state;
  final double progress;

  UploadItem copyWith({UploadState? state, double? progress}) => UploadItem(
    id: id,
    label: label,
    state: state ?? this.state,
    progress: progress ?? this.progress,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'state': state.name,
  };

  factory UploadItem.fromJson(Map<String, dynamic> json) => UploadItem(
    id: json['id'] as String,
    label: json['label'] as String,
    // In-flight uploads do not survive a restart; restore them as failed so
    // the provider can retry rather than silently losing them.
    state: switch (json['state'] as String?) {
      'done' => UploadState.done,
      _ => UploadState.failed,
    },
    progress: 1,
  );
}

/// Everything a provider enters during onboarding. Immutable; persisted as
/// JSON after each change so the application survives restarts.
class OnboardingDraft {
  const OnboardingDraft({
    this.phone = '',
    this.providerType,
    this.fullName = '',
    this.email = '',
    this.businessName = '',
    this.delivery,
    this.premisesAddress = '',
    this.primaryServiceId,
    this.subServices = const [],
    this.yearsExperience,
    this.experienceSummary = '',
    this.toolsEquipment = '',
    this.region,
    this.towns = const [],
    this.travelRadiusKm = 15,
    this.workingDays = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
    this.startHour = 8,
    this.endHour = 17,
    this.sameDay = true,
    this.emergency = false,
    this.calloutFee,
    this.hourlyRate,
    this.minimumCharge,
    this.pricingNotes = '',
    this.payoutType,
    this.momoProviderId,
    this.momoNumber = '',
    this.momoName = '',
    this.bankName,
    this.bankAccountNumber = '',
    this.bankAccountName = '',
    this.portfolio = const [],
    this.qualifications = const [],
    this.idFront,
    this.idBack,
    this.selfie,
    this.agreedToStandards = false,
    this.currentStep = 0,
  });

  final String phone;
  final ProviderType? providerType;
  final String fullName;
  final String email;
  final String businessName;
  final ServiceDelivery? delivery;
  final String premisesAddress;
  final String? primaryServiceId;
  final List<String> subServices;
  final int? yearsExperience;
  final String experienceSummary;
  final String toolsEquipment;
  final String? region;
  final List<String> towns;
  final double travelRadiusKm;
  final List<String> workingDays;
  final int startHour;
  final int endHour;
  final bool sameDay;
  final bool emergency;
  final double? calloutFee;
  final double? hourlyRate;
  final double? minimumCharge;
  final String pricingNotes;
  final PayoutType? payoutType;
  final String? momoProviderId;
  final String momoNumber;
  final String momoName;
  final String? bankName;
  final String bankAccountNumber;
  final String bankAccountName;
  final List<UploadItem> portfolio;
  final List<UploadItem> qualifications;
  final UploadItem? idFront;
  final UploadItem? idBack;
  final UploadItem? selfie;
  final bool agreedToStandards;
  final int currentStep;

  static const _unset = Object();

  OnboardingDraft copyWith({
    String? phone,
    Object? providerType = _unset,
    String? fullName,
    String? email,
    String? businessName,
    Object? delivery = _unset,
    String? premisesAddress,
    Object? primaryServiceId = _unset,
    List<String>? subServices,
    Object? yearsExperience = _unset,
    String? experienceSummary,
    String? toolsEquipment,
    Object? region = _unset,
    List<String>? towns,
    double? travelRadiusKm,
    List<String>? workingDays,
    int? startHour,
    int? endHour,
    bool? sameDay,
    bool? emergency,
    Object? calloutFee = _unset,
    Object? hourlyRate = _unset,
    Object? minimumCharge = _unset,
    String? pricingNotes,
    Object? payoutType = _unset,
    Object? momoProviderId = _unset,
    String? momoNumber,
    String? momoName,
    Object? bankName = _unset,
    String? bankAccountNumber,
    String? bankAccountName,
    List<UploadItem>? portfolio,
    List<UploadItem>? qualifications,
    Object? idFront = _unset,
    Object? idBack = _unset,
    Object? selfie = _unset,
    bool? agreedToStandards,
    int? currentStep,
  }) => OnboardingDraft(
    phone: phone ?? this.phone,
    providerType: providerType == _unset
        ? this.providerType
        : providerType as ProviderType?,
    fullName: fullName ?? this.fullName,
    email: email ?? this.email,
    businessName: businessName ?? this.businessName,
    delivery: delivery == _unset ? this.delivery : delivery as ServiceDelivery?,
    premisesAddress: premisesAddress ?? this.premisesAddress,
    primaryServiceId: primaryServiceId == _unset
        ? this.primaryServiceId
        : primaryServiceId as String?,
    subServices: subServices ?? this.subServices,
    yearsExperience: yearsExperience == _unset
        ? this.yearsExperience
        : yearsExperience as int?,
    experienceSummary: experienceSummary ?? this.experienceSummary,
    toolsEquipment: toolsEquipment ?? this.toolsEquipment,
    region: region == _unset ? this.region : region as String?,
    towns: towns ?? this.towns,
    travelRadiusKm: travelRadiusKm ?? this.travelRadiusKm,
    workingDays: workingDays ?? this.workingDays,
    startHour: startHour ?? this.startHour,
    endHour: endHour ?? this.endHour,
    sameDay: sameDay ?? this.sameDay,
    emergency: emergency ?? this.emergency,
    calloutFee: calloutFee == _unset ? this.calloutFee : calloutFee as double?,
    hourlyRate: hourlyRate == _unset ? this.hourlyRate : hourlyRate as double?,
    minimumCharge: minimumCharge == _unset
        ? this.minimumCharge
        : minimumCharge as double?,
    pricingNotes: pricingNotes ?? this.pricingNotes,
    payoutType: payoutType == _unset
        ? this.payoutType
        : payoutType as PayoutType?,
    momoProviderId: momoProviderId == _unset
        ? this.momoProviderId
        : momoProviderId as String?,
    momoNumber: momoNumber ?? this.momoNumber,
    momoName: momoName ?? this.momoName,
    bankName: bankName == _unset ? this.bankName : bankName as String?,
    bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
    bankAccountName: bankAccountName ?? this.bankAccountName,
    portfolio: portfolio ?? this.portfolio,
    qualifications: qualifications ?? this.qualifications,
    idFront: idFront == _unset ? this.idFront : idFront as UploadItem?,
    idBack: idBack == _unset ? this.idBack : idBack as UploadItem?,
    selfie: selfie == _unset ? this.selfie : selfie as UploadItem?,
    agreedToStandards: agreedToStandards ?? this.agreedToStandards,
    currentStep: currentStep ?? this.currentStep,
  );

  bool get isBusiness => providerType == ProviderType.business;

  bool get servesAtPremises =>
      delivery == ServiceDelivery.fixedPremises ||
      delivery == ServiceDelivery.both;

  bool get travelsToCustomers =>
      delivery == ServiceDelivery.travels || delivery == ServiceDelivery.both;

  /// Completion state of one wizard step, used by the hub, the review screen
  /// and step validation.
  SectionStatus statusOf(OnboardingStep step, CountryConfig config) {
    final service = config.serviceById(primaryServiceId);
    return switch (step) {
      OnboardingStep.providerType =>
        providerType == null
            ? SectionStatus.notStarted
            : SectionStatus.complete,
      OnboardingStep.details => _detailsStatus,
      OnboardingStep.services => switch ((primaryServiceId, subServices)) {
        (null, _) => SectionStatus.notStarted,
        (_, []) => SectionStatus.inProgress,
        _ => SectionStatus.complete,
      },
      OnboardingStep.experience =>
        yearsExperience == null
            ? SectionStatus.notStarted
            : experienceSummary.trim().isEmpty
            ? SectionStatus.inProgress
            : SectionStatus.complete,
      OnboardingStep.serviceArea =>
        region == null
            ? SectionStatus.notStarted
            : (towns.isEmpty && !servesAtPremises) ||
                  (servesAtPremises && premisesAddress.trim().isEmpty)
            ? SectionStatus.inProgress
            : towns.isEmpty
            ? SectionStatus.inProgress
            : SectionStatus.complete,
      // Availability has sensible defaults, so it is complete once reached;
      // an empty day selection means it still needs attention.
      OnboardingStep.availability =>
        workingDays.isEmpty
            ? SectionStatus.inProgress
            : currentStep >= OnboardingStep.availability.index
            ? SectionStatus.complete
            : SectionStatus.notStarted,
      OnboardingStep.pricing => switch (service?.pricingModel) {
        null => SectionStatus.notStarted,
        PricingModel.calloutQuote =>
          calloutFee == null
              ? SectionStatus.notStarted
              : SectionStatus.complete,
        PricingModel.hourly =>
          hourlyRate == null
              ? SectionStatus.notStarted
              : SectionStatus.complete,
        PricingModel.perItem =>
          minimumCharge == null
              ? SectionStatus.notStarted
              : SectionStatus.complete,
      },
      OnboardingStep.payout => _payoutStatus,
      OnboardingStep.portfolio =>
        portfolio.isEmpty && qualifications.isEmpty
            ? SectionStatus.notStarted
            : portfolio.where((item) => item.state == UploadState.done).isEmpty
            ? SectionStatus.inProgress
            : SectionStatus.complete,
      OnboardingStep.identity => _identityStatus,
    };
  }

  SectionStatus get _detailsStatus {
    final nameOk = fullName.trim().length >= 3;
    final businessOk = !isBusiness || businessName.trim().isNotEmpty;
    final deliveryOk =
        delivery != null &&
        (!servesAtPremises || premisesAddress.trim().isNotEmpty);
    if (nameOk && businessOk && deliveryOk) return SectionStatus.complete;
    if (fullName.trim().isNotEmpty || businessName.trim().isNotEmpty) {
      return SectionStatus.inProgress;
    }
    return SectionStatus.notStarted;
  }

  SectionStatus get _payoutStatus {
    switch (payoutType) {
      case null:
        return SectionStatus.notStarted;
      case PayoutType.mobileMoney:
        final digits = momoNumber.replaceAll(RegExp(r'\D'), '');
        if (momoProviderId != null &&
            digits.length >= 9 &&
            momoName.trim().isNotEmpty) {
          return SectionStatus.complete;
        }
        return SectionStatus.inProgress;
      case PayoutType.bank:
        if (bankName != null &&
            bankAccountNumber.trim().length >= 8 &&
            bankAccountName.trim().isNotEmpty) {
          return SectionStatus.complete;
        }
        return SectionStatus.inProgress;
    }
  }

  SectionStatus get _identityStatus {
    final done = [
      idFront,
      idBack,
      selfie,
    ].where((item) => item?.state == UploadState.done).length;
    if (done == 3) return SectionStatus.complete;
    if (done > 0 || idFront != null || idBack != null || selfie != null) {
      return SectionStatus.inProgress;
    }
    return SectionStatus.notStarted;
  }

  bool isComplete(CountryConfig config) => OnboardingStep.values.every(
    (step) => statusOf(step, config) == SectionStatus.complete,
  );

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'providerType': providerType?.name,
    'fullName': fullName,
    'email': email,
    'businessName': businessName,
    'delivery': delivery?.name,
    'premisesAddress': premisesAddress,
    'primaryServiceId': primaryServiceId,
    'subServices': subServices,
    'yearsExperience': yearsExperience,
    'experienceSummary': experienceSummary,
    'toolsEquipment': toolsEquipment,
    'region': region,
    'towns': towns,
    'travelRadiusKm': travelRadiusKm,
    'workingDays': workingDays,
    'startHour': startHour,
    'endHour': endHour,
    'sameDay': sameDay,
    'emergency': emergency,
    'calloutFee': calloutFee,
    'hourlyRate': hourlyRate,
    'minimumCharge': minimumCharge,
    'pricingNotes': pricingNotes,
    'payoutType': payoutType?.name,
    'momoProviderId': momoProviderId,
    'momoNumber': momoNumber,
    'momoName': momoName,
    'bankName': bankName,
    'bankAccountNumber': bankAccountNumber,
    'bankAccountName': bankAccountName,
    'portfolio': [
      for (final item in portfolio)
        if (item.state == UploadState.done) item.toJson(),
    ],
    'qualifications': [
      for (final item in qualifications)
        if (item.state == UploadState.done) item.toJson(),
    ],
    'idFront': idFront?.toJson(),
    'idBack': idBack?.toJson(),
    'selfie': selfie?.toJson(),
    'agreedToStandards': agreedToStandards,
    'currentStep': currentStep,
  };

  factory OnboardingDraft.fromJson(Map<String, dynamic> json) {
    T? enumOrNull<T extends Enum>(List<T> values, Object? name) {
      for (final value in values) {
        if (value.name == name) return value;
      }
      return null;
    }

    List<UploadItem> uploads(Object? value) => [
      if (value is List)
        for (final item in value)
          if (item is Map<String, dynamic>) UploadItem.fromJson(item),
    ];

    UploadItem? upload(Object? value) =>
        value is Map<String, dynamic> ? UploadItem.fromJson(value) : null;

    return OnboardingDraft(
      phone: json['phone'] as String? ?? '',
      providerType: enumOrNull(ProviderType.values, json['providerType']),
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      businessName: json['businessName'] as String? ?? '',
      delivery: enumOrNull(ServiceDelivery.values, json['delivery']),
      premisesAddress: json['premisesAddress'] as String? ?? '',
      primaryServiceId: json['primaryServiceId'] as String?,
      subServices: [...?(json['subServices'] as List?)?.cast<String>()],
      yearsExperience: json['yearsExperience'] as int?,
      experienceSummary: json['experienceSummary'] as String? ?? '',
      toolsEquipment: json['toolsEquipment'] as String? ?? '',
      region: json['region'] as String?,
      towns: [...?(json['towns'] as List?)?.cast<String>()],
      travelRadiusKm: (json['travelRadiusKm'] as num?)?.toDouble() ?? 15,
      workingDays: [...?(json['workingDays'] as List?)?.cast<String>()],
      startHour: json['startHour'] as int? ?? 8,
      endHour: json['endHour'] as int? ?? 17,
      sameDay: json['sameDay'] as bool? ?? true,
      emergency: json['emergency'] as bool? ?? false,
      calloutFee: (json['calloutFee'] as num?)?.toDouble(),
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
      minimumCharge: (json['minimumCharge'] as num?)?.toDouble(),
      pricingNotes: json['pricingNotes'] as String? ?? '',
      payoutType: enumOrNull(PayoutType.values, json['payoutType']),
      momoProviderId: json['momoProviderId'] as String?,
      momoNumber: json['momoNumber'] as String? ?? '',
      momoName: json['momoName'] as String? ?? '',
      bankName: json['bankName'] as String?,
      bankAccountNumber: json['bankAccountNumber'] as String? ?? '',
      bankAccountName: json['bankAccountName'] as String? ?? '',
      portfolio: uploads(json['portfolio']),
      qualifications: uploads(json['qualifications']),
      idFront: upload(json['idFront']),
      idBack: upload(json['idBack']),
      selfie: upload(json['selfie']),
      agreedToStandards: json['agreedToStandards'] as bool? ?? false,
      currentStep: json['currentStep'] as int? ?? 0,
    );
  }
}
