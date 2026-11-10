import '../models.dart';

abstract class PassagesRepository {
  Future<List<PassageGroup>> listPassages(String eventId);

  Future<PassageGroup?> getPassage(String id);

  Future<StoreResult> createPassage({
    required String eventId,
    required String buyerName,
    required int paidCents,
    required PaymentMethod method,
    required List<PassengerDraft> passengers,
    List<String> receiptNotes = const [],
    bool confirmBypass = false,
  });

  Future<StoreResult> updatePassage({
    required String passageId,
    required String eventId,
    required String buyerName,
    required PaymentMethod method,
    required List<PassengerDraft> passengers,
  });

  Future<StoreResult> addPayment({
    required String passageId,
    required int extraCents,
    required PaymentMethod method,
    String? receiptNote,
  });

  Stream<List<PassageGroup>> watchPassages(String eventId);
}
