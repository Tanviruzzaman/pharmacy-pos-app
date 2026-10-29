import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/db.dart';
import '../core/ids.dart';
import 'shop_settings.dart';

/// Backup = one JSON file containing every row of every synced table.
/// The format is the same shape as the sync push payload in docs/BACKEND_SYNC.md,
/// so the future backend can also import a backup file directly.
class BackupService {
  BackupService([AppDatabase? db]) : _db = db ?? AppDatabase.instance;
  final AppDatabase _db;

  static const formatVersion = 1;

  Future<Map<String, Object?>> buildBackup() async {
    final tables = <String, Object?>{};
    for (final t in syncedTables) {
      tables[t] = await _db.db.query(t);
    }
    return {
      'format': 'pharmacy_pos_backup',
      'format_version': formatVersion,
      'schema_version': AppDatabase.schemaVersion,
      'device_id': await _db.meta('device_id'),
      'invoice_seq': await _db.meta('invoice_seq'),
      'exported_at': nowMs(),
      'shop': {for (final k in ShopSettingsRepo.shopKeys) k: await _db.meta(k)},
      'tables': tables,
    };
  }

  /// Writes the backup to a file and opens the share sheet so the owner can
  /// save it to Google Drive, send it on WhatsApp/email, etc.
  Future<File> exportAndShare() async {
    final data = await buildBackup();
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().substring(0, 16).replaceAll(':', '-');
    final file = File(p.join(dir.path, 'pharmacy_backup_$stamp.json'));
    await file.writeAsString(jsonEncode(data));
    await Share.shareXFiles([XFile(file.path, mimeType: 'application/json')],
        subject: 'Pharmacy POS backup $stamp');
    await _db.setMeta('last_backup_at', '${nowMs()}');
    return file;
  }

  /// Replaces ALL local data with the backup contents.
  Future<int> restoreFromFile(File file) async {
    final data = jsonDecode(await file.readAsString());
    if (data is! Map || data['format'] != 'pharmacy_pos_backup') {
      throw const FormatException('Not a Pharmacy POS backup file');
    }
    if ((data['schema_version'] as int? ?? 0) > AppDatabase.schemaVersion) {
      throw const FormatException('Backup is from a newer app version. Please update the app.');
    }
    final tables = (data['tables'] as Map).cast<String, Object?>();
    var count = 0;
    await _db.db.transaction((txn) async {
      await txn.execute('PRAGMA defer_foreign_keys = ON');
      for (final t in syncedTables.reversed) {
        await txn.delete(t);
      }
      for (final t in syncedTables) {
        final rows = (tables[t] as List? ?? const []).cast<Map>();
        for (final r in rows) {
          await txn.insert(t, r.cast<String, Object?>());
          count++;
        }
      }
      final seq = data['invoice_seq'];
      if (seq != null) await _db.setMeta('invoice_seq', '$seq', txn: txn);
      final shop = data['shop'];
      if (shop is Map) {
        for (final k in ShopSettingsRepo.shopKeys) {
          if (shop[k] != null) await _db.setMeta(k, '${shop[k]}', txn: txn);
        }
      }
    });
    return count;
  }

  Future<DateTime?> lastBackupAt() async {
    final v = await _db.meta('last_backup_at');
    return v == null ? null : DateTime.fromMillisecondsSinceEpoch(int.parse(v));
  }
}
