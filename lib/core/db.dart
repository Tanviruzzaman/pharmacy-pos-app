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

  static const schemaVersion = 1;

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
        $_syncCols
      )''');
    b.execute('CREATE INDEX idx_items_sale ON sale_items(sale_id)');
    b.execute('''
      CREATE TABLE credit_entries (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL REFERENCES customers(id),
        type TEXT NOT NULL CHECK (type IN ('due','payment')),
        amount INTEGER NOT NULL,
        sale_id TEXT REFERENCES sales(id),
        note TEXT,
        entry_at INTEGER NOT NULL,
        entry_date TEXT NOT NULL,
        $_syncCols
      )''');
    b.execute('CREATE INDEX idx_credit_customer ON credit_entries(customer_id)');
    b.insert('app_meta', {'key': 'device_id', 'value': newId()});
    b.insert('app_meta', {'key': 'invoice_seq', 'value': '0'});
    await b.commit(noResult: true);
  }

  Future<String?> meta(String key, {DatabaseExecutor? txn}) async {
    final rows = await (txn ?? db).query('app_meta', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> setMeta(String key, String value, {DatabaseExecutor? txn}) =>
      (txn ?? db).insert('app_meta', {'key': key, 'value': value},
          conflictAlgorithm: ConflictAlgorithm.replace);
}
