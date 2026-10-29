import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Globally unique ids so rows created offline on any device never collide
/// when they are later pushed to the backend.
String newId() => _uuid.v4();

/// Milliseconds since epoch (UTC). Used for created_at / updated_at.
int nowMs() => DateTime.now().toUtc().millisecondsSinceEpoch;

/// Standard sync columns every table carries. See docs/BACKEND_SYNC.md.
Map<String, Object?> newSyncCols() {
  final now = nowMs();
  return {'created_at': now, 'updated_at': now, 'deleted': 0, 'synced': 0};
}

/// Columns to set on every update so the row is picked up by the next sync.
Map<String, Object?> touchSyncCols() => {'updated_at': nowMs(), 'synced': 0};

final dateKeyFmt = DateFormat('yyyy-MM-dd');
final displayDateFmt = DateFormat('dd MMM yyyy');
final displayDateTimeFmt = DateFormat('dd MMM yyyy, h:mm a');

String dateKey(DateTime d) => dateKeyFmt.format(d);
