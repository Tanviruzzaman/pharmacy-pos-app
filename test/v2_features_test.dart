import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_pos/core/db.dart';
import 'package:pharmacy_pos/data/customer_repo.dart';
import 'package:pharmacy_pos/data/medicine_repo.dart';
import 'package:pharmacy_pos/data/pin_service.dart';
import 'package:pharmacy_pos/data/report_repo.dart';
import 'package:pharmacy_pos/data/sale_repo.dart';
import 'package:pharmacy_pos/models/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late AppDatabase db;

  setUp(() async {
    db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfiNoIsolate);
  });
  tearDown(() => db.db.close());

  final future = DateTime.now().add(const Duration(days: 300));

  test('sell by strip and box, stock counted in tablets', () async {
    final meds = MedicineRepo(db);
    final m = await meds.add(name: 'Seclo 20', unit: 'capsule', sellPrice: 600, stripSize: 10, boxSize: 100);
    await meds.addBatch(medicineId: m.id, expiry: future, qty: 150, buyPrice: 400, sellPrice: 600);
    final found = (await meds.search('seclo')).single;
    expect(found.packUnits.map((p) => p.factor), [1, 10, 100]);

    // 1 box at 550 + 2 strips at 58 + 3 capsules at 6
    final sale = await SaleRepo(db).saveSale(cart: [
      CartLine(medicine: found, qty: 1, unitPrice: 55000, available: 150, pack: const PackUnit('box', 100)),
      CartLine(medicine: found, qty: 2, unitPrice: 5800, available: 150, pack: const PackUnit('strip', 10)),
      CartLine(medicine: found, qty: 3, unitPrice: 600, available: 150),
    ], paid: 68400);
    expect(sale.total, 55000 + 11600 + 1800);
    expect(sale.profit, sale.total - 123 * 400);
    expect((await meds.byId(m.id))!.stockQty, 150 - 123);

    final lines = (await SaleRepo(db).receipt(sale.id))!.items;
    expect([for (final l in lines) '${l.qty} ${l.soldUnit ?? 'base'} ${l.lineTotal}'],
        ['3 base 1800', '2 strip 11600', '1 box 55000']);
  });

  test('line total split across batches adds up exactly', () async {
    final meds = MedicineRepo(db);
    final m = await meds.add(name: 'Napa', unit: 'tablet', stripSize: 3);
    await meds.addBatch(
        medicineId: m.id, expiry: DateTime.now().add(const Duration(days: 30)), qty: 2, buyPrice: 100, sellPrice: 150);
    await meds.addBatch(medicineId: m.id, expiry: future, qty: 10, buyPrice: 100, sellPrice: 150);
    final found = (await meds.search('napa')).single;
    // 1 strip of 3 at 1000 poisha: 2 tablets come from batch 1, 1 from batch 2.
    final sale = await SaleRepo(db).saveSale(
        cart: [CartLine(medicine: found, qty: 1, unitPrice: 1000, available: 12, pack: const PackUnit('strip', 3))],
        paid: 1000);
    final parts = await db.db.query('sale_items', where: 'sale_id = ?', whereArgs: [sale.id]);
    expect(parts.length, 2);
    expect(parts.fold<int>(0, (s, r) => s + (r['line_total'] as int)), 1000);
  });

  test('partial return refunds cash, puts stock back, adjusts report', () async {
    final meds = MedicineRepo(db);
    final m = await meds.add(name: 'Ace', unit: 'tablet');
    await meds.addBatch(medicineId: m.id, expiry: future, qty: 20, buyPrice: 100, sellPrice: 200);
    final found = (await meds.search('ace')).single;
    // 10 x 200 = 2000, discount 200 -> total 1800 (10% off)
    final sale = await SaleRepo(db).saveSale(
        cart: [CartLine(medicine: found, qty: 10, unitPrice: 200, available: 20)], discount: 200, paid: 1800);

    final line = (await SaleRepo(db).itemsOf(sale.id)).single;
    final ret = await SaleRepo(db).returnItems(saleId: sale.id, qtyByKey: {line.key: 4});
    expect(ret.amount, 720, reason: '4 x 200 = 800 less 10% discount');
    expect(ret.refund, 720);
    expect(ret.bakiReduced, 0);
    expect((await meds.byId(m.id))!.stockQty, 14);

    final r = await ReportRepo(db).daily(DateTime.now());
    expect(r.returns, 720);
    expect(r.netSales, 1080);
    expect(r.cashInHand, 1080);
    expect(r.profit, (1800 - 1000) - (720 - 400));

    final again = (await SaleRepo(db).receipt(sale.id))!;
    expect(again.sale.returned, 720);
    expect(again.items.single.returnableQty, 6);
    await expectLater(
        SaleRepo(db).returnItems(saleId: sale.id, qtyByKey: {line.key: 7}), throwsA(isA<SaleException>()));
  });

  test('cancelling a baki sale clears the baki instead of refunding cash', () async {
    final meds = MedicineRepo(db);
    final m = await meds.add(name: 'Fexo', unit: 'tablet');
    await meds.addBatch(medicineId: m.id, expiry: future, qty: 10, buyPrice: 500, sellPrice: 800);
    final found = (await meds.search('fexo')).single;
    final cust = await CustomerRepo(db).add(name: 'Karim');
    final sale = await SaleRepo(db).saveSale(
        cart: [CartLine(medicine: found, qty: 5, unitPrice: 800, available: 10)], paid: 1000, customerId: cust.id);
    expect((await CustomerRepo(db).byId(cust.id))!.balance, 3000);

    final ret = await SaleRepo(db).cancelSale(sale.id);
    expect(ret.amount, 4000);
    expect(ret.bakiReduced, 3000);
    expect(ret.refund, 1000);
    expect((await CustomerRepo(db).byId(cust.id))!.balance, 0);
    expect((await CustomerRepo(db).ledger(cust.id)).first.isReturn, isTrue);
    expect((await SaleRepo(db).receipt(sale.id))!.sale.fullyReturned, isTrue);
    expect((await meds.byId(m.id))!.stockQty, 10);
    final r = await ReportRepo(db).daily(DateTime.now());
    expect(r.duePaymentsReceived, 0, reason: 'a return is not cash collected');
    expect(r.cashInHand, 0);
  });

  test('low stock list', () async {
    final meds = MedicineRepo(db);
    final low = await meds.add(name: 'Low', reorderLevel: 20);
    await meds.addBatch(medicineId: low.id, expiry: future, qty: 15, buyPrice: 1, sellPrice: 2);
    final ok = await meds.add(name: 'Ok', reorderLevel: 5);
    await meds.addBatch(medicineId: ok.id, expiry: future, qty: 50, buyPrice: 1, sellPrice: 2);
    await meds.add(name: 'Empty', reorderLevel: 1);
    await meds.add(name: 'NoAlert');
    expect((await meds.lowStock()).map((m) => m.name), ['Empty', 'Low']);
    expect((await meds.search('low')).single.isLowStock, isTrue);
  });

  test('PIN is hashed and checked', () async {
    final pin = PinService(db);
    expect(await pin.isSet(), isFalse);
    expect(await pin.check('0000'), isTrue, reason: 'no PIN = unlocked');
    await pin.set('1234');
    expect(await pin.isSet(), isTrue);
    expect(await pin.check('1234'), isTrue);
    expect(await pin.check('4321'), isFalse);
    expect(await db.meta('pin_hash'), isNot(contains('1234')));
    await pin.clear();
    expect(await pin.isSet(), isFalse);
  });

  test('v1 database upgrades to v2 and keeps its data', () async {
    final path = '${Directory.systemTemp.path}/pos_v1_upgrade_test.db';
    if (File(path).existsSync()) File(path).deleteSync();
    const sync = 'created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, deleted INTEGER NOT NULL DEFAULT 0, synced INTEGER NOT NULL DEFAULT 0';
    final v1 = await databaseFactoryFfiNoIsolate.openDatabase(path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (d, _) async {
            await d.execute('CREATE TABLE app_meta (key TEXT PRIMARY KEY, value TEXT)');
            await d.execute('CREATE TABLE customers (id TEXT PRIMARY KEY, name TEXT NOT NULL, $sync)');
            await d.execute('CREATE TABLE sales (id TEXT PRIMARY KEY, $sync)');
            await d.insert('customers', {'id': 'x', 'name': 'Old customer', 'created_at': 1, 'updated_at': 1});
            await d.execute(
                "CREATE TABLE medicines (id TEXT PRIMARY KEY, name TEXT NOT NULL, generic_name TEXT, company TEXT, unit TEXT NOT NULL DEFAULT 'pcs', sell_price INTEGER NOT NULL DEFAULT 0, barcode TEXT, $sync)");
            await d.execute(
                'CREATE TABLE sale_items (id TEXT PRIMARY KEY, sale_id TEXT NOT NULL, medicine_id TEXT NOT NULL, batch_id TEXT NOT NULL, medicine_name TEXT NOT NULL, qty INTEGER NOT NULL, unit_price INTEGER NOT NULL, buy_price INTEGER NOT NULL, line_total INTEGER NOT NULL, $sync)');
            await d.execute(
                "CREATE TABLE credit_entries (id TEXT PRIMARY KEY, customer_id TEXT NOT NULL, type TEXT NOT NULL CHECK (type IN ('due','payment')), amount INTEGER NOT NULL, sale_id TEXT, note TEXT, entry_at INTEGER NOT NULL, entry_date TEXT NOT NULL, $sync)");
            await d.insert('medicines', {'id': 'm1', 'name': 'Old med', 'created_at': 1, 'updated_at': 1});
            await d.insert('credit_entries', {
              'id': 'c1', 'customer_id': 'x', 'type': 'due', 'amount': 500, 'entry_at': 1, 'entry_date': '2026-01-01',
              'created_at': 1, 'updated_at': 1,
            });
          },
        ));
    await v1.close();

    final up = await AppDatabase.open(path: path, factory: databaseFactoryFfiNoIsolate);
    expect(await up.db.getVersion(), AppDatabase.schemaVersion);
    final med = (await up.db.query('medicines')).single;
    expect([med['name'], med['reorder_level'], med['strip_size']], ['Old med', 0, 0]);
    expect((await up.db.query('credit_entries')).single['amount'], 500);
    await up.db.insert('credit_entries', {
      'id': 'c2', 'customer_id': 'x', 'type': 'return', 'amount': 1, 'entry_at': 1, 'entry_date': '2026-01-01',
      'created_at': 1, 'updated_at': 1,
    });
    expect(await up.db.query('sale_returns'), isEmpty);
    await up.db.close();
    File(path).deleteSync();
  });
}
