import '../../domain/models.dart';
import '../../domain/repositories/receipts_repository.dart';

class LocalReceiptsRepository implements ReceiptsRepository {
  @override
  Future<StoreResult> uploadReceipt({
    required String eventId,
    required String paymentId,
    required String fileName,
    required List<int> bytes,
    required String mimeType,
  }) async {
    return const StoreResult.error(
      'O envio de arquivos de comprovante está disponível no modo Supabase. '
      'No modo local, registre o comprovante como nota na passagem.',
    );
  }

  @override
  Future<Uri?> signedDownloadUrl(String storagePath) async => null;
}
