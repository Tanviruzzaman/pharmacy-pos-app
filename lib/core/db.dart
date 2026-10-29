import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'ids.dart';

/// Tables that are synced to the backend (in dependency order).
const syncedTables = [
  'medicines',
  'stock_batches',
  'customers',
  'sales',
  'sale_items',
  'sale_returns',
  'credit_entries',
];

/// Every synced table has these columns:
///   id TEXT PRIMARY KEY  (UUID v4, generated on device)
///   created_at INTEGER   (ms since epoch, UTC)
///   updated_at INTEGER   (ms since epoch, UTC) - bumped on every change
///   deleted INTEGER      (0/1 soft delete - never hard delete synced rows)
///   synced INTEGER       (0 = changed locally, needs push; 1 = pushed)
const _syncCols = '''
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted INTEGER NOT NULL DEFAULT 0,
  synced INTEGER NOT NULL DEFAULT 0
''';

class AppDatabase {
  AppDatabase._(this.db);

  final Database db;
  static AppDatabase? _instance;

  static AppDatabase get instance {
    final i = _instance;
    if (i == null) throw StateError('AppDatabase.open() not called');
    return i;
  }

  /// v2: pack units + low-stock level on medicines, sold unit + returns on sale items,
  /// sale_returns table, and 'return' credit entries.
  static const schemaVersion = 2;

