import '../../domain/models.dart';
import '../../domain/repositories/check_in_repository.dart';
import '../local_app_store.dart';
import 'store_change_stream.dart';

class LocalCheckInRepository implements CheckInRepository {
  LocalCheckInRepository(this._store);

  final LocalAppStore _store;

  @override
  Future<bool> hasCheckIn(String allocationId, String direction) async {
    return _store.hasCheckIn(allocationId, direction);
  }

  @override
  Future<StoreResult> performCheckIn(String allocationId, String direction) async {
    return _store.performCheckIn(allocationId, direction);
  }

  @override
  Future<StoreResult> revertCheckIn(String allocationId, String direction) async {
    return _store.revertCheckIn(allocationId, direction);
  }

  @override
  Stream<List<CheckInRecord>> watchCheckIns(String eventId) {
    return storeChangeStream(_store, () {
      final ids = _store
          .allocationsForEvent(eventId, activeOnly: false)
          .map((a) => a.id)
          .toSet();
      return _store.checkIns
          .where((c) => ids.contains(c.allocationId))
          .toList();
    });
  }
}
