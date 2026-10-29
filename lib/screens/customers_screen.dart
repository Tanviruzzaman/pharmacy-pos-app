import 'package:flutter/material.dart';

import '../core/ids.dart';
import '../core/money.dart';
import '../data/customer_repo.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import 'customer_picker.dart';

/// Baki khata: customers and how much each one owes.
class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _q = TextEditingController();
  bool _onlyDue = true;
  List<Customer> _list = [];
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = CustomerRepo();
    final r = await repo.list(query: _q.text, onlyWithDue: _onlyDue);
    final t = await repo.totalOutstanding();
    if (!mounted) return;
    setState(() {
      _list = r;
      _total = t;
    });
  }

  Future<void> _open(Customer c) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerLedgerScreen(customerId: c.id)));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.bakiKhata)),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: Text(l.customer),
        onPressed: () async {
          final c = await editCustomer(context);
          if (c != null) _open(c);
        },
      ),
      body: Column(children: [
        Card(
          margin: const EdgeInsets.all(12),
          color: Theme.of(context).colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: StatRow(l.totalBakiToCollect, Money.format(_total), bold: true),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _q,
                decoration: InputDecoration(hintText: l.searchNamePhone, prefixIcon: const Icon(Icons.search)),
                onChanged: (_) => _load(),
              ),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: Text(l.hasDue),
              selected: _onlyDue,
              onSelected: (v) {
                setState(() => _onlyDue = v);
                _load();
              },
            ),
          ]),
        ),
        Expanded(
          child: _list.isEmpty
              ? EmptyState(icon: Icons.menu_book_outlined, text: l.noCustomers)
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: _list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final c = _list[i];
                    return ListTile(
                      leading: CircleAvatar(child: Text(c.name.isEmpty ? '?' : c.name[0].toUpperCase())),
                      title: Text(c.name),
                      subtitle: c.phone == null || c.phone!.isEmpty ? null : Text(c.phone!),
                      trailing: Text(Money.format(c.balance),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: c.balance > 0 ? Theme.of(context).colorScheme.error : null)),
                      onTap: () => _open(c),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

class CustomerLedgerScreen extends StatefulWidget {
  const CustomerLedgerScreen({super.key, required this.customerId});
  final String customerId;

  @override
  State<CustomerLedgerScreen> createState() => _CustomerLedgerScreenState();
}

class _CustomerLedgerScreenState extends State<CustomerLedgerScreen> {
  Customer? _c;
  List<CreditEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = CustomerRepo();
    final c = await repo.byId(widget.customerId);
    final e = await repo.ledger(widget.customerId);
    if (!mounted) return;
    setState(() {
      _c = c;
      _entries = e;
    });
  }

  Future<void> _addEntry(String type) async {
    final l = context.l10n;
    final amount =
        TextEditingController(text: type == 'payment' && (_c?.balance ?? 0) > 0 ? Money.toInput(_c!.balance) : '');
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(type == 'payment' ? l.paymentReceived : l.addBaki),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          MoneyField(controller: amount, label: l.amount, autofocus: true),
          const SizedBox(height: 8),
          TextField(controller: note, decoration: InputDecoration(labelText: l.note)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.save)),
        ],
      ),
    );
    final amt = Money.parse(amount.text);
    if (ok != true || amt <= 0) return;
    await CustomerRepo().addEntry(customerId: widget.customerId, type: type, amount: amt, note: note.text);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (c == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(c.name), actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () async {
            await editCustomer(context, existing: c);
            _load();
          },
        ),
      ]),
      body: Column(children: [
        Card(
          margin: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              if (c.phone != null && c.phone!.isNotEmpty) StatRow(l.phone, c.phone!),
              StatRow(l.currentBaki, Money.format(c.balance), bold: true, color: c.balance > 0 ? cs.error : cs.primary),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: FilledButton.icon(
                      onPressed: () => _addEntry('payment'),
                      icon: const Icon(Icons.payments_outlined),
                      label: Text(l.gotPayment)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                      onPressed: () => _addEntry('due'), icon: const Icon(Icons.add), label: Text(l.addBaki)),
                ),
              ]),
            ]),
          ),
        ),
        Expanded(
          child: _entries.isEmpty
              ? EmptyState(icon: Icons.receipt_long_outlined, text: l.noEntries)
              : ListView.separated(
                  itemCount: _entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final e = _entries[i];
                    final when = DateTime.fromMillisecondsSinceEpoch(e.entryAt);
                    final color = e.isDue ? cs.error : cs.primary;
                    return ListTile(
                      leading: Icon(
                          e.isDue
                              ? Icons.arrow_upward
                              : e.isReturn
                                  ? Icons.assignment_return_outlined
                                  : Icons.arrow_downward,
                          color: color),
                      title: Text(e.isDue
                          ? l.entryBaki
                          : e.isReturn
                              ? l.entryReturn
                              : l.entryPayment),
                      subtitle: Text([displayDateTimeFmt.format(when), if (e.note != null) e.note!].join(' · ')),
                      trailing: Text('${e.isDue ? '+' : '−'}${Money.format(e.amount)}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                      onLongPress: e.saleId != null
                          ? null
                          : () async {
                              final del = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(l.deleteEntry),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.no)),
                                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete)),
                                  ],
                                ),
                              );
                              if (del == true) {
                                await CustomerRepo().deleteEntry(e.id);
                                _load();
                              }
                            },
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
