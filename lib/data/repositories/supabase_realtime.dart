import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Subscribes to Postgres changes and cancels channels on dispose.
class SupabaseRealtimeHub {
  SupabaseRealtimeHub(this._client);

  final SupabaseClient _client;
  final _channels = <RealtimeChannel>[];

  Stream<void> watchTables(List<String> tables, {String? filter}) {
    late StreamController<void> controller;
    controller = StreamController<void>.broadcast(
      onCancel: () async {
        await _removeOwnedChannels();
      },
    );

    for (final table in tables) {
      var channel = _client.channel(
        'sct-$table-${identityHashCode(this)}-${DateTime.now().microsecondsSinceEpoch}',
      );
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        filter: filter == null
            ? null
            : PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: filter.split('=')[0],
                value: filter.split('=')[1],
              ),
        callback: (_) {
          if (!controller.isClosed) controller.add(null);
        },
      );
      channel.subscribe();
      _channels.add(channel);
    }

    return controller.stream;
  }

  Future<void> _removeOwnedChannels() async {
    for (final channel in List<RealtimeChannel>.from(_channels)) {
      await _client.removeChannel(channel);
    }
    _channels.clear();
  }

  Future<void> dispose() => _removeOwnedChannels();
}
