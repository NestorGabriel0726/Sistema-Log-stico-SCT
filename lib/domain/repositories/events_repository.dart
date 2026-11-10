import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';

/// Abstract repository for transport events.
abstract class EventsRepository {
  /// Returns a list of events. If [includeDeleted] is true, also returns events marked as deleted.
  Future<List<TransportEvent>> listEvents({bool includeDeleted = false});

  /// Retrieves a single event by its [id]. Returns null if not found.
  Future<TransportEvent?> getEvent(String id, {bool includeDeleted = false});

  /// Persists a new [event].
  Future<void> addEvent(TransportEvent event);

  /// Updates an existing [event].
  Future<void> updateEvent(TransportEvent event);

  /// Marks an event as deleted (soft‑delete).
  Future<void> deleteEvent(String id);

  /// Stream of events that updates when the underlying store changes.
  Stream<List<TransportEvent>> watchEvents({bool includeDeleted = false});
}

