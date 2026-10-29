import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_pos/core/db.dart';
import 'package:pharmacy_pos/data/backup_service.dart';
import 'package:pharmacy_pos/data/customer_repo.dart';
import 'package:pharmacy_pos/data/medicine_repo.dart';
import 'package:pharmacy_pos/data/sale_repo.dart';
import 'package:pharmacy_pos/data/shop_settings.dart';
import 'package:pharmacy_pos/models/models.dart';
import 'package:pharmacy_pos/receipt/receipt_pdf.dart';
import 'package:pharmacy_pos/receipt/receipt_thermal.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Printable text of an ESC/POS byte stream (commands removed).
List<String> printedLines(List<int> bytes) {
  final out = StringBuffer();
  for (var i = 0; i < bytes.length; i++) {
    final b = bytes[i];
    if (b == 0x1B || b == 0x1D) {
      // ESC @ has no argument; ESC a/E/d and GS ! take one; GS V B n takes two.
      final cmd = bytes[i + 1];
      i += (b == 0x1B && cmd == 0x40) ? 1 : (b == 0x1D && cmd == 0x56) ? 3 : 2;
    } else {
      out.writeCharCode(b);
    }
  }
  return const LineSplitter().convert(out.toString());
}

void main() {
  sqfliteFfiInit();
  late AppDatabase db;

  setUp(() async {
    db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfiNoIsolate);
  });
  tearDown(() => db.db.close());

  Future<Receipt> makeSale() async {
    final meds = MedicineRepo(db);
    final m = await meds.add(name: 'Napa Extra 500mg Tablet', unit: 'tablet', sellPrice: 250);
    await meds.addBatch(
        medicineId: m.id, expiry: DateTime.now().add(const Duration(days: 300)), qty: 50, buyPrice: 200, sellPrice: 250);
    final found = (await meds.search('napa')).single;
    final cust = await CustomerRepo(db).add(name: 'Rahim', phone: '01700000000');
    final sale = await SaleRepo(db).saveSale(
      cart: [CartLine(medicine: found, qty: 4, unitPrice: 250, available: found.stockQty)],
      discount: 100,
      paid: 500,
      customerId: cust.id,
    );
    return (await SaleRepo(db).receipt(sale.id))!;
  }

  test('receipt loads sale, customer and items', () async {
    final r = await makeSale();
    expect(r.sale.customerName, 'Rahim');
    expect(r.customerPhone, '01700000000');
    expect(r.items.single.qty, 4);
    expect(r.subtotal, 1000);
    expect(r.sale.total, 900);
    expect(r.sale.due, 400);
  });

  test('thermal receipt fits the paper and shows totals', () async {
    final r = await makeSale();
    for (final width in [58, 80]) {
      final shop = ShopSettings(name: 'Shifa Pharmacy', address: 'Mirpur 10, Dhaka', phone: '01800000000', paperWidth: width);
      final lines = printedLines(buildThermalReceipt(r, shop));
      expect(lines.every((l) => l.length <= shop.lineChars), isTrue, reason: '${width}mm overflow: $lines');
      expect(lines.first, 'Shifa Pharmacy');
      expect(lines, contains('Invoice: ${r.sale.invoiceNo}'));
      expect(lines, contains(leftRight('  4 x 2.50', '10.00', shop.lineChars)));
      expect(lines, contains(leftRight('Discount', '-1.00', shop.lineChars)));
      expect(lines, contains(leftRight('TOTAL (Tk)', '9.00', shop.lineChars)));
      expect(lines, contains(leftRight('Due (baki)', '4.00', shop.lineChars)));
    }
  });

  test('non-ASCII text is replaced for the printer', () {
    expect(receiptSafe('শিফা Pharmacy ৳'), '???? Pharmacy ?');
    expect(wrap('Napa Extra 500mg Tablet', 10), ['Napa Extra', '500mg', 'Tablet']);
  });

  test('receipt PDF builds', () async {
    final r = await makeSale();
    final bytes = await buildReceiptPdf(r, ShopSettings(name: 'Shifa Pharmacy', paperWidth: 80));
    expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
  });

  test('shop settings save, load and survive backup restore', () async {
    final repo = ShopSettingsRepo(db);
    expect((await repo.load()).displayName, 'Pharmacy');
    await repo.save(ShopSettings(name: 'Shifa', phone: '018', paperWidth: 80, printerAddress: 'AA:BB', printerName: 'P58'));
    final s = await repo.load();
    expect([s.name, s.phone, s.paperWidth, s.printerAddress, s.lineChars], ['Shifa', '018', 80, 'AA:BB', 48]);

    final backup = await BackupService(db).buildBackup();
    await repo.save(ShopSettings());
    final file = await File('${Directory.systemTemp.path}/pos_backup_test.json').writeAsString(jsonEncode(backup));
    await BackupService(db).restoreFromFile(file);
    final restored = await repo.load();
    expect([restored.name, restored.paperWidth, restored.printerAddress], ['Shifa', 80, null],
        reason: 'shop details restored, printer is per-device');
  });
}
