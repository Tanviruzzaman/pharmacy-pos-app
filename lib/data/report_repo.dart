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

    return DailyReport(
      date: date,
      saleCount: s['n'] as int,
      totalSales: s['total'] as int,
      totalDiscount: s['discount'] as int,
      totalCost: s['cost'] as int,
      profit: s['profit'] as int,
      cashFromSales: s['paid'] as int,
      dueGiven: s['due'] as int,
      duePaymentsReceived: payments,
      sales: await SaleRepo(_db).salesOn(date),
    );
  }
}