  /// [path] / [factory] can be overridden in tests (e.g. in-memory ffi db).
  static Future<AppDatabase> open({String? path, DatabaseFactory? factory}) async {
    final f = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await f.getDatabasesPath(), 'pharmacy_pos.db');
    final db = await f.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
    _instance = AppDatabase._(db);
    return _instance!;
  }

  static Future<void> _onCreate(Database db, int version) async {
    final b = db.batch();
    b.execute('''
      CREATE TABLE app_meta (
        key TEXT PRIMARY KEY,
        value TEXT
      )''');
    b.execute('''
      CREATE TABLE medicines (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        generic_name TEXT,
        company TEXT,
        unit TEXT NOT NULL DEFAULT 'pcs',
        sell_price INTEGER NOT NULL DEFAULT 0,
        barcode TEXT,
        $_medicineV2Cols,
        $_syncCols
      )''');
    b.execute('CREATE INDEX idx_medicines_name ON medicines(name)');
    b.execute('''
      CREATE TABLE stock_batches (
        id TEXT PRIMARY KEY,
        medicine_id TEXT NOT NULL REFERENCES medicines(id),
        batch_no TEXT,
        expiry_date TEXT NOT NULL,
        qty INTEGER NOT NULL,
        buy_price INTEGER NOT NULL,
        sell_price INTEGER NOT NULL,
        $_syncCols
      )''');
    b.execute('CREATE INDEX idx_batches_med ON stock_batches(medicine_id, expiry_date)');
    b.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        $_syncCols
      )''');
    b.execute('''
      CREATE TABLE sales (
        id TEXT PRIMARY KEY,
        invoice_no TEXT NOT NULL,
        customer_id TEXT REFERENCES customers(id),
        sold_at INTEGER NOT NULL,
        sale_date TEXT NOT NULL,
        subtotal INTEGER NOT NULL,
        discount INTEGER NOT NULL DEFAULT 0,
        total INTEGER NOT NULL,
        paid INTEGER NOT NULL,
        due INTEGER NOT NULL DEFAULT 0,
        cost INTEGER NOT NULL,
        profit INTEGER NOT NULL,
        $_syncCols
      )''');
    b.execute('CREATE INDEX idx_sales_date ON sales(sale_date)');
    b.execute('''
      CREATE TABLE sale_items (
        id TEXT PRIMARY KEY,
        sale_id TEXT NOT NULL REFERENCES sales(id),
        medicine_id TEXT NOT NULL REFERENCES medicines(id),
        batch_id TEXT NOT NULL REFERENCES stock_batches(id),
        medicine_name TEXT NOT NULL,
        qty INTEGER NOT NULL,
        unit_price INTEGER NOT NULL,
        buy_price INTEGER NOT NULL,
        line_total INTEGER NOT NULL,
        $_saleItemV2Cols,
        $_syncCols
      )''');
    b.execute('CREATE INDEX idx_items_sale ON sale_items(sale_id)');
    _createSaleReturns(b);
    _createCreditEntries(b, 'credit_entries');
    b.execute('CREATE INDEX idx_credit_customer ON credit_entries(customer_id)');
    b.insert('app_meta', {'key': 'device_id', 'value': newId()});
    b.insert('app_meta', {'key': 'invoice_seq', 'value': '0'});
    await b.commit(noResult: true);
  }

  /// Quantities are always stored in the medicine's base unit (e.g. tablet).
  /// strip_size / box_size = base units per strip / box (0 = not sold that way).
  static const _medicineV2Cols = '''
    reorder_level INTEGER NOT NULL DEFAULT 0,
    strip_size INTEGER NOT NULL DEFAULT 0,
    box_size INTEGER NOT NULL DEFAULT 0
  ''';

  /// qty and returned_qty are base units; unit_price is per sold unit (unit_factor base units).
  /// sold_unit NULL means the medicine's base unit.
  static const _saleItemV2Cols = '''
    sold_unit TEXT,
    unit_factor INTEGER NOT NULL DEFAULT 1,
    returned_qty INTEGER NOT NULL DEFAULT 0
  ''';

  static void _createSaleReturns(Batch b) {
    b.execute('''
      CREATE TABLE sale_returns (
        id TEXT PRIMARY KEY,
        sale_id TEXT NOT NULL REFERENCES sales(id),
        returned_at INTEGER NOT NULL,
        return_date TEXT NOT NULL,
        amount INTEGER NOT NULL,
        cost INTEGER NOT NULL,
        refund INTEGER NOT NULL,
        baki_reduced INTEGER NOT NULL,
        $_syncCols
      )''');
    b.execute('CREATE INDEX idx_returns_date ON sale_returns(return_date)');
    b.execute('CREATE INDEX idx_returns_sale ON sale_returns(sale_id)');
  }

  /// type: 'due' adds to baki; 'payment' (cash received) and 'return' (goods returned) reduce it.
  static void _createCreditEntries(Batch b, String table) {
    b.execute('''
      CREATE TABLE $table (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL REFERENCES customers(id),
        type TEXT NOT NULL CHECK (type IN ('due','payment','return')),
        amount INTEGER NOT NULL,
        sale_id TEXT REFERENCES sales(id),
        note TEXT,
        entry_at INTEGER NOT NULL,
        entry_date TEXT NOT NULL,
        $_syncCols
      )''');
  }

  static Future<void> _onUpgrade(Database db, int from, int to) async {
    if (from < 2) {
      final b = db.batch();
      for (final col in _medicineV2Cols.split(',')) {
        b.execute('ALTER TABLE medicines ADD COLUMN ${col.trim()}');
      }
      for (final col in _saleItemV2Cols.split(',')) {
        b.execute('ALTER TABLE sale_items ADD COLUMN ${col.trim()}');
      }
      _createSaleReturns(b);
      // SQLite cannot change a CHECK constraint in place, so rebuild credit_entries.
      _createCreditEntries(b, 'credit_entries_v2');
      b.execute('INSERT INTO credit_entries_v2 SELECT * FROM credit_entries');
      b.execute('DROP TABLE credit_entries');
      b.execute('ALTER TABLE credit_entries_v2 RENAME TO credit_entries');
      b.execute('CREATE INDEX idx_credit_customer ON credit_entries(customer_id)');
      await b.commit(noResult: true);
    }
  }

  Future<String?> meta(String key, {DatabaseExecutor? txn}) async {
    final rows = await (txn ?? db).query('app_meta', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> setMeta(String key, String value, {DatabaseExecutor? txn}) =>
      (txn ?? db).insert('app_meta', {'key': key, 'value': value},
          conflictAlgorithm: ConflictAlgorithm.replace);
}
