import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models.dart';
import '../../domain/repositories/allocations_repository.dart';
import 'supabase_error_mapper.dart';
import 'supabase_mappers.dart';
import 'supabase_realtime.dart';

class SupabaseAllocationsRepository implements AllocationsRepository {
  SupabaseAllocationsRepository(this._client);

  final SupabaseClient _client;

  Future<String?> _passengerDayId(String passengerId, String dayId) async {
    final row = await _client
        .from('passenger_days')
        .select('id')
        .eq('event_passenger_id', passengerId)
        .eq('event_day_id', dayId)
        .maybeSingle();
    return row == null ? null : '${row['id']}';
  }

  @override
  Future<List<Allocation>> listForEvent(
    String eventId, {
    bool activeOnly = true,
  }) async {
    var query = _client
        .from('passenger_allocations')
        .select(
          '*, passenger_days!inner(event_day_id, event_passenger_id, event_passengers!inner(event_id))',
        )
        .eq('passenger_days.event_passengers.event_id', eventId);
    if (activeOnly) {
      query = query.eq('status', 'ACTIVE');
    }
    final rows = await query;
    return (rows as List)
        .whereType<Map<String, dynamic>>()
        .map(allocationFromRow)
        .toList();
  }

  @override
  Future<List<Allocation>> listForVehicleDay(
    String vehicleId,
    String dayId,
  ) async {
    final rows = await _client
        .from('passenger_allocations')
        .select(
          '*, passenger_days!inner(event_day_id, event_passenger_id)',
        )
        .eq('vehicle_id', vehicleId)
        .eq('passenger_days.event_day_id', dayId)
        .order('position');
    return (rows as List)
        .whereType<Map<String, dynamic>>()
        .map(allocationFromRow)
        .toList();
  }

  @override
  Future<StoreResult> allocate({
    required String passengerId,
    required String vehicleId,
    required String dayId,
    String? stopId,
  }) async {
    try {
      final passengerDayId = await _passengerDayId(passengerId, dayId);
      if (passengerDayId == null) {
        return const StoreResult.error('Este passageiro não viaja neste dia.');
      }
      await _client.rpc(
        'allocate_passenger',
        params: {
          'p_passenger_day_id': passengerDayId,
          'p_vehicle_id': vehicleId,
          'p_stop_id': stopId,
        },
      );
      return const StoreResult.ok();
    } catch (e) {
      return mapSupabaseError(e);
    }
  }

  @override
  Future<StoreResult> relocate({
    required String allocationId,
    required String targetVehicleId,
    String? targetStopId,
    bool confirmed = false,
  }) async {
    if (!confirmed) {
      return const StoreResult.confirm('Confirmar a realocação do passageiro?');
    }
    try {
      await _client.rpc(
        'relocate_passenger',
        params: {
          'p_current_allocation_id': allocationId,
          'p_target_vehicle_id': targetVehicleId,
          'p_stop_id': targetStopId,
        },
      );
      return const StoreResult.ok();
    } catch (e) {
      return mapSupabaseError(e);
    }
  }

  @override
  Future<StoreResult> markDesisted({
    required String allocationId,
    PassengerDraft? substitute,
    bool confirmRelocate = false,
  }) async {
    try {
      await _client.rpc(
        'mark_passenger_desisted',
        params: {
          'p_allocation_id': allocationId,
          'p_reason': substitute == null ? 'Desistência' : 'Substituição',
        },
      );
      return const StoreResult.ok();
    } catch (e) {
      return mapSupabaseError(e);
    }
  }

  @override
  Stream<List<Allocation>> watchForEvent(String eventId) async* {
    yield await listForEvent(eventId, activeOnly: false);
    final hub = SupabaseRealtimeHub(_client);
    await for (final _ in hub.watchTables(['passenger_allocations'])) {
      yield await listForEvent(eventId, activeOnly: false);
    }
  }
}
