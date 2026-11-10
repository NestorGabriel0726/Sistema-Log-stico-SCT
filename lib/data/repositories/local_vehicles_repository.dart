import '../../domain/models.dart';
import '../../domain/repositories/vehicles_repository.dart';
import '../local_app_store.dart';
import 'store_change_stream.dart';

class LocalVehiclesRepository implements VehiclesRepository {
  LocalVehiclesRepository(this._store);

  final LocalAppStore _store;

  @override
  Future<List<Vehicle>> listVehicles(String eventId) async {
    return _store.vehiclesForEvent(eventId);
  }

  @override
  Future<Vehicle?> getVehicle(String id) async {
    return _store.vehicleById(id);
  }

  @override
  Future<StoreResult> addVehicle({
    required String eventId,
    required String name,
    required VehicleType type,
    required int physicalCapacity,
    required int localCapacity,
    List<VehicleStop> stops = const [],
  }) async {
    return _store.addVehicle(
      eventId: eventId,
      name: name,
      type: type,
      physicalCapacity: physicalCapacity,
      localCapacity: localCapacity,
      stops: stops,
    );
  }

  @override
  Future<StoreResult> updateVehicle(
    Vehicle vehicle, {
    Map<String, String>? reassignStops,
  }) async {
    return _store.updateVehicle(vehicle, reassignStops: reassignStops);
  }

  @override
  Stream<List<Vehicle>> watchVehicles(String eventId) {
    return storeChangeStream(_store, () => _store.vehiclesForEvent(eventId));
  }
}
