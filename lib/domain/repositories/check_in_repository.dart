import '../models.dart';

abstract class CheckInRepository {
  Future<bool> hasCheckIn(String allocationId, String direction);

  Future<StoreResult> performCheckIn(String allocationId, String direction);

  Future<StoreResult> revertCheckIn(String allocationId, String direction);

  Stream<List<CheckInRecord>> watchCheckIns(String eventId);
}
