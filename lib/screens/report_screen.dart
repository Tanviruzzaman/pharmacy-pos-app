import 'package:flutter/material.dart';

import '../core/ids.dart';
import '../core/money.dart';
import '../data/report_repo.dart';
import '../data/sale_repo.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import 'receipt_actions.dart';
import 'return_screen.dart';

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
    final receipt = await SaleRepo().receipt(s.id);
    if (receipt == null || !mounted) return;
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _InvoiceSheet(receipt: receipt),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = _r;
    final cs = Theme.of(context).colorScheme;
    final isToday = dateKey(_day) == dateKey(DateTime.now());
    return Scaffold(
      appBar: AppBar(title: Text(l.dailyReport)),
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
                    child: Text(isToday ? '${l.today} · ${displayDateFmt.format(_day)}' : displayDateFmt.format(_day),
                        style: const TextStyle(fontSize: 16)),
                  ),
                ),
                IconButton(onPressed: isToday ? null : () => _shift(1), icon: const Icon(Icons.chevron_right)),
              ]),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    StatRow(l.salesInvoices('${r.saleCount}'), Money.format(r.totalSales), bold: r.returns == 0),
                    if (r.returns > 0) ...[
                      StatRow(l.returns, '−${Money.format(r.returns)}', color: cs.error),
                      StatRow(l.netSales, Money.format(r.netSales), bold: true),
                    ],
                    StatRow(l.discountGiven, Money.format(r.totalDiscount)),
                    StatRow(l.costOfGoods, Money.format(r.totalCost)),
                    StatRow(l.profit, Money.format(r.profit), bold: true, color: r.profit >= 0 ? cs.primary : cs.error),
                  ]),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    StatRow(l.cashFromSales, Money.format(r.cashFromSales)),
                    StatRow(l.bakiCollected, Money.format(r.duePaymentsReceived)),
                    if (r.refunds > 0) StatRow(l.cashRefunded, '−${Money.format(r.refunds)}', color: cs.error),
                    StatRow(l.cashInHand, Money.format(r.cashInHand), bold: true),
                    StatRow(l.newBakiGiven, Money.format(r.dueGiven), color: cs.error),
                  ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                child: Text(l.invoices, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              if (r.sales.isEmpty) EmptyState(icon: Icons.receipt_long_outlined, text: l.noSalesDay),
              for (final s in r.sales)
                ListTile(
                  onTap: () => _showSale(s),
                  title: Text(s.invoiceNo),
                  subtitle: Text([
                    displayDateTimeFmt.format(DateTime.fromMillisecondsSinceEpoch(s.soldAt)).split(', ').last,
                    if (s.customerName != null) s.customerName!,
                    if (s.due > 0) '${l.dueBaki} ${Money.format(s.due)}',
                    if (s.fullyReturned)
                      l.returned
                    else if (s.returned > 0)
                      l.partlyReturned,
                  ].join(' · ')),
                  trailing: Text(Money.format(s.total),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: s.fullyReturned ? TextDecoration.lineThrough : null)),
                ),
            ]),
    );
  }
}

class _InvoiceSheet extends StatelessWidget {
  const _InvoiceSheet({required this.receipt});
  final Receipt receipt;

  Future<void> _cancelInvoice(BuildContext context) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.cancelInvoice),
        content: Text(l.cancelInvoiceConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.no)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.cancelInvoice)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      final ret = await SaleRepo().cancelSale(receipt.sale.id);
      if (context.mounted) {
        await showReturnResult(context, ret);
        if (context.mounted) Navigator.pop(context, true);
      }
    } on SaleException catch (e) {
      if (context.mounted) showSnack(context, l.saleError(e), error: true);
    }
  }

  Future<void> _returnItems(BuildContext context) async {
    final done = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => ReturnScreen(saleId: receipt.sale.id)));
    if (done == true && context.mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = receipt.sale;
    final cs = Theme.of(context).colorScheme;
    final canReturn = receipt.items.any((i) => i.returnableQty > 0);
    return SafeArea(
      child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(16), children: [
        Text(l.invoiceNo(s.invoiceNo), style: Theme.of(context).textTheme.titleLarge),
        Text(displayDateTimeFmt.format(receipt.soldAt)),
        const Divider(),
        for (final i in receipt.items)
          StatRow(
            '${i.name} × ${i.qty}${i.soldUnit == null ? '' : ' ${l.unit(i.soldUnit)}'}'
            '${i.returnedQty > 0 ? '  (${l.returned} ${i.returnedQty})' : ''}',
            Money.format(i.lineTotal),
          ),
        const Divider(),
        if (s.discount > 0) StatRow(l.discount, '−${Money.format(s.discount)}'),
        StatRow(l.total, Money.format(s.total), bold: true),
        StatRow(l.paid, Money.format(s.paid)),
        if (s.due > 0) StatRow('${l.dueBaki}${s.customerName != null ? ' (${s.customerName})' : ''}', Money.format(s.due)),
        if (s.returned > 0) StatRow(l.returned, '−${Money.format(s.returned)}', color: cs.error),
        StatRow(l.profit, Money.format(s.profit)),
        const SizedBox(height: 12),
        ReceiptButtons(saleId: s.id),
        if (canReturn) ...[
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _returnItems(context),
                icon: const Icon(Icons.assignment_return_outlined),
                label: Text(l.returnItems),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _cancelInvoice(context),
                icon: Icon(Icons.cancel_outlined, color: cs.error),
                label: Text(l.cancelInvoice, style: TextStyle(color: cs.error)),
              ),
            ),
          ]),
        ],
      ]),
    );
  }
}
