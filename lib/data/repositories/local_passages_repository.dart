import '../../domain/models.dart';
import '../../domain/repositories/passages_repository.dart';
import '../local_app_store.dart';
import 'store_change_stream.dart';

class LocalPassagesRepository implements PassagesRepository {
  LocalPassagesRepository(this._store);

  final LocalAppStore _store;

  @override
  Future<List<PassageGroup>> listPassages(String eventId) async {
    return _store.passagesForEvent(eventId);
  }

  @override
  Future<PassageGroup?> getPassage(String id) async {
    return _store.passageById(id);
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
    return _store.createPassage(
      eventId: eventId,
      buyerName: buyerName,
      paidCents: paidCents,
      method: method,
      passengers: passengers,
      receiptNotes: receiptNotes,
      confirmBypass: confirmBypass,
    );
  }

  @override
  Future<StoreResult> updatePassage({
    required String passageId,
    required String eventId,
    required String buyerName,
    required PaymentMethod method,
    required List<PassengerDraft> passengers,
  }) async {
    return _store.updatePassage(
      passageId: passageId,
      eventId: eventId,
      buyerName: buyerName,
      method: method,
      passengers: passengers,
    );
  }

  @override
  Future<StoreResult> addPayment({
    required String passageId,
    required int extraCents,
    required PaymentMethod method,
    String? receiptNote,
  }) async {
    return _store.addPayment(
      passageId: passageId,
      extraCents: extraCents,
      method: method,
      receiptNote: receiptNote,
    );
  }

  @override
  Stream<List<PassageGroup>> watchPassages(String eventId) {
    return storeChangeStream(_store, () => _store.passagesForEvent(eventId));
  }
}
