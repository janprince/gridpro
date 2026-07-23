import 'package:grid_professionals/core/models/models.dart';

abstract final class MockData {
  static const professional = Professional(
    id: 'pro-001',
    fullName: 'Kofi Mensah',
    phone: '+233 24 555 0192',
    businessName: 'Mensah Electrical & Cooling',
    bio: 'Licensed electrical and AC professional serving homes across Accra.',
    categories: ['Electrical', 'AC Repair & Servicing'],
    serviceAreas: ['East Legon', 'Spintex', 'Adenta', 'Madina', 'Tema'],
    yearsExperience: 8,
    rating: 4.9,
    completedJobs: 124,
    responseRate: 98,
    onTimeRate: 96,
  );

  static const categories = [
    'Plumbing',
    'Electrical',
    'AC Repair and Servicing',
    'Cleaning',
    'Laundry',
    'Gardening',
    'Appliance Repair',
    'Water Pump / Borehole',
    'Generator / Inverter / Solar',
    'CCTV / Security',
    'Carpentry',
    'Painting',
    'Masonry',
    'Welding',
    'General Handyman',
  ];

  static const areas = [
    'East Legon',
    'Spintex',
    'Adenta',
    'Madina',
    'Tema',
    'Oyarifa',
    'Cantonments',
    'Osu',
    'Labone',
    'Dansoman',
    'Kumasi',
    'Other',
  ];

  static final jobs = <Job>[
    Job(
      id: 'JOB-1024',
      category: 'Electrical',
      summary: 'Electrical Fault',
      description:
          'Frequent power trips in the main distribution board. Customer reports a burning smell near one breaker.',
      area: 'East Legon',
      fullAddress: '12 Kofi Annan Street, East Legon',
      customerName: 'Ama Serwaa',
      scheduledAt: DateTime.now().add(const Duration(hours: 2)),
      status: JobStatus.newOffer,
      calloutFee: 50,
      distanceKm: 3.2,
      urgency: 'Urgent',
    ),
    Job(
      id: 'JOB-1021',
      category: 'Plumbing',
      summary: 'Plumbing Leak',
      description:
          'Main pipe burst in the compound. Water is currently isolated to prevent further flooding.',
      area: 'Spintex',
      fullAddress: '18 Boundary Road, Spintex',
      customerName: 'Kwame Mensah',
      scheduledAt: DateTime.now().add(const Duration(hours: 5)),
      status: JobStatus.accepted,
      calloutFee: 50,
      distanceKm: 6.8,
      urgency: 'Urgent',
    ),
    Job(
      id: 'JOB-1019',
      category: 'AC Repair',
      summary: 'AC Servicing',
      description:
          'Two split units need routine servicing and a refrigerant check.',
      area: 'Adenta',
      fullAddress: '4 Lakeside Avenue, Adenta',
      customerName: 'Esi Owusu',
      scheduledAt: DateTime.now().add(const Duration(days: 1, hours: 1)),
      status: JobStatus.awaitingCustomerApproval,
      calloutFee: 50,
      distanceKm: 8.5,
      quoteTotal: 470,
    ),
    Job(
      id: 'JOB-1017',
      category: 'Water Systems',
      summary: 'Water Pump Repair',
      description: 'Booster pump runs but does not build pressure.',
      area: 'Tema',
      fullAddress: 'Community 12, House 48, Tema',
      customerName: 'Nana Boateng',
      scheduledAt: DateTime.now().add(const Duration(days: 1, hours: 4)),
      status: JobStatus.quoteApproved,
      calloutFee: 60,
      distanceKm: 18,
      quoteTotal: 650,
    ),
    Job(
      id: 'JOB-1010',
      category: 'Cleaning',
      summary: 'Home Cleaning',
      description: 'Deep cleaning for a three-bedroom apartment.',
      area: 'Cantonments',
      fullAddress: 'Patrice Lumumba Road, Cantonments',
      customerName: 'Akua Ofori',
      scheduledAt: DateTime.now().subtract(const Duration(days: 3)),
      status: JobStatus.paid,
      calloutFee: 0,
      distanceKm: 4,
      quoteTotal: 420,
    ),
    Job(
      id: 'JOB-1008',
      category: 'Gardening',
      summary: 'Garden Maintenance',
      description: 'Lawn trim and hedge maintenance.',
      area: 'Oyarifa',
      fullAddress: 'Special Gardens Estate, Oyarifa',
      customerName: 'Kojo Asante',
      scheduledAt: DateTime.now().subtract(const Duration(days: 8)),
      status: JobStatus.paid,
      calloutFee: 40,
      distanceKm: 12,
      quoteTotal: 350,
    ),
  ];

  static final earnings = [
    Earning(
      jobId: 'JOB-1010',
      label: 'Home Cleaning',
      gross: 420,
      commission: 63,
      date: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Earning(
      jobId: 'JOB-1008',
      label: 'Garden Maintenance',
      gross: 350,
      commission: 52.5,
      date: DateTime.now().subtract(const Duration(days: 8)),
    ),
    Earning(
      jobId: 'JOB-1004',
      label: 'Generator Servicing',
      gross: 680,
      commission: 102,
      date: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  static final payouts = [
    Payout(
      id: 'PAY-28041',
      amount: 780,
      date: DateTime.now().add(const Duration(days: 2)),
      status: PayoutStatus.pending,
      method: 'MTN MoMo •••• 0192',
    ),
    Payout(
      id: 'PAY-27884',
      amount: 935,
      date: DateTime.now().subtract(const Duration(days: 7)),
      status: PayoutStatus.paid,
      method: 'MTN MoMo •••• 0192',
    ),
  ];

  static final reviews = [
    Review(
      customer: 'Ama Serwaa',
      rating: 5,
      comment:
          'Kofi arrived on time, explained the issue clearly and left the area tidy.',
      date: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Review(
      customer: 'Kwame Mensah',
      rating: 4.8,
      comment: 'Professional work and a clear quote.',
      date: DateTime.now().subtract(const Duration(days: 12)),
    ),
  ];

  static const portfolio = [
    PortfolioItem(
      title: 'Distribution board upgrade',
      category: 'Electrical',
      notes: 'Before and after safety upgrade.',
      colorValue: 0xFF466A63,
    ),
    PortfolioItem(
      title: 'Split AC installation',
      category: 'AC Repair',
      notes: 'Clean indoor and outdoor installation.',
      colorValue: 0xFF73999B,
    ),
    PortfolioItem(
      title: 'Inverter changeover',
      category: 'Solar',
      notes: 'Automatic changeover and testing.',
      colorValue: 0xFF9A7E55,
    ),
  ];

  static const training = [
    TrainingModule(
      title: 'GRID professional standards',
      durationMinutes: 12,
      progress: 1,
      category: 'Standards',
    ),
    TrainingModule(
      title: 'Writing clear professional quotes',
      durationMinutes: 18,
      progress: .65,
      category: 'Business',
    ),
    TrainingModule(
      title: 'Working safely in customer homes',
      durationMinutes: 22,
      progress: .2,
      category: 'Safety',
    ),
    TrainingModule(
      title: 'Customer communication basics',
      durationMinutes: 15,
      progress: 0,
      category: 'Service',
    ),
  ];
}
