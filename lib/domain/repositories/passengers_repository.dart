import '../models.dart';

abstract class PassengersRepository {
  Future<List<Passenger>> listPassengers(String eventId);

  Future<Passenger?> getPassenger(String id);

  Future<StoreResult> updatePassengerDays({
    required String passengerId,
    required List<String> dayIds,
  });

  Stream<List<Passenger>> watchPassengers(String eventId);
}
