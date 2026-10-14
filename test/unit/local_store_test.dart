import 'package:flutter_test/flutter_test.dart';
import 'package:transport_logistics/data/local_app_store.dart';
import 'package:transport_logistics/data/seed_data.dart';
import 'package:transport_logistics/domain/models.dart';

void main() {
  test('seed, check-in e desistência liberam vaga', () {
    final store = LocalAppStore();
    store.signIn(name: 'Carlos', role: UserRole.coordinator);

    expect(store.listEvents().single.id, SeedData.eventId);
    expect(store.passengersForEvent(SeedData.eventId).length, 6);

    final result = store.performCheckIn('a1', 'OUTBOUND');
    expect(result.ok, isTrue);
    expect(store.hasCheckIn('a1', 'OUTBOUND'), isTrue);

    final before = store.allocationsForVehicleDay('bus-1', 'day-1').where((a) => a.isActive).length;
    store.markDesisted(allocationId: 'a1');
    final after = store.allocationsForVehicleDay('bus-1', 'day-1').where((a) => a.isActive).length;
    expect(after, before - 1);
  });

  test('isenção inválida é recusada na passagem', () {
    final store = LocalAppStore();
    store.signIn(name: 'Carlos', role: UserRole.coordinator);
    final event = store.eventById(SeedData.eventId)!;
    final err = store.validateExemption(
      category: PassengerCategory.exempt,
      birthDate: DateTime(2018, 1, 1),
      event: event,
    );
    expect(err, isNotNull);
  });
}
