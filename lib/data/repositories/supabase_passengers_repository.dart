import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models.dart';
import '../../domain/repositories/passengers_repository.dart';
import 'supabase_error_mapper.dart';
import 'supabase_mappers.dart';
import 'supabase_realtime.dart';

class SupabasePassengersRepository implements PassengersRepository {
  SupabasePassengersRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Passenger>> listPassengers(String eventId) async {
    final rows = await _client
        .from('event_passengers')
        .select(
          '*, passenger_days(event_day_id), passage_passengers(passage_id)',
        )
        .eq('event_id', eventId)
        .neq('status', 'CANCELLED');
    return (rows as List)
        .whereType<Map<String, dynamic>>()
        .map(passengerFromRow)
        .toList();
  }

  @override
  Future<Passenger?> getPassenger(String id) async {
    final row = await _client
        .from('event_passengers')
        .select(
          '*, passenger_days(event_day_id), passage_passengers(passage_id)',
        )
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return passengerFromRow(row);
  }

  @override
  Future<StoreResult> updatePassengerDays({
    required String passengerId,
    required List<String> dayIds,
  }) async {
    try {
      await _client.rpc(
        'replace_passenger_days',
        params: {
          'p_event_passenger_id': passengerId,
          'p_day_ids': dayIds,
        },
      );
      return const StoreResult.ok();
    } catch (e) {
      return mapSupabaseError(e);
    }
  }

  @override
  Stream<List<Passenger>> watchPassengers(String eventId) async* {
    yield await listPassengers(eventId);
    final hub = SupabaseRealtimeHub(_client);
    await for (final _ in hub.watchTables(
      ['event_passengers', 'passenger_days', 'passage_passengers'],
    )) {
      yield await listPassengers(eventId);
    }
  }
}
