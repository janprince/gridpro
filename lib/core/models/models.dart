export 'package:grid_professionals/core/models/onboarding_models.dart';

enum VerificationStatus {
  notStarted,
  submitted,
  identityReview,
  skillReview,
  standardsCheck,
  approved,
  rejected,
}

enum AvailabilityStatus { available, busy, offline }

enum JobStatus {
  newOffer,
  offerExpired,
  declined,
  accepted,
  onMyWay,
  arrived,
  inspectionInProgress,
  quoteDraft,
  quoteSubmitted,
  awaitingCustomerApproval,
  quoteApproved,
  workInProgress,
  workCompleted,
  awaitingCustomerConfirmation,
  paymentProcessing,
  payoutPending,
  paid,
  cancelled,
  disputed,
}

extension JobStatusLabel on JobStatus {
  String get label => switch (this) {
    JobStatus.newOffer => 'New offer',
    JobStatus.offerExpired => 'Offer expired',
    JobStatus.declined => 'Declined',
    JobStatus.accepted => 'Accepted',
    JobStatus.onMyWay => 'On my way',
    JobStatus.arrived => 'Arrived',
    JobStatus.inspectionInProgress => 'Inspection in progress',
    JobStatus.quoteDraft => 'Quote draft',
    JobStatus.quoteSubmitted => 'Quote submitted',
    JobStatus.awaitingCustomerApproval => 'Awaiting approval',
    JobStatus.quoteApproved => 'Quote approved',
    JobStatus.workInProgress => 'Work in progress',
    JobStatus.workCompleted => 'Work completed',
    JobStatus.awaitingCustomerConfirmation => 'Awaiting confirmation',
    JobStatus.paymentProcessing => 'Payment processing',
    JobStatus.payoutPending => 'Payout pending',
    JobStatus.paid => 'Paid',
    JobStatus.cancelled => 'Cancelled',
    JobStatus.disputed => 'Disputed',
  };
}

class ServiceCategory {
  const ServiceCategory(this.id, this.name, this.iconCode);
  final String id;
  final String name;
  final int iconCode;
}

class ServiceArea {
  const ServiceArea(this.name, {this.region = 'Greater Accra'});
  final String name;
  final String region;
}

class Availability {
  const Availability({
    this.status = AvailabilityStatus.available,
    this.workingDays = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
    this.startHour = 7,
    this.endHour = 18,
    this.maximumTravelKm = 25,
    this.emergency = true,
    this.sameDay = true,
  });
  final AvailabilityStatus status;
  final List<String> workingDays;
  final int startHour;
  final int endHour;
  final double maximumTravelKm;
  final bool emergency;
  final bool sameDay;

  Availability copyWith({
    AvailabilityStatus? status,
    bool? emergency,
    bool? sameDay,
  }) => Availability(
    status: status ?? this.status,
    workingDays: workingDays,
    startHour: startHour,
    endHour: endHour,
    maximumTravelKm: maximumTravelKm,
    emergency: emergency ?? this.emergency,
    sameDay: sameDay ?? this.sameDay,
  );
}

class Professional {
  const Professional({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.businessName,
    required this.bio,
    required this.categories,
    required this.serviceAreas,
    required this.yearsExperience,
    required this.rating,
    required this.completedJobs,
    required this.responseRate,
    required this.onTimeRate,
  });
  final String id;
  final String fullName;
  final String phone;
  final String businessName;
  final String bio;
  final List<String> categories;
  final List<String> serviceAreas;
  final int yearsExperience;
  final double rating;
  final int completedJobs;
  final int responseRate;
  final int onTimeRate;
}

class ProfessionalApplication {
  const ProfessionalApplication({
    this.fullName = '',
    this.phone = '',
    this.email = '',
    this.location = '',
    this.categories = const [],
    this.yearsExperience = 0,
    this.serviceAreas = const [],
    this.agreedToStandards = false,
  });
  final String fullName;
  final String phone;
  final String email;
  final String location;
  final List<String> categories;
  final int yearsExperience;
  final List<String> serviceAreas;
  final bool agreedToStandards;
}

class Job {
  const Job({
    required this.id,
    required this.category,
    required this.summary,
    required this.description,
    required this.area,
    required this.fullAddress,
    required this.customerName,
    required this.scheduledAt,
    required this.status,
    required this.calloutFee,
    required this.distanceKm,
    this.urgency = 'Standard',
    this.quoteTotal,
  });
  final String id;
  final String category;
  final String summary;
  final String description;
  final String area;
  final String fullAddress;
  final String customerName;
  final DateTime scheduledAt;
  final JobStatus status;
  final double calloutFee;
  final double distanceKm;
  final String urgency;
  final double? quoteTotal;

  Job copyWith({JobStatus? status, double? quoteTotal}) => Job(
    id: id,
    category: category,
    summary: summary,
    description: description,
    area: area,
    fullAddress: fullAddress,
    customerName: customerName,
    scheduledAt: scheduledAt,
    status: status ?? this.status,
    calloutFee: calloutFee,
    distanceKm: distanceKm,
    urgency: urgency,
    quoteTotal: quoteTotal ?? this.quoteTotal,
  );
}

class MaterialItem {
  const MaterialItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });
  final String name;
  final double quantity;
  final double unitPrice;
  double get total => quantity * unitPrice;
}

class QuoteLineItem {
  const QuoteLineItem({required this.label, required this.amount});
  final String label;
  final double amount;
}

class Quote {
  const Quote({
    required this.jobId,
    required this.labour,
    required this.materials,
    required this.notes,
    required this.duration,
    required this.warranty,
    required this.calloutFee,
    this.submittedAt,
  });
  final String jobId;
  final double labour;
  final List<MaterialItem> materials;
  final String notes;
  final String duration;
  final String warranty;
  final double calloutFee;
  final DateTime? submittedAt;
  double get materialsTotal =>
      materials.fold(0, (sum, item) => sum + item.total);
  double get total => calloutFee + labour + materialsTotal;
}

class Earning {
  const Earning({
    required this.jobId,
    required this.label,
    required this.gross,
    required this.commission,
    required this.date,
  });
  final String jobId;
  final String label;
  final double gross;
  final double commission;
  final DateTime date;
  double get net => gross - commission;
}

enum PayoutStatus { processing, pending, paid, delayed }

class Payout {
  const Payout({
    required this.id,
    required this.amount,
    required this.date,
    required this.status,
    required this.method,
  });
  final String id;
  final double amount;
  final DateTime date;
  final PayoutStatus status;
  final String method;
}

class Review {
  const Review({
    required this.customer,
    required this.rating,
    required this.comment,
    required this.date,
  });
  final String customer;
  final double rating;
  final String comment;
  final DateTime date;
}

class PortfolioItem {
  const PortfolioItem({
    required this.title,
    required this.category,
    required this.notes,
    required this.colorValue,
  });
  final String title;
  final String category;
  final String notes;
  final int colorValue;
}

class TrainingModule {
  const TrainingModule({
    required this.title,
    required this.durationMinutes,
    required this.progress,
    required this.category,
  });
  final String title;
  final int durationMinutes;
  final double progress;
  final String category;
}

class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.reason,
    required this.details,
    required this.createdAt,
    required this.status,
  });
  final String id;
  final String reason;
  final String details;
  final DateTime createdAt;
  final String status;
}
