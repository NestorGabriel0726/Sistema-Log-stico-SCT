import '../models.dart';

abstract class AllocationsRepository {
  Future<List<Allocation>> listForEvent(String eventId, {bool activeOnly = true});

  Future<List<Allocation>> listForVehicleDay(String vehicleId, String dayId);

  Future<StoreResult> allocate({
    required String passengerId,
    required String vehicleId,
    required String dayId,
    String? stopId,
  });

  Future<StoreResult> relocate({
    required String allocationId,
    required String targetVehicleId,
    String? targetStopId,
    bool confirmed = false,
  });

  Future<StoreResult> markDesisted({
    required String allocationId,
    PassengerDraft? substitute,
    bool confirmRelocate = false,
  });

  Stream<List<Allocation>> watchForEvent(String eventId);
}
