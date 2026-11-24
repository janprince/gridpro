import 'package:flutter/material.dart';

/// The services GRID Pro supports at launch. Each has its own tint (see
/// `ServiceKindStyle.palette`) so a job's service reads before any text.
enum ServiceKind { cleaning, laundry, acServicing, pestControl }

extension ServiceKindInfo on ServiceKind {
  String get label => switch (this) {
    ServiceKind.cleaning => 'Home cleaning',
    ServiceKind.laundry => 'Laundry',
    ServiceKind.acServicing => 'AC servicing',
    ServiceKind.pestControl => 'Pest control',
  };

  /// Collected and brought back rather than done in one visit.
  bool get collected => this == ServiceKind.laundry;

  /// Catalogue slug, shared with the GRID API.
  String get id => switch (this) {
    ServiceKind.cleaning => 'cleaning',
    ServiceKind.laundry => 'laundry',
    ServiceKind.acServicing => 'ac-servicing',
    ServiceKind.pestControl => 'pest-control',
  };

  IconData get icon => switch (this) {
    ServiceKind.cleaning => Icons.cleaning_services_rounded,
    ServiceKind.laundry => Icons.local_laundry_service_rounded,
    ServiceKind.acServicing => Icons.ac_unit_rounded,
    ServiceKind.pestControl => Icons.pest_control_rounded,
  };

  /// Maps a catalogue id or category name onto a service, if it is one.
  static ServiceKind? fromName(String? value) {
    final name = (value ?? '').toLowerCase();
    if (name.startsWith('ac-') ||
        name.contains('air con') ||
        name.startsWith('ac ')) {
      return ServiceKind.acServicing;
    }
    if (name.contains('pest') || name.contains('fumig')) {
      return ServiceKind.pestControl;
    }
    if (name.contains('laundr') || name.contains('wash')) {
      return ServiceKind.laundry;
    }
    if (name.contains('clean')) return ServiceKind.cleaning;
    return null;
  }
}
