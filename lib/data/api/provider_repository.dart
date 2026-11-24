import 'package:grid_professionals/data/api/api_client.dart';
import 'package:grid_professionals/data/api/api_config.dart';

/// Server-side view of the provider's application, used to reconcile local draft state.
class RemoteApplication {
  const RemoteApplication({
    required this.status,
    required this.accountVerificationStatus,
    this.reviewNote,
    this.rejectionReason,
    this.submittedAt,
  });

  /// `Draft | Submitted | UnderReview | MoreInformationRequired | Approved | Rejected | Withdrawn`
  final String status;

  /// Mirrored onto the account; also carries `Suspended`, which the application never has.
  final String accountVerificationStatus;
  final String? reviewNote;
  final String? rejectionReason;
  final DateTime? submittedAt;
}

/// Server-authoritative completeness of the application.
class Readiness {
  const Readiness({
    required this.isReady,
    required this.completionPercentage,
    required this.missing,
  });

  final bool isReady;
  final int completionPercentage;

  /// Requirement codes with human-readable messages, e.g. `portfolio.required`.
  final List<({String code, String message})> missing;
}

/// A verification document already held by GRID.
class RemoteDocument {
  const RemoteDocument({
    required this.id,
    required this.documentType,
    required this.storageKey,
    required this.reviewStatus,
    this.reviewNote,
  });

  final String id;
  final String documentType;
  final String storageKey;

  /// `Pending | Approved | Rejected`
  final String reviewStatus;
  final String? reviewNote;

  String get url => ApiConfig.mediaUrl(storageKey);
}

/// Everything GRID Pro needs from the provider-facing endpoints during onboarding.
///
/// Each method maps to exactly one API call so the sync layer can queue and retry them
/// individually.
class ProviderRepository {
  ProviderRepository(this._client);

  final ApiClient _client;

  // ── Account ────────────────────────────────────────────────────────────

