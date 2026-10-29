import '../core/db.dart';
import '../core/ids.dart';
import '../models/models.dart';
import 'sale_repo.dart';

class ReportRepo {
  ReportRepo([AppDatabase? db]) : _db = db ?? AppDatabase.instance;
  final AppDatabase _db;

  Future<DailyReport> daily(DateTime day) async {
    final date = dateKey(day);
    final s = (await _db.db.rawQuery('''
      SELECT COUNT(*) AS n,
             COALESCE(SUM(total), 0) AS total,
             COALESCE(SUM(discount), 0) AS discount,
             COALESCE(SUM(cost), 0) AS cost,
             COALESCE(SUM(profit), 0) AS profit,
             COALESCE(SUM(paid), 0) AS paid,
             COALESCE(SUM(due), 0) AS due
      FROM sales WHERE sale_date = ? AND deleted = 0
    ''', [date]))
        .first;
    final payments = (await _db.db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) AS p FROM credit_entries
      WHERE entry_date = ? AND type = 'payment' AND deleted = 0
    ''', [date]))
        .first['p'] as int;
    // Returns count on the day they happen, whichever day the sale was.
    final r = (await _db.db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) AS amount, COALESCE(SUM(cost), 0) AS cost, COALESCE(SUM(refund), 0) AS refund
      FROM sale_returns WHERE return_date = ? AND deleted = 0
    ''', [date]))
        .first;
    final returns = r['amount'] as int;
    final returnCost = r['cost'] as int;

    return DailyReport(
      date: date,
      saleCount: s['n'] as int,
      totalSales: s['total'] as int,
      totalDiscount: s['discount'] as int,
      totalCost: (s['cost'] as int) - returnCost,
      profit: (s['profit'] as int) - (returns - returnCost),
      cashFromSales: s['paid'] as int,
      dueGiven: s['due'] as int,
      duePaymentsReceived: payments,
      returns: returns,
      refunds: r['refund'] as int,
      sales: await SaleRepo(_db).salesOn(date),
    );
  }
}
