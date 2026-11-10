import '../../domain/models.dart';
import '../../domain/repositories/allocations_repository.dart';
import '../local_app_store.dart';
import 'store_change_stream.dart';

class LocalAllocationsRepository implements AllocationsRepository {
  LocalAllocationsRepository(this._store);

  final LocalAppStore _store;

  @override
  Future<List<Allocation>> listForEvent(
    String eventId, {
    bool activeOnly = true,
  }) async {
    return _store.allocationsForEvent(eventId, activeOnly: activeOnly);
  }

  @override
  Future<List<Allocation>> listForVehicleDay(
    String vehicleId,
    String dayId,
  ) async {
    return _store.allocationsForVehicleDay(vehicleId, dayId);
  }

  @override
  Future<StoreResult> allocate({
    required String passengerId,
    required String vehicleId,
    required String dayId,
    String? stopId,
  }) async {
    return _store.allocate(
      passengerId: passengerId,
      vehicleId: vehicleId,
      dayId: dayId,
      stopId: stopId,
    );
  }

  @override
  Future<StoreResult> relocate({
    required String allocationId,
    required String targetVehicleId,
    String? targetStopId,
    bool confirmed = false,
  }) async {
    return _store.relocate(
      allocationId: allocationId,
      targetVehicleId: targetVehicleId,
      targetStopId: targetStopId,
      confirmed: confirmed,
    );
  }

  @override
  Future<StoreResult> markDesisted({
    required String allocationId,
    PassengerDraft? substitute,
    bool confirmRelocate = false,
  }) async {
    return _store.markDesisted(
      allocationId: allocationId,
      substitute: substitute,
      confirmRelocate: confirmRelocate,
    );
  }

  @override
  Stream<List<Allocation>> watchForEvent(String eventId) {
    return storeChangeStream(
      _store,
      () => _store.allocationsForEvent(eventId, activeOnly: false),
    );
  }
}
