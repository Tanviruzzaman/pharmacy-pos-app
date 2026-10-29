import '../core/db.dart';
import '../core/ids.dart';
import '../models/models.dart';

class MedicineRepo {
  MedicineRepo([AppDatabase? db]) : _db = db ?? AppDatabase.instance;
  final AppDatabase _db;

  /// Sellable stock = non-deleted batches that are not yet expired.
  static const _stockJoin = '''
    LEFT JOIN (
      SELECT medicine_id,
             SUM(qty) AS stock_qty,
             MIN(expiry_date) AS nearest_expiry
      FROM stock_batches
      WHERE deleted = 0 AND qty > 0 AND expiry_date >= ?
      GROUP BY medicine_id
    ) s ON s.medicine_id = m.id
  ''';

  Future<List<Medicine>> search(String query, {bool inStockOnly = false, int limit = 50}) async {
    final today = dateKey(DateTime.now());
    final q = '%${query.trim()}%';
    final rows = await _db.db.rawQuery('''
      SELECT m.*, COALESCE(s.stock_qty, 0) AS stock_qty, s.nearest_expiry
      FROM medicines m
      $_stockJoin
      WHERE m.deleted = 0
        AND (m.name LIKE ? OR m.generic_name LIKE ? OR m.barcode = ?)
        ${inStockOnly ? 'AND COALESCE(s.stock_qty, 0) > 0' : ''}
      ORDER BY m.name COLLATE NOCASE
      LIMIT ?
    ''', [today, q, q, query.trim(), limit]);
    return rows.map(Medicine.fromMap).toList();
  }

  Future<Medicine?> byId(String id) async {
    final today = dateKey(DateTime.now());
    final rows = await _db.db.rawQuery('''
      SELECT m.*, COALESCE(s.stock_qty, 0) AS stock_qty, s.nearest_expiry
      FROM medicines m
      $_stockJoin
      WHERE m.id = ?
    ''', [today, id]);
    return rows.isEmpty ? null : Medicine.fromMap(rows.first);
  }

  Future<Medicine> add({
    required String name,
    String? genericName,
    String? company,
    String unit = 'pcs',
    int sellPrice = 0,
    String? barcode,
  }) async {
    final id = newId();
    await _db.db.insert('medicines', {
      'id': id,
      'name': name.trim(),
      'generic_name': _blankToNull(genericName),
      'company': _blankToNull(company),
      'unit': unit,
      'sell_price': sellPrice,
      'barcode': _blankToNull(barcode),
      ...newSyncCols(),
    });
    return Medicine(
        id: id, name: name.trim(), genericName: genericName, company: company, unit: unit, sellPrice: sellPrice);
  }

  Future<void> update(Medicine m) => _db.db.update(
        'medicines',
        {
          'name': m.name.trim(),
          'generic_name': _blankToNull(m.genericName),
          'company': _blankToNull(m.company),
          'unit': m.unit,
          'sell_price': m.sellPrice,
          'barcode': _blankToNull(m.barcode),
          ...touchSyncCols(),
        },
        where: 'id = ?',
        whereArgs: [m.id],
      );

  Future<void> softDelete(String id) =>
      _db.db.update('medicines', {'deleted': 1, ...touchSyncCols()}, where: 'id = ?', whereArgs: [id]);

  Future<List<StockBatch>> batchesFor(String medicineId) async {
    final rows = await _db.db.query('stock_batches',
        where: 'medicine_id = ? AND deleted = 0', whereArgs: [medicineId], orderBy: 'expiry_date');
    return rows.map(StockBatch.fromMap).toList();
  }

  Future<void> addBatch({
    required String medicineId,
    String? batchNo,
    required DateTime expiry,
    required int qty,
    required int buyPrice,
    required int sellPrice,
  }) async {
    await _db.db.transaction((txn) async {
      await txn.insert('stock_batches', {
        'id': newId(),
        'medicine_id': medicineId,
        'batch_no': _blankToNull(batchNo),
        'expiry_date': dateKey(expiry),
        'qty': qty,
        'buy_price': buyPrice,
        'sell_price': sellPrice,
        ...newSyncCols(),
      });
      // Remember latest selling price as the medicine default.
      await txn.update('medicines', {'sell_price': sellPrice, ...touchSyncCols()},
          where: 'id = ?', whereArgs: [medicineId]);
    });
  }

  Future<void> adjustBatchQty(String batchId, int newQty) => _db.db.update(
      'stock_batches', {'qty': newQty, ...touchSyncCols()},
      where: 'id = ?', whereArgs: [batchId]);

  Future<void> deleteBatch(String batchId) => _db.db.update(
      'stock_batches', {'deleted': 1, ...touchSyncCols()},
      where: 'id = ?', whereArgs: [batchId]);

  /// Batches with stock that are expired or expire within [withinDays].
  Future<List<StockBatch>> expiring({int withinDays = 90}) async {
    final limit = dateKey(DateTime.now().add(Duration(days: withinDays)));
    final rows = await _db.db.rawQuery('''
      SELECT b.*, m.name AS medicine_name
      FROM stock_batches b
      JOIN medicines m ON m.id = b.medicine_id
      WHERE b.deleted = 0 AND m.deleted = 0 AND b.qty > 0 AND b.expiry_date <= ?
      ORDER BY b.expiry_date
    ''', [limit]);
    return rows.map(StockBatch.fromMap).toList();
  }

  Future<int> expiringCount({int withinDays = 90}) async => (await expiring(withinDays: withinDays)).length;

  static String? _blankToNull(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
}
