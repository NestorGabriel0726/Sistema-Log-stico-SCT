import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models.dart';
import '../../domain/repositories/receipts_repository.dart';
import 'supabase_error_mapper.dart';

class SupabaseReceiptsRepository implements ReceiptsRepository {
  SupabaseReceiptsRepository(this._client);

  final SupabaseClient _client;
  static const bucket = 'payment-receipts';

  @override
  Future<StoreResult> uploadReceipt({
    required String eventId,
    required String paymentId,
    required String fileName,
    required List<int> bytes,
    required String mimeType,
  }) async {
    final path = '$eventId/$paymentId/$fileName';
    try {
      await _client.storage.from(bucket).uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: FileOptions(contentType: mimeType, upsert: false),
          );
      await _client.from('payment_receipts').insert({
        'payment_id': paymentId,
        'storage_path': path,
        'file_name': fileName,
        'mime_type': mimeType,
        'uploaded_by': _client.auth.currentUser?.id,
      });
      return StoreResult.ok(path);
    } catch (e) {
      return mapSupabaseError(e);
    }
  }

  @override
  Future<Uri?> signedDownloadUrl(String storagePath) async {
    try {
      final url = await _client.storage.from(bucket).createSignedUrl(
            storagePath,
            60 * 10,
          );
      return Uri.tryParse(url);
    } catch (_) {
      return null;
    }
  }
}
