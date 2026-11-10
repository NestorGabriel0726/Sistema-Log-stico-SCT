import '../../domain/models.dart';
import '../../domain/repositories/passengers_repository.dart';
import '../local_app_store.dart';
import 'store_change_stream.dart';

class LocalPassengersRepository implements PassengersRepository {
  LocalPassengersRepository(this._store);

  final LocalAppStore _store;

  @override
  Future<List<Passenger>> listPassengers(String eventId) async {
    return _store.passengersForEvent(eventId);
  }

  @override
  Future<Passenger?> getPassenger(String id) async {
    return _store.passengerById(id);
  }

  @override
  Future<StoreResult> updatePassengerDays({
    required String passengerId,
    required List<String> dayIds,
  }) async {
    return _store.updatePassengerDays(passengerId: passengerId, dayIds: dayIds);
  }

  @override
  Stream<List<Passenger>> watchPassengers(String eventId) {
    return storeChangeStream(_store, () => _store.passengersForEvent(eventId));
  }
}
