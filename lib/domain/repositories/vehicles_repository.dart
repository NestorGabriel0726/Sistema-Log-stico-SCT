import '../models.dart';

abstract class VehiclesRepository {
  Future<List<Vehicle>> listVehicles(String eventId);

  Future<Vehicle?> getVehicle(String id);

  Future<StoreResult> addVehicle({
    required String eventId,
    required String name,
    required VehicleType type,
    required int physicalCapacity,
    required int localCapacity,
    List<VehicleStop> stops = const [],
  });

  Future<StoreResult> updateVehicle(
    Vehicle vehicle, {
    Map<String, String>? reassignStops,
  });

  Stream<List<Vehicle>> watchVehicles(String eventId);
}
