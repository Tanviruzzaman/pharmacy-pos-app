import 'package:flutter/material.dart';

import '../core/money.dart';
import '../data/sale_repo.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../widgets/common.dart';

/// Shows what to do with the money after a return: cash to give back, baki reduced.
Future<void> showReturnResult(BuildContext context, SaleReturn ret) {
  final l = context.l10n;
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(Icons.assignment_return, size: 40, color: Theme.of(ctx).colorScheme.primary),
      title: Text(l.returnDone),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(Money.format(ret.amount), style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (ret.refund > 0)
          Text(l.giveBackCash(Money.format(ret.refund)),
              textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        if (ret.bakiReduced > 0) Text(l.bakiReduced(Money.format(ret.bakiReduced)), textAlign: TextAlign.center),
      ]),
      actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(l.ok))],
    ),
  );
}

/// Choose how many of each item come back. Pops true when a return was saved.
class ReturnScreen extends StatefulWidget {
  const ReturnScreen({super.key, required this.saleId});
  final String saleId;

  @override
  State<ReturnScreen> createState() => _ReturnScreenState();
}

class _ReturnScreenState extends State<ReturnScreen> {
  Receipt? _r;
  final _qty = <String, int>{};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    SaleRepo().receipt(widget.saleId).then((r) {
      if (mounted) setState(() => _r = r);
    });
  }

  /// Estimate shown before saving; the repo computes the exact figure.
  int get _value {
    final r = _r!;
    final gross = r.items.fold<int>(0, (s, i) => s + i.lineTotal * (_qty[i.key] ?? 0) ~/ (i.qty == 0 ? 1 : i.qty));
    return r.subtotal == 0 ? 0 : (gross * r.sale.total / r.subtotal).round();
  }

  Future<void> _save() async {
    final l = context.l10n;
    setState(() => _saving = true);
    try {
      final ret = await SaleRepo().returnItems(saleId: widget.saleId, qtyByKey: _qty);
      if (!mounted) return;
      await showReturnResult(context, ret);
      if (mounted) Navigator.pop(context, true);
    } on SaleException catch (e) {
      if (mounted) showSnack(context, l.saleError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = _r;
    if (r == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final lines = r.items.where((i) => i.returnableQty > 0).toList();
    final any = _qty.values.any((q) => q > 0);
    return Scaffold(
      appBar: AppBar(title: Text(l.returnTitle(r.sale.invoiceNo))),
      body: ListView.separated(
        itemCount: lines.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final line = lines[i];
          final q = _qty[line.key] ?? 0;
          final unit = line.soldUnit == null ? '' : ' ${l.unit(line.soldUnit)}';
          return ListTile(
            title: Text(line.name),
            subtitle: Text('${l.returnLine('${line.qty}$unit', '${line.returnableQty}$unit')}\n'
                '${Money.format(line.unitPrice)} × ${line.qty}'),
            isThreeLine: true,
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: q > 0 ? () => setState(() => _qty[line.key] = q - 1) : null,
              ),
              Text('$q', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: q < line.returnableQty ? () => setState(() => _qty[line.key] = q + 1) : null,
              ),
            ]),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            StatRow(l.returnValue, Money.format(any ? _value : 0), bold: true),
            if (r.sale.discount > 0) Text(l.returnDiscountNote, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: any && !_saving ? _save : null,
              icon: const Icon(Icons.assignment_return),
              label: Text(l.confirmReturn),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
          ]),
        ),
      ),
    );
  }
}
