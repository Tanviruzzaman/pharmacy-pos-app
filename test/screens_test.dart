import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_pos/core/app_locale.dart';
import 'package:pharmacy_pos/core/db.dart';
import 'package:pharmacy_pos/data/customer_repo.dart';
import 'package:pharmacy_pos/data/medicine_repo.dart';
import 'package:pharmacy_pos/data/sale_repo.dart';
import 'package:pharmacy_pos/main.dart';
import 'package:pharmacy_pos/models/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Opens every screen from the home tiles in both languages: catches layout
/// overflows, missing translations and crashes that unit tests don't see.
void main() {
  sqfliteFfiInit();

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  // tester.pageBack() looks for the English "Back" tooltip, which is translated in Bangla.
  Future<void> back(WidgetTester tester) async {
    await tester.tap(find.byType(BackButton));
    await settle(tester);
  }

  Future<void> seed() async {
    final db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfiNoIsolate);
    final meds = MedicineRepo(db);
    final m = await meds.add(name: 'Napa', unit: 'tablet', sellPrice: 120, stripSize: 10, boxSize: 100, reorderLevel: 500);
    await meds.addBatch(medicineId: m.id, expiry: DateTime.now().add(const Duration(days: 40)), qty: 250, buyPrice: 80, sellPrice: 120);
    final found = (await meds.search('napa')).single;
    final c = await CustomerRepo(db).add(name: 'Rahim', phone: '01700000000');
    await SaleRepo(db).saveSale(
        cart: [CartLine(medicine: found, qty: 2, unitPrice: 1100, available: 250, pack: const PackUnit('strip', 10))],
        paid: 1000,
        customerId: c.id);
  }

  for (final (code, newSale, stock, report) in [
    ('bn', 'নতুন বিক্রি', 'স্টক', 'দৈনিক হিসাব'),
    ('en', 'New Sale', 'Stock', 'Daily report'),
  ]) {
    testWidgets('every screen opens in $code', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.runAsync(() async {
        await seed();
        await setLocale(code);
      });
      await tester.pumpWidget(const PharmacyApp(firstRun: false, startLocked: false));
      await settle(tester);
      expect(find.text(newSale), findsOneWidget);

      // Each home tile: open, check it built, go back.
      for (final icon in [
        Icons.inventory_2_outlined,
        Icons.warning_amber_rounded,
        Icons.trending_down,
        Icons.menu_book_outlined,
        Icons.bar_chart,
        Icons.cloud_upload_outlined,
        Icons.settings_outlined,
      ]) {
        await tester.ensureVisible(find.byIcon(icon).first);
        await tester.pump();
        await tester.tap(find.byIcon(icon).first);
        await settle(tester);
        expect(tester.takeException(), isNull, reason: 'screen behind $icon');
        await back(tester);
        await settle(tester);
      }

      await tester.tap(find.text(stock));
      await settle(tester);
      await tester.tap(find.text('Napa'));
      await settle(tester);
      expect(find.textContaining('230'), findsWidgets, reason: '250 bought - 2 strips of 10 sold');
      await back(tester);
      await back(tester);

      await tester.ensureVisible(find.text(report));
      await tester.pump();
      await tester.tap(find.text(report));
      await settle(tester);
      await tester.tap(find.byType(ListTile).last);
      await settle(tester);
      expect(tester.takeException(), isNull);

      await tester.runAsync(() => AppDatabase.instance.db.close());
    });
  }

  testWidgets('starts on the PIN pad when locked', (tester) async {
    await tester.runAsync(() async {
      await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfiNoIsolate);
      await setLocale('bn');
    });
    await tester.pumpWidget(const PharmacyApp(firstRun: false, startLocked: true));
    await settle(tester);
    expect(find.text('PIN দিন'), findsOneWidget);
    await tester.runAsync(() => AppDatabase.instance.db.close());
  });
}
