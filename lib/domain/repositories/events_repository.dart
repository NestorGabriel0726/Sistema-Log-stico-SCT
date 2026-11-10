import '../models.dart';

abstract class EventsRepository {
  Future<List<TransportEvent>> listEvents({bool includeDeleted = false});

  Future<TransportEvent?> getEvent(String id, {bool includeDeleted = false});

  Future<List<EventDay>> daysForEvent(String eventId);

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
  });

  Future<StoreResult> updateEvent(TransportEvent event);

  Future<EventDeletionImpact> describeDeletionImpact(String eventId);

  Future<StoreResult> deleteEvent(String id, {bool confirmed = false});

  Stream<List<TransportEvent>> watchEvents({bool includeDeleted = false});
}
