import 'package:flutter/material.dart';

import '../core/money.dart';
import '../data/medicine_repo.dart';
import '../data/sale_repo.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import 'customer_picker.dart';
import 'receipt_actions.dart';

class SaleScreen extends StatefulWidget {
  const SaleScreen({super.key});

  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  final _cart = <CartLine>[];
  List<Medicine> _results = [];

  int get _subtotal => _cart.fold(0, (s, l) => s + l.lineTotal);

  Future<void> _onSearch(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    final r = await MedicineRepo().search(q, limit: 30);
    if (mounted && _search.text == q) setState(() => _results = r);
  }

  /// Base units already in the cart for [m] on lines other than [except].
  int _usedElsewhere(Medicine m, CartLine? except) =>
      _cart.where((l) => l.medicine.id == m.id && l != except).fold(0, (s, l) => s + l.baseQty);

  void _add(Medicine m) {
    if (m.stockQty <= 0) {
      showSnack(context, context.l10n.outOfStock(m.name), error: true);
      return;
    }
    setState(() {
      final existing = _cart.where((l) => l.medicine.id == m.id && l.pack.factor == 1).firstOrNull;
      if (existing != null) {
        if (existing.qty < existing.maxQty) existing.qty++;
      } else if (_usedElsewhere(m, null) < m.stockQty) {
        _cart.add(CartLine(medicine: m, qty: 1, unitPrice: m.sellPrice, available: m.stockQty - _usedElsewhere(m, null)));
      }
      _search.clear();
      _results = [];
    });
    _searchFocus.requestFocus();
  }

  Future<void> _editLine(int index) async {
    final l = context.l10n;
    final line = _cart[index];
    final m = line.medicine;
    final free = m.stockQty - _usedElsewhere(m, line);
    var pack = line.pack;
    final qty = TextEditingController(text: '${line.qty}');
    final price = TextEditingController(text: Money.toInput(line.unitPrice));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(m.name),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            if (m.packUnits.length > 1) ...[
              Align(alignment: Alignment.centerLeft, child: Text(l.sellAs)),
              const SizedBox(height: 4),
              SegmentedButton<PackUnit>(
                segments: [
                  for (final p in m.packUnits)
                    ButtonSegment(value: p, label: Text(l.packName(m, p)), enabled: p.factor <= free),
                ],
                selected: {pack},
                onSelectionChanged: (v) => setS(() {
                  pack = v.first;
                  price.text = Money.toInput(m.sellPrice * pack.factor);
                  qty.text = '1';
                }),
              ),
              const SizedBox(height: 12),
            ],
            IntField(controller: qty, label: l.quantityMax('${free ~/ pack.factor}')),
            const SizedBox(height: 12),
            MoneyField(controller: price, label: l.pricePer(l.packName(m, pack))),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.ok)),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final maxQty = free ~/ pack.factor;
    final q = (int.tryParse(qty.text) ?? line.qty).clamp(1, maxQty < 1 ? 1 : maxQty);
    setState(() {
      _cart[index] = CartLine(
        medicine: m,
        qty: q,
        unitPrice: Money.parse(price.text),
        available: free,
        pack: pack,
      );
    });
  }

  Future<void> _checkout() async {
    final l = context.l10n;
    final sale = await showModalBottomSheet<Sale>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CheckoutSheet(cart: _cart, subtotal: _subtotal),
    );
    if (sale == null || !mounted) return;
    setState(_cart.clear);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.check_circle, size: 48, color: Theme.of(ctx).colorScheme.primary),
        title: Text(l.saleSaved),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l.invoiceNo(sale.invoiceNo)),
          const SizedBox(height: 4),
          Text(Money.format(sale.total), style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          if (sale.due > 0)
            Text(l.addedToBaki(Money.format(sale.due)), style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          const SizedBox(height: 16),
          ReceiptButtons(saleId: sale.id),
        ]),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(l.newSale))],
      ),
    );
    _searchFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.newSale)),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _search,
            focusNode: _searchFocus,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l.searchMedicineHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _search.clear();
                        _onSearch('');
                      }),
            ),
            onChanged: _onSearch,
          ),
        ),
        Expanded(child: _results.isNotEmpty || _search.text.isNotEmpty ? _buildResults() : _buildCart()),
        if (_cart.isNotEmpty) _buildFooter(),
      ]),
    );
  }

  Widget _buildResults() {
    final l = context.l10n;
    if (_results.isEmpty) return EmptyState(icon: Icons.search_off, text: l.noMedicineFound);
    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final m = _results[i];
        final out = m.stockQty <= 0;
        return ListTile(
          title: Text(m.name),
          subtitle: Text([if (m.genericName != null) m.genericName!, l.stockLabel(l.qty(m, m.stockQty))].join(' · ')),
          trailing: Text(Money.format(m.sellPrice), style: const TextStyle(fontWeight: FontWeight.bold)),
          enabled: !out,
          onTap: () => _add(m),
        );
      },
    );
  }

  Widget _buildCart() {
    final l = context.l10n;
    if (_cart.isEmpty) return EmptyState(icon: Icons.shopping_cart_outlined, text: l.cartEmpty);
    return ListView.separated(
      itemCount: _cart.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final line = _cart[i];
        final unit = l.packName(line.medicine, line.pack);
        return ListTile(
          onTap: () => _editLine(i),
          title: Text(line.medicine.name),
          subtitle: Text('${Money.format(line.unitPrice)} × ${line.qty} $unit = ${Money.format(line.lineTotal)}'),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => setState(() => line.qty > 1 ? line.qty-- : _cart.removeAt(i)),
            ),
            Text('${line.qty}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: line.qty < line.maxQty ? () => setState(() => line.qty++) : null,
            ),
          ]),
        );
      },
    );
  }

  Widget _buildFooter() {
    final l = context.l10n;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHigh),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(l.itemsCount('${_cart.length}')),
              Text(Money.format(_subtotal), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ]),
          ),
          FilledButton.icon(onPressed: _checkout, icon: const Icon(Icons.check), label: Text(l.checkout)),
        ]),
      ),
    );
  }
}

