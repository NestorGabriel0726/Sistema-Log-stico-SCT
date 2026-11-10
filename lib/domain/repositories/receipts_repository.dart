import '../models.dart';

abstract class ReceiptsRepository {
  Future<StoreResult> uploadReceipt({
    required String eventId,
    required String paymentId,
    required String fileName,
    required List<int> bytes,
    required String mimeType,
  });

  Future<Uri?> signedDownloadUrl(String storagePath);
}
