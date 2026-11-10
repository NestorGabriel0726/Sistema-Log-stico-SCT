import '../models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abstract repository for vehicle data.
abstract class VehiclesRepository {
  /// Returns the list of vehicles for a given event.
  Future<List<Vehicle>> listVehicles(String eventId);

  /// Retrieves a vehicle by its id.
  Future<Vehicle?> getVehicle(String id);

  /// Persists a new vehicle.
  Future<void> addVehicle(Vehicle vehicle);

  /// Updates an existing vehicle.
  Future<void> updateVehicle(Vehicle vehicle);

  /// Deletes a vehicle.
  Future<void> deleteVehicle(String id);

  /// Stream of vehicle lists for an event.
  Stream<List<Vehicle>> watchVehicles(String eventId);
}

