import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models.dart';
import '../../domain/repositories/vehicles_repository.dart';
import 'supabase_error_mapper.dart';
import 'supabase_mappers.dart';
import 'supabase_realtime.dart';

class SupabaseVehiclesRepository implements VehiclesRepository {
  SupabaseVehiclesRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Vehicle>> listVehicles(String eventId) async {
    final rows = await _client
        .from('vehicles')
        .select('*, vehicle_stops(*)')
        .eq('event_id', eventId)
        .neq('status', 'INACTIVE')
        .order('name');
    return (rows as List)
        .whereType<Map<String, dynamic>>()
        .map(vehicleFromRow)
        .toList();
  }

  @override
  Future<Vehicle?> getVehicle(String id) async {
    final row = await _client
        .from('vehicles')
        .select('*, vehicle_stops(*)')
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return vehicleFromRow(row);
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
    try {
      await _client.rpc(
        'upsert_vehicle_with_stops',
        params: {
          'p_vehicle_id': null,
          'p_event_id': eventId,
          'p_name': name.trim(),
          'p_type': pgVehicleType(type),
          'p_physical_capacity': physicalCapacity,
          'p_local_capacity': localCapacity,
          'p_stops': stops
              .map((s) => {
                    'id': s.id,
                    'name': s.name,
                    'reference': s.reference,
                    'sequence': s.sequence,
                  })
              .toList(),
          'p_reassign_stops': <String, String>{},
        },
      );
      return const StoreResult.ok();
    } catch (e) {
      return mapSupabaseError(e);
    }
  }

  @override
  Future<StoreResult> updateVehicle(
    Vehicle vehicle, {
    Map<String, String>? reassignStops,
  }) async {
    try {
      await _client.rpc(
        'upsert_vehicle_with_stops',
        params: {
          'p_vehicle_id': vehicle.id,
          'p_event_id': vehicle.eventId,
          'p_name': vehicle.name,
          'p_type': pgVehicleType(vehicle.type),
          'p_physical_capacity': vehicle.physicalCapacity,
          'p_local_capacity': vehicle.localCapacity,
          'p_stops': vehicle.stops
              .map((s) => {
                    'id': s.id,
                    'name': s.name,
                    'reference': s.reference,
                    'sequence': s.sequence,
                  })
              .toList(),
          'p_reassign_stops': reassignStops ?? <String, String>{},
        },
      );
      return const StoreResult.ok();
    } catch (e) {
      return mapSupabaseError(e);
    }
  }

  @override
  Stream<List<Vehicle>> watchVehicles(String eventId) async* {
    yield await listVehicles(eventId);
    final hub = SupabaseRealtimeHub(_client);
    await for (final _ in hub.watchTables(['vehicles', 'vehicle_stops'])) {
      yield await listVehicles(eventId);
    }
  }
}
