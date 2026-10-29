import '../core/db.dart';
import '../core/ids.dart';

/// Version 1 is offline-only: nothing here talks to the network.
///
/// This class is the hand-off point for the backend you build later. It
/// collects every row changed locally (synced = 0) in the exact JSON shape
/// described in docs/BACKEND_SYNC.md, and marks rows as synced once the
/// server has accepted them. A future SyncService only has to:
///   1. payload = await SyncOutbox().buildPushPayload();
///   2. POST payload to /api/v1/sync/push
///   3. await SyncOutbox().markSynced(payload);
///   4. GET /api/v1/sync/pull?since=<last_pull_at> and applyPulled(...)
class SyncOutbox {
  SyncOutbox([AppDatabase? db]) : _db = db ?? AppDatabase.instance;
  final AppDatabase _db;

  Future<int> pendingCount() async {
    var n = 0;
    for (final t in syncedTables) {
      final r = await _db.db.rawQuery('SELECT COUNT(*) AS n FROM $t WHERE synced = 0');
      n += r.first['n'] as int;
    }
    return n;
  }

  Future<Map<String, Object?>> buildPushPayload({int maxRowsPerTable = 500}) async {
    final changes = <String, Object?>{};
    for (final t in syncedTables) {
      final rows = await _db.db.query(t, where: 'synced = 0', orderBy: 'updated_at', limit: maxRowsPerTable);
      if (rows.isNotEmpty) {
        changes[t] = rows.map((r) => Map.of(r)..remove('synced')).toList();
      }
    }
    return {
      'device_id': await _db.meta('device_id'),
      'schema_version': AppDatabase.schemaVersion,
      'sent_at': nowMs(),
      'changes': changes,
    };
  }

  /// Only marks a row synced if it was not modified again after being sent.
  Future<void> markSynced(Map<String, Object?> payload) async {
    final changes = (payload['changes'] as Map).cast<String, Object?>();
    await _db.db.transaction((txn) async {
      for (final entry in changes.entries) {
        for (final row in (entry.value as List).cast<Map>()) {
          await txn.update(entry.key, {'synced': 1},
              where: 'id = ? AND updated_at = ?', whereArgs: [row['id'], row['updated_at']]);
        }
      }
    });
  }

  /// Applies rows from the server (last-write-wins on updated_at).
  Future<void> applyPulled(Map<String, Object?> changes) async {
    await _db.db.transaction((txn) async {
      await txn.execute('PRAGMA defer_foreign_keys = ON');
      for (final t in syncedTables) {
        for (final raw in (changes[t] as List? ?? const []).cast<Map>()) {
          final row = raw.cast<String, Object?>();
          final local = await txn.query(t, columns: ['updated_at'], where: 'id = ?', whereArgs: [row['id']]);
          if (local.isEmpty) {
            await txn.insert(t, {...row, 'synced': 1});
          } else if ((row['updated_at'] as int) > (local.first['updated_at'] as int)) {
            await txn.update(t, {...row, 'synced': 1}, where: 'id = ?', whereArgs: [row['id']]);
          }
        }
      }
    });
  }
}
