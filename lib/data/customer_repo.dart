import '../core/db.dart';
import '../core/ids.dart';
import '../models/models.dart';

class CustomerRepo {
  CustomerRepo([AppDatabase? db]) : _db = db ?? AppDatabase.instance;
  final AppDatabase _db;

  static const _balanceSql = '''
    COALESCE((SELECT SUM(CASE WHEN e.type = 'due' THEN e.amount ELSE -e.amount END)
              FROM credit_entries e
              WHERE e.customer_id = c.id AND e.deleted = 0), 0) AS balance
  ''';

  Future<List<Customer>> list({String query = '', bool onlyWithDue = false}) async {
    final q = '%${query.trim()}%';
    final rows = await _db.db.rawQuery('''
      SELECT * FROM (
        SELECT c.*, $_balanceSql FROM customers c
        WHERE c.deleted = 0 AND (c.name LIKE ? OR c.phone LIKE ?)
      )
      ${onlyWithDue ? 'WHERE balance > 0' : ''}
      ORDER BY balance DESC, name COLLATE NOCASE
    ''', [q, q]);
    return rows.map(Customer.fromMap).toList();
  }

  Future<Customer?> byId(String id) async {
    final rows = await _db.db.rawQuery('SELECT c.*, $_balanceSql FROM customers c WHERE c.id = ?', [id]);
    return rows.isEmpty ? null : Customer.fromMap(rows.first);
  }

  Future<int> totalOutstanding() async {
    final r = await _db.db.rawQuery('''
      SELECT COALESCE(SUM(CASE WHEN type = 'due' THEN amount ELSE -amount END), 0) AS t
      FROM credit_entries WHERE deleted = 0
    ''');
    return (r.first['t'] as int?) ?? 0;
  }

  Future<Customer> add({required String name, String? phone, String? address}) async {
    final id = newId();
    await _db.db.insert('customers', {
      'id': id,
      'name': name.trim(),
      'phone': phone?.trim(),
      'address': address?.trim(),
      ...newSyncCols(),
    });
    return Customer(id: id, name: name.trim(), phone: phone, address: address);
  }

  Future<void> update(Customer c) => _db.db.update(
      'customers', {'name': c.name.trim(), 'phone': c.phone, 'address': c.address, ...touchSyncCols()},
      where: 'id = ?', whereArgs: [c.id]);

  Future<List<CreditEntry>> ledger(String customerId) async {
    final rows = await _db.db.query('credit_entries',
        where: 'customer_id = ? AND deleted = 0', whereArgs: [customerId], orderBy: 'entry_at DESC');
    return rows.map(CreditEntry.fromMap).toList();
  }

  /// [type] is 'payment' (customer paid us) or 'due' (manual baki, e.g. old balance).
  Future<void> addEntry({
    required String customerId,
    required String type,
    required int amount,
    String? note,
    DateTime? at,
  }) async {
    assert(type == 'due' || type == 'payment');
    if (amount <= 0) throw ArgumentError('Amount must be positive');
    final when = at ?? DateTime.now();
    await _db.db.insert('credit_entries', {
      'id': newId(),
      'customer_id': customerId,
      'type': type,
      'amount': amount,
      'note': note?.trim().isEmpty ?? true ? null : note!.trim(),
      'entry_at': when.toUtc().millisecondsSinceEpoch,
      'entry_date': dateKey(when),
      ...newSyncCols(),
    });
  }

  Future<void> deleteEntry(String entryId) => _db.db.update(
      'credit_entries', {'deleted': 1, ...touchSyncCols()},
      where: 'id = ? AND sale_id IS NULL', whereArgs: [entryId]);
}
