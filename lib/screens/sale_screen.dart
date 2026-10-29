import 'package:flutter/material.dart';

import '../core/money.dart';
import '../data/medicine_repo.dart';
import '../data/sale_repo.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import 'customer_picker.dart';

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

  void _add(Medicine m) {
    if (m.stockQty <= 0) {
      showSnack(context, '${m.name} is out of stock (or all batches expired)', error: true);
      return;
    }
    setState(() {
      final existing = _cart.where((l) => l.medicine.id == m.id).firstOrNull;
      if (existing != null) {
        if (existing.qty < existing.available) existing.qty++;
      } else {
        _cart.add(CartLine(medicine: m, qty: 1, unitPrice: m.sellPrice, available: m.stockQty));
      }
      _search.clear();
      _results = [];
    });
    _searchFocus.requestFocus();
  }

  Future<void> _editLine(CartLine line) async {
    final qty = TextEditingController(text: '${line.qty}');
    final price = TextEditingController(text: Money.toInput(line.unitPrice));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(line.medicine.name),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          IntField(controller: qty, label: 'Quantity (max ${line.available})'),
          const SizedBox(height: 12),
          MoneyField(controller: price, label: 'Unit price'),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('OK')),
        ],
      ),
    );
    if (ok != true) return;
    final q = int.tryParse(qty.text) ?? line.qty;
    setState(() {
      line.qty = q.clamp(1, line.available);
      line.unitPrice = Money.parse(price.text);
    });
  }

  Future<void> _checkout() async {
    final sale = await showModalBottomSheet<Sale>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CheckoutSheet(cart: _cart, subtotal: _subtotal),
    );
    if (sale == null || !mounted) return;
    setState(_cart.clear);
    final msg = sale.due > 0
        ? 'Saved ${sale.invoiceNo}. ${Money.format(sale.due)} added to baki.'
        : 'Saved ${sale.invoiceNo} · ${Money.format(sale.total)}';
    showSnack(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Sale')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _search,
            focusNode: _searchFocus,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search medicine by name / generic / barcode',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(icon: const Icon(Icons.clear), onPressed: () {
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
    if (_results.isEmpty) return const EmptyState(icon: Icons.search_off, text: 'No medicine found');
    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final m = _results[i];
        final out = m.stockQty <= 0;
        return ListTile(
          title: Text(m.name),
          subtitle: Text([if (m.genericName != null) m.genericName!, 'Stock: ${m.stockQty} ${m.unit}'].join(' · ')),
          trailing: Text(Money.format(m.sellPrice), style: const TextStyle(fontWeight: FontWeight.bold)),
          enabled: !out,
          onTap: () => _add(m),
        );
      },
    );
  }

  Widget _buildCart() {
    if (_cart.isEmpty) {
      return const EmptyState(icon: Icons.shopping_cart_outlined, text: 'Search a medicine above to add it to the cart');
    }
    return ListView.separated(
      itemCount: _cart.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final l = _cart[i];
        return ListTile(
          onTap: () => _editLine(l),
          title: Text(l.medicine.name),
          subtitle: Text('${Money.format(l.unitPrice)} × ${l.qty} = ${Money.format(l.lineTotal)}'),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => setState(() => l.qty > 1 ? l.qty-- : _cart.removeAt(i)),
            ),
            Text('${l.qty}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: l.qty < l.available ? () => setState(() => l.qty++) : null,
            ),
          ]),
        );
      },
    );
  }

  Widget _buildFooter() => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHigh),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text('${_cart.length} items'),
                Text(Money.format(_subtotal), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ]),
            ),
            FilledButton.icon(onPressed: _checkout, icon: const Icon(Icons.check), label: const Text('Checkout')),
          ]),
        ),
      );
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
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Checkout', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            StatRow('Subtotal', Money.format(widget.subtotal)),
            const SizedBox(height: 8),
            MoneyField(controller: _discount, label: 'Discount', onChanged: (_) => setState(() {})),
            const SizedBox(height: 8),
            StatRow('Total', Money.format(_total), bold: true),
            const SizedBox(height: 8),
            MoneyField(controller: _paid, label: 'Cash received', onChanged: (_) => setState(() {})),
            const SizedBox(height: 8),
            if (_change > 0) StatRow('Return change', Money.format(_change), color: cs.primary),
            if (_due > 0) StatRow('Due (baki)', Money.format(_due), color: cs.error, bold: true),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.person_outline),
              label: Text(_customer == null
                  ? (_due > 0 ? 'Select customer (required for baki)' : 'Customer (optional)')
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
              child: Text(_saving ? 'Saving…' : 'Save sale'),
            ),
          ]),
        ),
      ),
    );
  }
}
