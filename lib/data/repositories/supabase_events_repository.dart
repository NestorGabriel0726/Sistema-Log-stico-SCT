import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models.dart';
import '../../domain/repositories/events_repository.dart';
import 'supabase_error_mapper.dart';
import 'supabase_mappers.dart';
import 'supabase_realtime.dart';

class SupabaseEventsRepository implements EventsRepository {
  SupabaseEventsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<TransportEvent>> listEvents({bool includeDeleted = false}) async {
    var query = _client.from('events').select();
    if (!includeDeleted) {
      query = query.neq('status', 'ARCHIVED');
    }
    final rows = await query.order('start_date');
    return (rows as List)
        .whereType<Map<String, dynamic>>()
        .map(eventFromRow)
        .toList();
  }

  @override
  Future<TransportEvent?> getEvent(String id, {bool includeDeleted = false}) async {
    final row =
        await _client.from('events').select().eq('id', id).maybeSingle();
    if (row == null) return null;
    final event = eventFromRow(row);
    if (!includeDeleted && event.isDeleted) return null;
    return event;
  }

  @override
  Future<List<EventDay>> daysForEvent(String eventId) async {
    final rows = await _client
        .from('event_days')
        .select()
        .eq('event_id', eventId)
        .order('sequence_order');
    return (rows as List)
        .whereType<Map<String, dynamic>>()
        .map(eventDayFromRow)
        .toList();
  }

  @override
  Future<StoreResult> createEvent({
    required String theme,
    required EventKind kind,
    required DateTime start,
    required DateTime end,
    required int dailyFareCents,
    int minimumPayingAge = 6,
    DateTime? passageDeadline,
    DateTime? preliminaryListDeadline,
    DateTime? finalListDeadline,
  }) async {
    try {
      final data = await _client.rpc(
        'create_transport_event',
        params: {
          'p_theme': theme.trim(),
          'p_type': pgEventType(kind),
          'p_start_date': start.toIso8601String().split('T').first,
          'p_end_date': end.toIso8601String().split('T').first,
          'p_daily_fare_cents': dailyFareCents,
          'p_minimum_paying_age': minimumPayingAge,
          'p_passage_deadline': passageDeadline?.toIso8601String(),
          'p_preliminary_list_deadline':
              preliminaryListDeadline?.toIso8601String(),
          'p_final_list_deadline': finalListDeadline?.toIso8601String(),
        },
      );
      final id = data is Map ? data['event_id'] : null;
      return StoreResult.ok(id?.toString() ?? 'OK');
    } catch (e) {
      return mapSupabaseError(e);
    }
  }

  @override
  Future<StoreResult> updateEvent(TransportEvent event) async {
    try {
      await _client.rpc(
        'update_transport_event',
        params: {
          'p_event_id': event.id,
          'p_theme': event.theme,
          'p_type': pgEventType(event.kind),
          'p_start_date': event.startDate.toIso8601String().split('T').first,
          'p_end_date': event.endDate.toIso8601String().split('T').first,
          'p_daily_fare_cents': event.dailyFareCents,
          'p_minimum_paying_age': event.minimumPayingAge,
          'p_passage_deadline': event.passageDeadline?.toIso8601String(),
          'p_preliminary_list_deadline':
              event.preliminaryListDeadline?.toIso8601String(),
          'p_final_list_deadline': event.finalListDeadline?.toIso8601String(),
          'p_captain_checkin_enabled': event.captainCheckinEnabled,
          'p_helper_checkin_enabled': event.helperCheckinEnabled,
          'p_status': pgEventStatus(event),
        },
      );
      return const StoreResult.ok();
    } catch (e) {
      return mapSupabaseError(e);
    }
  }

  @override
  Future<EventDeletionImpact> describeDeletionImpact(String eventId) async {
    final event = await getEvent(eventId, includeDeleted: true);
    final passengers = await _client
        .from('event_passengers')
        .select('id')
        .eq('event_id', eventId);
    final passages =
        await _client.from('passages').select('id').eq('event_id', eventId);
    final vehicles =
        await _client.from('vehicles').select('id').eq('event_id', eventId);
    final payments = await _client
        .from('payments')
        .select('amount_cents, passages!inner(event_id)')
        .eq('passages.event_id', eventId);
    var paid = 0;
    if (payments is List) {
      for (final row in payments) {
        if (row is Map) {
          paid += (row['amount_cents'] as num?)?.toInt() ?? 0;
        }
      }
    }
    return EventDeletionImpact(
      eventTheme: event?.theme ?? '',
      passengerCount: (passengers as List).length,
      passageCount: (passages as List).length,
      vehicleCount: (vehicles as List).length,
      allocationCount: 0,
      checkInCount: 0,
      paidCents: paid,
      hasFinancialRecords: paid > 0,
    );
  }

  @override
  Future<StoreResult> deleteEvent(String id, {bool confirmed = false}) async {
    if (!confirmed) {
      final impact = await describeDeletionImpact(id);
      return StoreResult.confirm(
        impact.hasFinancialRecords
            ? 'Este evento possui registros financeiros. O arquivamento preservará o histórico.'
            : 'Deseja realmente arquivar este evento?',
      );
    }
    try {
      await _client.rpc('archive_transport_event', params: {'p_event_id': id});
      return const StoreResult.ok();
    } catch (e) {
      return mapSupabaseError(e);
    }
  }

  @override
  Stream<List<TransportEvent>> watchEvents({bool includeDeleted = false}) async* {
    yield await listEvents(includeDeleted: includeDeleted);
    final hub = SupabaseRealtimeHub(_client);
    await for (final _ in hub.watchTables(['events', 'event_days'])) {
      yield await listEvents(includeDeleted: includeDeleted);
    }
  }
}