class _CheckoutSheet extends StatefulWidget {
  const _CheckoutSheet({required this.cart, required this.subtotal});
  final List<CartLine> cart;
  final int subtotal;

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  final _discount = TextEditingController();
  late final _paid = TextEditingController(text: Money.toInput(widget.subtotal));
  Customer? _customer;
  bool _saving = false;

  int get _total => widget.subtotal - Money.parse(_discount.text);
  int get _paidAmt => Money.parse(_paid.text);
  int get _due => (_total - _paidAmt).clamp(0, _total);
  int get _change => (_paidAmt - _total).clamp(0, 1 << 31);

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final sale = await SaleRepo().saveSale(
        cart: widget.cart,
        discount: Money.parse(_discount.text),
        paid: _paidAmt,
        customerId: _customer?.id,
      );
      if (mounted) Navigator.pop(context, sale);
    } on SaleException catch (e) {
      if (mounted) showSnack(context, context.l10n.saleError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l.checkout, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            StatRow(l.subtotal, Money.format(widget.subtotal)),
            const SizedBox(height: 8),
            MoneyField(controller: _discount, label: l.discount, onChanged: (_) => setState(() {})),
            const SizedBox(height: 8),
            StatRow(l.total, Money.format(_total), bold: true),
            const SizedBox(height: 8),
            MoneyField(controller: _paid, label: l.cashReceived, onChanged: (_) => setState(() {})),
            const SizedBox(height: 8),
            if (_change > 0) StatRow(l.returnChange, Money.format(_change), color: cs.primary),
            if (_due > 0) StatRow(l.dueBaki, Money.format(_due), color: cs.error, bold: true),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.person_outline),
              label: Text(_customer == null
                  ? (_due > 0 ? l.selectCustomerRequired : l.customerOptional)
                  : '${_customer!.name}${_customer!.phone != null ? ' · ${_customer!.phone}' : ''}'),
              onPressed: () async {
                final c = await pickCustomer(context);
                if (c != null) setState(() => _customer = c);
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving || _total < 0 ? null : _save,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: Text(_saving ? l.saving : l.saveSale),
            ),
          ]),
        ),
      ),
    );
  }
}
