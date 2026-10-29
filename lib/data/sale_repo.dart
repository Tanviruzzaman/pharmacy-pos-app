import 'package:sqflite/sqflite.dart';

import '../core/db.dart';
import '../core/ids.dart';
import '../models/models.dart';

class SaleException implements Exception {
  SaleException(this.message);
  final String message;
  @override
  String toString() => message;
}

class SaleRepo {
  SaleRepo([AppDatabase? db]) : _db = db ?? AppDatabase.instance;
  final AppDatabase _db;

  /// Saves a sale atomically:
  ///  - takes stock from batches First-Expiry-First-Out (expired batches are skipped)
  ///  - records cost/profit per batch buy price
  ///  - if [paid] < total, the remainder is added to the customer's baki khata
  Future<Sale> saveSale({
    required List<CartLine> cart,
    int discount = 0,
    required int paid,
    String? customerId,
    DateTime? at,
  }) async {
    if (cart.isEmpty) throw SaleException('Cart is empty');
    final subtotal = cart.fold<int>(0, (s, l) => s + l.lineTotal);
    if (discount < 0 || discount > subtotal) throw SaleException('Invalid discount');
    final total = subtotal - discount;
    if (paid < 0) throw SaleException('Invalid paid amount');
    final paidApplied = paid > total ? total : paid; // change is returned, not stored
    final due = total - paidApplied;
    if (due > 0 && customerId == null) {
      throw SaleException('Select a customer to record ৳ due in baki khata');
    }

    final soldAt = (at ?? DateTime.now());
    final soldAtMs = soldAt.toUtc().millisecondsSinceEpoch;
    final saleDate = dateKey(soldAt);
    final today = dateKey(DateTime.now());
    final saleId = newId();

    return _db.db.transaction((txn) async {
      final invoiceNo = await _nextInvoiceNo(txn);
      var cost = 0;
      final items = <Map<String, Object?>>[];

      for (final line in cart) {
        if (line.qty <= 0) throw SaleException('Invalid quantity for ${line.medicine.name}');
        var remaining = line.qty;
        final batches = await txn.query('stock_batches',
            where: 'medicine_id = ? AND deleted = 0 AND qty > 0 AND expiry_date >= ?',
            whereArgs: [line.medicine.id, today],
            orderBy: 'expiry_date, created_at');
        for (final b in batches) {
          if (remaining == 0) break;
          final take = remaining < (b['qty'] as int) ? remaining : b['qty'] as int;
          final buy = b['buy_price'] as int;
          await txn.update('stock_batches', {'qty': (b['qty'] as int) - take, ...touchSyncCols()},
              where: 'id = ?', whereArgs: [b['id']]);
          items.add({
            'id': newId(),
            'sale_id': saleId,
            'medicine_id': line.medicine.id,
            'batch_id': b['id'],
            'medicine_name': line.medicine.name,
            'qty': take,
            'unit_price': line.unitPrice,
            'buy_price': buy,
            'line_total': take * line.unitPrice,
            ...newSyncCols(),
          });
          cost += take * buy;
          remaining -= take;
        }
        if (remaining > 0) {
          throw SaleException('Not enough stock for ${line.medicine.name} (short by $remaining)');
        }
      }

      final profit = total - cost;
      await txn.insert('sales', {
        'id': saleId,
        'invoice_no': invoiceNo,
        'customer_id': customerId,
        'sold_at': soldAtMs,
        'sale_date': saleDate,
        'subtotal': subtotal,
        'discount': discount,
        'total': total,
        'paid': paidApplied,
        'due': due,
        'cost': cost,
        'profit': profit,
        ...newSyncCols(),
      });
      for (final item in items) {
        await txn.insert('sale_items', item);
      }
      if (due > 0) {
        await txn.insert('credit_entries', {
          'id': newId(),
          'customer_id': customerId,
          'type': 'due',
          'amount': due,
          'sale_id': saleId,
          'note': 'Invoice $invoiceNo',
          'entry_at': soldAtMs,
          'entry_date': saleDate,
          ...newSyncCols(),
        });
      }
      return Sale(
        id: saleId,
        invoiceNo: invoiceNo,
        customerId: customerId,
        soldAt: soldAtMs,
        total: total,
        paid: paidApplied,
        due: due,
        profit: profit,
        discount: discount,
      );
    });
  }

  /// Invoice numbers are device-local: <device-prefix>-<seq>, e.g. "A1F3-000042".
  /// The prefix keeps them unique across devices once cloud sync is added.
  Future<String> _nextInvoiceNo(Transaction txn) async {
    final seq = int.parse(await _db.meta('invoice_seq', txn: txn) ?? '0') + 1;
    await _db.setMeta('invoice_seq', '$seq', txn: txn);
    final device = (await _db.meta('device_id', txn: txn) ?? '0000').substring(0, 4).toUpperCase();
    return '$device-${seq.toString().padLeft(6, '0')}';
  }

  Future<List<Sale>> salesOn(String date) async {
    final rows = await _db.db.rawQuery('''
      SELECT s.*, c.name AS customer_name
      FROM sales s LEFT JOIN customers c ON c.id = s.customer_id
      WHERE s.sale_date = ? AND s.deleted = 0
      ORDER BY s.sold_at DESC
    ''', [date]);
    return rows.map(Sale.fromMap).toList();
  }

  Future<List<Map<String, Object?>>> itemsOf(String saleId) => _db.db.rawQuery('''
      SELECT medicine_name, SUM(qty) AS qty, unit_price, SUM(line_total) AS line_total
      FROM sale_items WHERE sale_id = ? AND deleted = 0
      GROUP BY medicine_id, unit_price
      ORDER BY medicine_name
    ''', [saleId]);
}
