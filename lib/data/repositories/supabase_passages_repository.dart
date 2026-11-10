import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models.dart';
import '../../domain/repositories/passages_repository.dart';
import 'supabase_error_mapper.dart';
import 'supabase_mappers.dart';
import 'supabase_realtime.dart';

class SupabasePassagesRepository implements PassagesRepository {
  SupabasePassagesRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<PassageGroup>> listPassages(String eventId) async {
    final rows = await _client
        .from('passages')
        .select(
          '*, passage_passengers(event_passenger_id), payments(amount_cents, payment_method, notes)',
        )
        .eq('event_id', eventId)
        .neq('status', 'CANCELLED');
    return (rows as List)
        .whereType<Map<String, dynamic>>()
        .map(passageFromRow)
        .toList();
  }

  @override
  Future<PassageGroup?> getPassage(String id) async {
    final row = await _client
        .from('passages')
        .select(
          '*, passage_passengers(event_passenger_id), payments(amount_cents, payment_method, notes)',
        )
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return passageFromRow(row);
  }

  @override
  Future<StoreResult> createPassage({
    required String eventId,
    required String buyerName,
    required int paidCents,
    required PaymentMethod method,
    required List<PassengerDraft> passengers,
    List<String> receiptNotes = const [],
    bool confirmBypass = false,
  }) async {
    try {
      await _client.rpc(
        'create_passage_group',
        params: {
          'p_event_id': eventId,
          'p_buyer_name': buyerName.trim(),
          'p_paid_cents': paidCents,
          'p_payment_method': pgPaymentMethod(method),
          'p_passengers': passengers.map(passengerDraftToRpc).toList(),
          'p_notes': receiptNotes.isEmpty ? null : receiptNotes.join('\n'),
          'p_confirm_bypass': confirmBypass,
        },
      );
      return const StoreResult.ok();
    } catch (e) {
      final mapped = mapSupabaseError(e);
      if (e.toString().contains('DEADLINE_PASSED') && !confirmBypass) {
        return const StoreResult.confirm(
          'O prazo de passagens já passou. Registrar mesmo assim? A exceção será gravada no histórico.',
        );
      }
      return mapped;
    }
  }

  @override
  Future<StoreResult> updatePassage({
    required String passageId,
    required String eventId,
    required String buyerName,
    required PaymentMethod method,
    required List<PassengerDraft> passengers,
  }) async {
    try {
      await _client.rpc(
        'update_passage_group',
        params: {
          'p_passage_id': passageId,
          'p_event_id': eventId,
          'p_buyer_name': buyerName.trim(),
          'p_payment_method': pgPaymentMethod(method),
          'p_passengers': passengers.map(passengerDraftToRpc).toList(),
        },
      );
      return const StoreResult.ok();
    } catch (e) {
      return mapSupabaseError(e);
    }
  }

  @override
  Future<StoreResult> addPayment({
    required String passageId,
    required int extraCents,
    required PaymentMethod method,
    String? receiptNote,
  }) async {
    try {
      await _client.rpc(
        'record_payment',
        params: {
          'p_passage_id': passageId,
          'p_amount_cents': extraCents,
          'p_payment_method': pgPaymentMethod(method),
          'p_notes': receiptNote,
        },
      );
      return const StoreResult.ok();
    } catch (e) {
      return mapSupabaseError(e);
    }
  }

  @override
  Stream<List<PassageGroup>> watchPassages(String eventId) async* {
    yield await listPassages(eventId);
    final hub = SupabaseRealtimeHub(_client);
    await for (final _ in hub.watchTables(['passages', 'payments', 'passage_passengers'])) {
      yield await listPassages(eventId);
    }
  }
}