  /// Creates the provider account. Also creates the application and grants the owner role,
  /// so this is the call that turns a signed-in user into a provider.
  Future<String> createAccount({
    required String accountType,
    required String displayName,
    String? email,
  }) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/provider-accounts',
      body: {
        'accountType': accountType,
        'displayName': displayName,
        if (email != null && email.isNotEmpty) 'email': email,
      },
    );
    return data['id'] as String;
  }

  Future<Map<String, dynamic>?> getAccount() async {
    return _client.get<Map<String, dynamic>?>('/provider-accounts/me');
  }

  /// Full replace — the API has no partial update, so every field is resent each time.
  Future<void> updateAccount({
    required String displayName,
    required int yearsOfExperience,
    String? legalName,
    String? description,
    String? email,
    String? businessRegistrationNumber,
    String? city,
    String? primaryArea,
    String? deliveryMode,
    String? premisesAddress,
  }) async {
    await _client.put<dynamic>(
      '/provider-accounts/me',
      body: {
        'displayName': displayName,
        'legalName': legalName,
        'description': description,
        'email': email,
        'profileImageUrl': null,
        'businessRegistrationNumber': businessRegistrationNumber,
        'city': city,
        'primaryArea': primaryArea,
        'yearsOfExperience': yearsOfExperience,
        'deliveryMode': deliveryMode,
        'premisesAddress': premisesAddress,
      },
    );
  }

  Future<void> setOperatingStatus(String status) async {
    await _client.put<dynamic>(
      '/provider-accounts/me/operating-status',
      body: {'operatingStatus': status},
    );
  }

  // ── Application ────────────────────────────────────────────────────────

  Future<RemoteApplication> getApplication() async {
    final application = await _client.get<Map<String, dynamic>>(
      '/provider-applications/me',
    );
    final account = await _client.get<Map<String, dynamic>>(
      '/provider-accounts/me',
    );
    return RemoteApplication(
      status: application['status'] as String,
      accountVerificationStatus: account['verificationStatus'] as String,
      reviewNote: application['reviewNote'] as String?,
      rejectionReason: application['rejectionReason'] as String?,
      submittedAt: application['submittedAt'] == null
          ? null
          : DateTime.parse(application['submittedAt'] as String),
    );
  }

  Future<void> updateExperience({
    String? mainSkill,
    String? secondarySkills,
    String? toolsNotes,
    String? experienceDescription,
    int? yearsOperating,
  }) async {
    await _client.put<dynamic>(
      '/provider-applications/me/experience',
      body: {
        'mainSkill': mainSkill,
        'secondarySkills': secondarySkills,
        'toolsNotes': toolsNotes,
        'certifications': null,
        'experienceDescription': experienceDescription,
        'yearsOperating': yearsOperating,
      },
    );
  }

  Future<void> setCurrentStep(int step) async {
    await _client.put<dynamic>(
      '/provider-applications/me/current-step',
      body: {'step': step},
    );
  }

  Future<Readiness> getReadiness() async {
    final data = await _client.get<Map<String, dynamic>>(
      '/provider-applications/me/readiness',
    );
    final missing = <({String code, String message})>[];
    for (final item in (data['missingRequirements'] as List? ?? const [])) {
      if (item is Map<String, dynamic>) {
        missing.add((
          code: item['code'] as String? ?? '',
          message: item['message'] as String? ?? '',
        ));
      }
    }
    return Readiness(
      isReady: data['isReady'] as bool? ?? false,
      completionPercentage: data['completionPercentage'] as int? ?? 0,
      missing: missing,
    );
  }

  Future<void> submitApplication() async {
    await _client.post<dynamic>('/provider-applications/me/submit');
  }

  // ── Offerings, areas, availability ─────────────────────────────────────

  Future<List<Map<String, dynamic>>> getOfferings() async {
    final data = await _client.get<List<dynamic>>('/provider-offerings');
    return data.cast<Map<String, dynamic>>();
  }

  Future<String> createOffering(Map<String, dynamic> body) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/provider-offerings',
      body: body,
    );
    return data['id'] as String;
  }

  Future<void> updateOffering(String id, Map<String, dynamic> body) async {
    await _client.put<dynamic>('/provider-offerings/$id', body: body);
  }

  Future<List<Map<String, dynamic>>> getServiceAreas() async {
    final data = await _client.get<List<dynamic>>('/provider-service-areas');
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> addServiceArea({
    required String serviceAreaId,
    double? maximumTravelDistanceKm,
    bool supportsEmergency = false,
    bool supportsSameDay = true,
  }) async {
    await _client.post<dynamic>(
      '/provider-service-areas',
      body: {
        'serviceAreaId': serviceAreaId,
        'maximumTravelDistanceKm': maximumTravelDistanceKm,
        'supportsEmergency': supportsEmergency,
        'supportsSameDay': supportsSameDay,
      },
    );
  }

  Future<void> removeServiceArea(String id) =>
      _client.delete<dynamic>('/provider-service-areas/$id');

  /// Full replace of the weekly pattern.
  Future<void> setAvailability(List<Map<String, dynamic>> rules) async {
    await _client.put<dynamic>(
      '/provider-availability/rules',
      body: {'rules': rules},
    );
  }

  // ── Portfolio, documents, standards ────────────────────────────────────

  Future<void> addPortfolioItem({
    required String title,
    required String storageKey,
    required String contentType,
    String? serviceCategoryId,
    String? description,
  }) async {
    await _client.post<dynamic>(
      '/provider-portfolio',
      body: {
        'serviceCategoryId': serviceCategoryId,
        'title': title,
        'description': description,
        'storageKey': storageKey,
        'contentType': contentType,
        'projectCompletedAt': null,
      },
    );
  }

  Future<List<RemoteDocument>> getDocuments() async {
    final data = await _client.get<List<dynamic>>(
      '/provider-verification-documents',
    );
    return [
      for (final item in data.cast<Map<String, dynamic>>())
        RemoteDocument(
          id: item['id'] as String,
          documentType: item['documentType'] as String,
          storageKey: item['storageKey'] as String? ?? '',
          reviewStatus: item['reviewStatus'] as String? ?? 'Pending',
          reviewNote: item['reviewNote'] as String?,
        ),
    ];
  }

  Future<void> addDocument({
    required String documentType,
    required String storageKey,
    required String fileName,
    required String contentType,
    required int sizeBytes,
  }) async {
    await _client.post<dynamic>(
      '/provider-verification-documents',
      body: {
        'documentType': documentType,
        'storageKey': storageKey,
        'fileName': fileName,
        'contentType': contentType,
        'sizeBytes': sizeBytes,
      },
    );
  }

  Future<void> acceptStandards() async {
    await _client.post<dynamic>('/provider-standards/current/accept');
  }

  // ── Payout ─────────────────────────────────────────────────────────────

  Future<void> addPayoutMethod({
    required String methodType,
    required String providerName,
    required String accountName,
    required String accountNumber,
  }) async {
    await _client.post<dynamic>(
      '/payout-methods',
      body: {
        'methodType': methodType,
        'providerName': providerName,
        'accountName': accountName,
        'accountNumber': accountNumber,
        'makeDefault': true,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getPayoutMethods() async {
    final data = await _client.get<List<dynamic>>('/payout-methods');
    return data.cast<Map<String, dynamic>>();
  }

  // ── Media ──────────────────────────────────────────────────────────────

  /// Runs the three-step upload: request a ticket, PUT the bytes, confirm.
  /// Returns the storage key to attach to a portfolio item or document.
  Future<String> uploadFile({
    required String purpose,
    required String fileName,
    required String contentType,
    required List<int> bytes,
  }) async {
    final ticket = await _client.post<Map<String, dynamic>>(
      '/media/upload-requests',
      body: {
        'purpose': purpose,
        'fileName': fileName,
        'contentType': contentType,
        'sizeBytes': bytes.length,
      },
    );
    final storageKey = ticket['storageKey'] as String;
    await _client.putBytes(ticket['uploadUrl'] as String, bytes, contentType);
    await _client.post<dynamic>(
      '/media/uploads/confirm',
      body: {'storageKey': storageKey},
    );
    return storageKey;
  }
}
