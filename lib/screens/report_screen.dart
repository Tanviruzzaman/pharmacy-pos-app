import 'package:flutter/material.dart';

import '../core/ids.dart';
import '../core/money.dart';
import '../data/report_repo.dart';
import '../data/sale_repo.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _day = DateTime.now();
  DailyReport? _r;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await ReportRepo().daily(_day);
    if (mounted) setState(() => _r = r);
  }

  void _shift(int days) {
    final next = _day.add(Duration(days: days));
    if (next.isAfter(DateTime.now())) return;
    setState(() => _day = next);
    _load();
  }

  Future<void> _showSale(Sale s) async {
    final items = await SaleRepo().itemsOf(s.id);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(16), children: [
          Text('Invoice ${s.invoiceNo}', style: Theme.of(context).textTheme.titleLarge),
          Text(displayDateTimeFmt.format(DateTime.fromMillisecondsSinceEpoch(s.soldAt))),
          const Divider(),
          for (final i in items)
            StatRow('${i['medicine_name']} × ${i['qty']}', Money.format(i['line_total'] as int)),
          const Divider(),
          if (s.discount > 0) StatRow('Discount', '−${Money.format(s.discount)}'),
          StatRow('Total', Money.format(s.total), bold: true),
          StatRow('Paid', Money.format(s.paid)),
          if (s.due > 0) StatRow('Baki${s.customerName != null ? ' (${s.customerName})' : ''}', Money.format(s.due)),
          StatRow('Profit', Money.format(s.profit)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = _r;
    final cs = Theme.of(context).colorScheme;
    final isToday = dateKey(_day) == dateKey(DateTime.now());
    return Scaffold(
      appBar: AppBar(title: const Text('Daily report')),
      body: r == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(12), children: [
              Row(children: [
                IconButton(onPressed: () => _shift(-1), icon: const Icon(Icons.chevron_left)),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                          context: context, initialDate: _day, firstDate: DateTime(2020), lastDate: DateTime.now());
                      if (d != null) {
                        setState(() => _day = d);
                        _load();
                      }
                    },
                    child: Text(isToday ? 'Today · ${displayDateFmt.format(_day)}' : displayDateFmt.format(_day),
                        style: const TextStyle(fontSize: 16)),
                  ),
                ),
                IconButton(onPressed: isToday ? null : () => _shift(1), icon: const Icon(Icons.chevron_right)),
              ]),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    StatRow('Sales (${r.saleCount} invoices)', Money.format(r.totalSales), bold: true),
                    StatRow('Discount given', Money.format(r.totalDiscount)),
                    StatRow('Cost of goods', Money.format(r.totalCost)),
                    StatRow('Profit', Money.format(r.profit), bold: true, color: r.profit >= 0 ? cs.primary : cs.error),
                  ]),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    StatRow('Cash from sales', Money.format(r.cashFromSales)),
                    StatRow('Baki collected', Money.format(r.duePaymentsReceived)),
                    StatRow('Cash in hand', Money.format(r.cashInHand), bold: true),
                    StatRow('New baki given', Money.format(r.dueGiven), color: cs.error),
                  ]),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 12, 4, 4),
                child: Text('Invoices', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              if (r.sales.isEmpty) const EmptyState(icon: Icons.receipt_long_outlined, text: 'No sales on this day'),
              for (final s in r.sales)
                ListTile(
                  onTap: () => _showSale(s),
                  title: Text(s.invoiceNo),
                  subtitle: Text([
                    displayDateTimeFmt.format(DateTime.fromMillisecondsSinceEpoch(s.soldAt)).split(', ').last,
                    if (s.customerName != null) s.customerName!,
                    if (s.due > 0) 'baki ${Money.format(s.due)}',
                  ].join(' · ')),
                  trailing: Text(Money.format(s.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
            ]),
    );
  }
}
