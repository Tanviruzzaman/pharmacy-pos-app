import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_pos/core/db.dart';
import 'package:pharmacy_pos/core/money.dart';
import 'package:pharmacy_pos/data/backup_service.dart';
import 'package:pharmacy_pos/data/customer_repo.dart';
import 'package:pharmacy_pos/data/medicine_repo.dart';
import 'package:pharmacy_pos/data/report_repo.dart';
import 'package:pharmacy_pos/data/sale_repo.dart';
import 'package:pharmacy_pos/data/sync_outbox.dart';
import 'package:pharmacy_pos/models/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late AppDatabase db;

  setUp(() async {
    db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfiNoIsolate);
  });
  tearDown(() => db.db.close());

  test('Money parse/format', () {
    expect(Money.parse('12.5'), 1250);
    expect(Money.parse('1,200'), 120000);
    expect(Money.toInput(1250), '12.50');
    expect(Money.format(120000), '৳1,200.00');
  });

  test('FEFO sale, profit, baki and daily report', () async {
    final meds = MedicineRepo(db);
    final napa = await meds.add(name: 'Napa 500', genericName: 'Paracetamol', unit: 'tablet', sellPrice: 120);
    final now = DateTime.now();
    // Later expiry, higher cost
    await meds.addBatch(
        medicineId: napa.id, batchNo: 'B2', expiry: now.add(const Duration(days: 400)), qty: 100, buyPrice: 100, sellPrice: 120);
    // Earlier expiry, lower cost -> must be sold first
    await meds.addBatch(
        medicineId: napa.id, batchNo: 'B1', expiry: now.add(const Duration(days: 30)), qty: 5, buyPrice: 80, sellPrice: 120);
    // Expired batch -> never sold
    await meds.addBatch(
        medicineId: napa.id, batchNo: 'B0', expiry: now.subtract(const Duration(days: 3)), qty: 50, buyPrice: 50, sellPrice: 120);

    final found = (await meds.search('napa')).single;
    expect(found.stockQty, 105);
    expect(await meds.expiringCount(withinDays: 90), 2); // B1 + expired B0

    final cust = await CustomerRepo(db).add(name: 'Rahim', phone: '01700000000');

    await expectLater(
      SaleRepo(db).saveSale(
          cart: [CartLine(medicine: found, qty: 10, unitPrice: 120, available: found.stockQty)], paid: 0),
      throwsA(isA<SaleException>()),
      reason: 'due without customer must fail',
    );

    final sale = await SaleRepo(db).saveSale(
      cart: [CartLine(medicine: found, qty: 10, unitPrice: 120, available: found.stockQty)],
      discount: 100,
      paid: 500,
      customerId: cust.id,
    );
    // 10 x 120 = 1200 - 100 discount = 1100. Cost = 5x80 + 5x100 = 900. Profit = 200.
    expect(sale.total, 1100);
    expect(sale.due, 600);
    expect(sale.profit, 200);

    final batches = await meds.batchesFor(napa.id);
    expect({for (final b in batches) b.batchNo: b.qty}, {'B0': 50, 'B1': 0, 'B2': 95});

    final customers = CustomerRepo(db);
    expect((await customers.byId(cust.id))!.balance, 600);
    await customers.addEntry(customerId: cust.id, type: 'payment', amount: 250);
    expect((await customers.byId(cust.id))!.balance, 350);

    final r = await ReportRepo(db).daily(DateTime.now());
    expect(r.saleCount, 1);
    expect(r.totalSales, 1100);
    expect(r.profit, 200);
    expect(r.cashFromSales, 500);
    expect(r.duePaymentsReceived, 250);
    expect(r.cashInHand, 750);
  });

  test('cannot oversell', () async {
    final meds = MedicineRepo(db);
    final m = await meds.add(name: 'Seclo 20', sellPrice: 700);
    await meds.addBatch(
        medicineId: m.id, expiry: DateTime.now().add(const Duration(days: 200)), qty: 3, buyPrice: 500, sellPrice: 700);
    final found = (await meds.search('seclo')).single;
    await expectLater(
      SaleRepo(db).saveSale(cart: [CartLine(medicine: found, qty: 4, unitPrice: 700, available: 3)], paid: 2800),
      throwsA(isA<SaleException>()),
    );
    expect((await meds.batchesFor(m.id)).single.qty, 3, reason: 'transaction rolled back');
  });

  test('backup round trip and sync outbox', () async {
    final meds = MedicineRepo(db);
    final m = await meds.add(name: 'Ace', sellPrice: 100);
    await meds.addBatch(
        medicineId: m.id, expiry: DateTime.now().add(const Duration(days: 200)), qty: 10, buyPrice: 80, sellPrice: 100);

    final outbox = SyncOutbox(db);
    final payload = await outbox.buildPushPayload();
    expect((payload['changes'] as Map).keys, containsAll(['medicines', 'stock_batches']));
    await outbox.markSynced(payload);
    expect(await outbox.pendingCount(), 0);

    final backup = await BackupService(db).buildBackup();
    expect(((backup['tables'] as Map)['medicines'] as List).length, 1);
  });
}
