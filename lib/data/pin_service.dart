import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../core/db.dart';
import '../core/ids.dart';

/// App lock PIN. Only a salted SHA-256 hash is stored, in app_meta (device-local, not backed up).
class PinService {
  PinService([AppDatabase? db]) : _db = db ?? AppDatabase.instance;
  final AppDatabase _db;

  static const length = 4;

  Future<bool> isSet() async => ((await _db.meta('pin_hash')) ?? '').isNotEmpty;

  Future<void> set(String pin) async {
    if (pin.length != length || int.tryParse(pin) == null) throw ArgumentError('PIN must be $length digits');
    final salt = newId();
    await _db.setMeta('pin_salt', salt);
    await _db.setMeta('pin_hash', _hash(salt, pin));
  }

  Future<bool> check(String pin) async {
    final hash = await _db.meta('pin_hash');
    if (hash == null || hash.isEmpty) return true;
    return _hash(await _db.meta('pin_salt') ?? '', pin) == hash;
  }

  Future<void> clear() => _db.setMeta('pin_hash', '');

  static String _hash(String salt, String pin) => sha256.convert(utf8.encode('$salt:$pin')).toString();
}
