import '../../domain/models.dart';
import '../../domain/repositories/events_repository.dart';
import '../local_app_store.dart';
import 'store_change_stream.dart';

class LocalEventsRepository implements EventsRepository {
  LocalEventsRepository(this._store);

  final LocalAppStore _store;

  @override
  Future<List<TransportEvent>> listEvents({bool includeDeleted = false}) async {
    return _store.listEvents(includeDeleted: includeDeleted);
  }

  @override
  Future<TransportEvent?> getEvent(String id, {bool includeDeleted = false}) async {
    return _store.eventById(id, includeDeleted: includeDeleted);
  }

  @override
  Future<List<EventDay>> daysForEvent(String eventId) async {
    return _store.daysForEvent(eventId);
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
    return _store.createEvent(
      theme: theme,
      kind: kind,
      start: start,
      end: end,
      dailyFareCents: dailyFareCents,
      minimumPayingAge: minimumPayingAge,
      passageDeadline: passageDeadline,
      preliminaryListDeadline: preliminaryListDeadline,
      finalListDeadline: finalListDeadline,
    );
  }

  @override
  Future<StoreResult> updateEvent(TransportEvent event) async {
    return _store.updateEvent(event);
  }

  @override
  Future<EventDeletionImpact> describeDeletionImpact(String eventId) async {
    return _store.describeEventDeletionImpact(eventId);
  }

  @override
  Future<StoreResult> deleteEvent(String id, {bool confirmed = false}) async {
    return _store.deleteEvent(id, confirmed: confirmed);
  }

  @override
  Stream<List<TransportEvent>> watchEvents({bool includeDeleted = false}) {
    return storeChangeStream(
      _store,
      () => _store.listEvents(includeDeleted: includeDeleted),
    );
  }
}
