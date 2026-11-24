import 'package:flutter_test/flutter_test.dart';
import 'package:grid_professionals/core/models/onboarding_models.dart';
import 'package:grid_professionals/data/country/country_config.dart';

void main() {
  test('a provider keeps the price less GRID fee, to the pesewa', () {
    const rate = PackageRate(
      group: 'Standard clean',
      name: '2 bedrooms',
      price: 250,
    );
    expect(rate.earning(15), 212.5);
    expect(rate.earning(0), 250);
    const odd = PackageRate(group: 'Laundry', name: 'Duvet', price: 49.99);
    expect(odd.earning(15), 42.49);
  });

  test('several services can be chosen; pest control asks for a licence', () {
    const draft = OnboardingDraft(
      primaryServiceId: 'cleaning',
      extraServiceIds: ['ac-servicing'],
    );
    expect(draft.serviceIds, ['cleaning', 'ac-servicing']);
    expect(draft.needsLicence, isFalse);

    final withPest = draft.copyWith(
      extraServiceIds: ['ac-servicing', 'pest-control'],
    );
    expect(withPest.needsLicence, isTrue);

    // The choice survives a restart.
    final restored = OnboardingDraft.fromJson(withPest.toJson());
    expect(restored.serviceIds, ['cleaning', 'ac-servicing', 'pest-control']);
  });
}
