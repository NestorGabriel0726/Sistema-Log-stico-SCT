import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models.dart';
import '../../domain/repositories/check_in_repository.dart';
import 'supabase_error_mapper.dart';
import 'supabase_mappers.dart';
import 'supabase_realtime.dart';

class SupabaseCheckInRepository implements CheckInRepository {
  SupabaseCheckInRepository(this._client);

  final SupabaseClient _client;

  String _direction(String raw) =>
      raw.toUpperCase() == 'RETURN' ? 'RETURN' : 'OUTBOUND';

  @override
  Future<bool> hasCheckIn(String allocationId, String direction) async {
    final row = await _client
        .from('check_ins')
        .select('id')
        .eq('passenger_allocation_id', allocationId)
        .eq('trip_direction', _direction(direction))
        .maybeSingle();
    return row != null;
  }

  @override
  Future<StoreResult> performCheckIn(String allocationId, String direction) async {
    try {
      await _client.rpc(
        'perform_checkin',
        params: {
          'p_allocation_id': allocationId,
          'p_trip_direction': _direction(direction),
        },
      );
      return const StoreResult.ok();
    } catch (e) {
      return mapSupabaseError(e);
    }
  }

  @override
  Future<StoreResult> revertCheckIn(String allocationId, String direction) async {
    try {
      await _client.rpc(
        'revert_checkin',
        params: {
          'p_allocation_id': allocationId,
          'p_trip_direction': _direction(direction),
        },
      );
      return const StoreResult.ok();
    } catch (e) {
      return mapSupabaseError(e);
    }
  }

  @override
  Stream<List<CheckInRecord>> watchCheckIns(String eventId) async* {
    yield await _list(eventId);
    final hub = SupabaseRealtimeHub(_client);
    await for (final _ in hub.watchTables(['check_ins'])) {
      yield await _list(eventId);
    }
  }

  Future<List<CheckInRecord>> _list(String eventId) async {
    final rows = await _client
        .from('check_ins')
        .select(
          '*, passenger_allocations!inner(passenger_days!inner(event_passengers!inner(event_id)))',
        )
        .eq(
          'passenger_allocations.passenger_days.event_passengers.event_id',
          eventId,
        );
    return (rows as List)
        .whereType<Map<String, dynamic>>()
        .map(checkInFromRow)
        .toList();
  }
}
