import 'package:sqflite/sqflite.dart';

import '../core/db.dart';
import '../core/ids.dart';
import '../models/models.dart';

enum SaleError {
  emptyCart,
  invalidDiscount,
  invalidPaid,
  dueNeedsCustomer,
  invalidQty,
  notEnoughStock,
  notFound,
  returnTooMuch,
  nothingToReturn,
}

/// [code] lets the UI show the message in the user's language; [name] is the medicine involved, if any.
class SaleException implements Exception {
  SaleException(this.code, [this.name]);
  final SaleError code;
  final String? name;
  @override
  String toString() => 'SaleException(${code.name}${name == null ? '' : ', $name'})';
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
    if (cart.isEmpty) throw SaleException(SaleError.emptyCart);
    final subtotal = cart.fold<int>(0, (s, l) => s + l.lineTotal);
    if (discount < 0 || discount > subtotal) throw SaleException(SaleError.invalidDiscount);
    final total = subtotal - discount;
    if (paid < 0) throw SaleException(SaleError.invalidPaid);
    final paidApplied = paid > total ? total : paid; // change is returned, not stored
    final due = total - paidApplied;
    if (due > 0 && customerId == null) {
      throw SaleException(SaleError.dueNeedsCustomer);
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
        if (line.qty <= 0) throw SaleException(SaleError.invalidQty, line.medicine.name);
        final baseQty = line.baseQty;
        var remaining = baseQty;
        var allocated = 0;
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
          remaining -= take;
          // Split the line total across batches by quantity; the last part takes the rounding.
          final part = remaining == 0 ? line.lineTotal - allocated : line.lineTotal * take ~/ baseQty;
          allocated += part;
          items.add({
            'id': newId(),
            'sale_id': saleId,
            'medicine_id': line.medicine.id,
            'batch_id': b['id'],
            'medicine_name': line.medicine.name,
            'qty': take,
            'unit_price': line.unitPrice,
            'buy_price': buy,
            'line_total': part,
            'sold_unit': line.pack.name,
            'unit_factor': line.pack.factor,
            ...newSyncCols(),
          });
          cost += take * buy;
        }
        if (remaining > 0) {
          throw SaleException(SaleError.notEnoughStock, line.medicine.name);
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

  static const _saleSelect = '''
    SELECT s.*, c.name AS customer_name, c.phone AS customer_phone,
           (SELECT COALESCE(SUM(r.amount), 0) FROM sale_returns r WHERE r.sale_id = s.id AND r.deleted = 0) AS returned
    FROM sales s LEFT JOIN customers c ON c.id = s.customer_id
  ''';

  Future<List<Sale>> salesOn(String date) async {
    final rows = await _db.db.rawQuery('''
      $_saleSelect
      WHERE s.sale_date = ? AND s.deleted = 0
      ORDER BY s.sold_at DESC
    ''', [date]);
    return rows.map(Sale.fromMap).toList();
  }

  Future<Receipt?> receipt(String saleId) async {
    final rows = await _db.db.rawQuery('$_saleSelect WHERE s.id = ?', [saleId]);
    if (rows.isEmpty) return null;
    return Receipt(
      sale: Sale.fromMap(rows.first),
      customerPhone: rows.first['customer_phone'] as String?,
      items: await itemsOf(saleId),
    );
  }

  Future<List<ReceiptLine>> itemsOf(String saleId, {DatabaseExecutor? txn}) async {
    final rows = await (txn ?? _db.db).rawQuery('''
      SELECT medicine_id, medicine_name, sold_unit, unit_factor, unit_price,
             SUM(qty) AS qty, SUM(returned_qty) AS returned_qty, SUM(line_total) AS line_total
      FROM sale_items WHERE sale_id = ? AND deleted = 0
      GROUP BY medicine_id, sold_unit, unit_factor, unit_price
      ORDER BY medicine_name, unit_factor
    ''', [saleId]);
    return rows.map(ReceiptLine.fromMap).toList();
  }

  /// Takes items back from a sale. [qtyByKey] maps [ReceiptLine.key] to the
  /// quantity (in sold units) being returned.
  ///  - stock goes back into the batches it was sold from
  ///  - the return's value includes its share of the invoice discount
  ///  - that value first reduces the customer's baki, the rest is cash refunded
  Future<SaleReturn> returnItems({required String saleId, required Map<String, int> qtyByKey, DateTime? at}) async {
    final when = at ?? DateTime.now();
    final whenMs = when.toUtc().millisecondsSinceEpoch;
    return _db.db.transaction((txn) async {
      final sale = (await txn.query('sales', where: 'id = ? AND deleted = 0', whereArgs: [saleId])).firstOrNull;
      if (sale == null) throw SaleException(SaleError.notFound);
      final lines = {for (final l in await itemsOf(saleId, txn: txn)) l.key: l};

      var gross = 0;
      var cost = 0;
      for (final MapEntry(:key, value: qty) in qtyByKey.entries) {
        if (qty <= 0) continue;
        final line = lines[key];
        if (line == null || qty > line.returnableQty) {
          throw SaleException(SaleError.returnTooMuch, line?.name);
        }
        var remaining = qty * line.unitFactor;
        // Latest-expiry batch first: the reverse of how the sale took stock.
        final rows = await txn.rawQuery('''
          SELECT i.*, b.qty AS batch_qty FROM sale_items i JOIN stock_batches b ON b.id = i.batch_id
          WHERE i.sale_id = ? AND i.deleted = 0 AND i.medicine_id = ? AND i.sold_unit IS ?
            AND i.unit_factor = ? AND i.unit_price = ? AND i.qty > i.returned_qty
          ORDER BY b.expiry_date DESC
        ''', [saleId, line.medicineId, line.soldUnit, line.unitFactor, line.unitPrice]);
        for (final r in rows) {
          if (remaining == 0) break;
          final itemQty = r['qty'] as int;
          final back = remaining < itemQty - (r['returned_qty'] as int) ? remaining : itemQty - (r['returned_qty'] as int);
          await txn.update('sale_items', {'returned_qty': (r['returned_qty'] as int) + back, ...touchSyncCols()},
              where: 'id = ?', whereArgs: [r['id']]);
          await txn.update('stock_batches', {'qty': (r['batch_qty'] as int) + back, ...touchSyncCols()},
              where: 'id = ?', whereArgs: [r['batch_id']]);
          gross += (r['line_total'] as int) * back ~/ itemQty;
          cost += back * (r['buy_price'] as int);
          remaining -= back;
        }
      }
      if (gross == 0 && cost == 0) throw SaleException(SaleError.nothingToReturn);

      final total = sale['total'] as int;
      final subtotal = total + (sale['discount'] as int);
      final amount = subtotal == 0 ? 0 : (gross * total / subtotal).round();

      final customerId = sale['customer_id'] as String?;
      var bakiReduced = 0;
      if (customerId != null) {
        final bal = (await txn.rawQuery('''
          SELECT COALESCE(SUM(CASE WHEN type = 'due' THEN amount ELSE -amount END), 0) AS b
          FROM credit_entries WHERE customer_id = ? AND deleted = 0
        ''', [customerId])).first['b'] as int;
        bakiReduced = bal <= 0 ? 0 : (bal < amount ? bal : amount);
      }
      final ret = SaleReturn(
        id: newId(),
        saleId: saleId,
        amount: amount,
        cost: cost,
        refund: amount - bakiReduced,
        bakiReduced: bakiReduced,
        returnedAt: whenMs,
      );
      await txn.insert('sale_returns', {
        'id': ret.id,
        'sale_id': saleId,
        'returned_at': whenMs,
        'return_date': dateKey(when),
        'amount': amount,
        'cost': cost,
        'refund': ret.refund,
        'baki_reduced': bakiReduced,
        ...newSyncCols(),
      });
      if (bakiReduced > 0) {
        await txn.insert('credit_entries', {
          'id': newId(),
          'customer_id': customerId,
          'type': 'return',
          'amount': bakiReduced,
          'sale_id': saleId,
          'note': 'Return ${sale['invoice_no']}',
          'entry_at': whenMs,
          'entry_date': dateKey(when),
          ...newSyncCols(),
        });
      }
      return ret;
    });
  }

  /// Returns everything still returnable on the invoice.
  Future<SaleReturn> cancelSale(String saleId) async {
    final lines = await itemsOf(saleId);
    return returnItems(saleId: saleId, qtyByKey: {
      for (final l in lines)
        if (l.returnableQty > 0) l.key: l.returnableQty,
    });
  }
}
