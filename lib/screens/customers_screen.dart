import 'package:flutter/material.dart';

import '../core/ids.dart';
import '../core/money.dart';
import '../data/customer_repo.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Baki khata')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text('Customer'),
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
            child: StatRow('Total baki to collect', Money.format(_total), bold: true),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _q,
                decoration: const InputDecoration(hintText: 'Search name / phone', prefixIcon: Icon(Icons.search)),
                onChanged: (_) => _load(),
              ),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Has due'),
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
              ? const EmptyState(icon: Icons.menu_book_outlined, text: 'No customers here')
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
    final amount = TextEditingController(text: type == 'payment' && (_c?.balance ?? 0) > 0 ? Money.toInput(_c!.balance) : '');
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(type == 'payment' ? 'Payment received' : 'Add baki'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          MoneyField(controller: amount, label: 'Amount', autofocus: true),
          const SizedBox(height: 8),
          TextField(controller: note, decoration: const InputDecoration(labelText: 'Note')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
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
              if (c.phone != null && c.phone!.isNotEmpty) StatRow('Phone', c.phone!),
              StatRow('Current baki', Money.format(c.balance), bold: true, color: c.balance > 0 ? cs.error : cs.primary),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: FilledButton.icon(
                      onPressed: () => _addEntry('payment'),
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Got payment')),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                      onPressed: () => _addEntry('due'), icon: const Icon(Icons.add), label: const Text('Add baki')),
                ),
              ]),
            ]),
          ),
        ),
        Expanded(
          child: _entries.isEmpty
              ? const EmptyState(icon: Icons.receipt_long_outlined, text: 'No entries yet')
              : ListView.separated(
                  itemCount: _entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final e = _entries[i];
                    final when = DateTime.fromMillisecondsSinceEpoch(e.entryAt);
                    return ListTile(
                      leading: Icon(e.isDue ? Icons.arrow_upward : Icons.arrow_downward,
                          color: e.isDue ? cs.error : cs.primary),
                      title: Text(e.isDue ? 'Baki' : 'Payment'),
                      subtitle: Text([displayDateTimeFmt.format(when), if (e.note != null) e.note!].join(' · ')),
                      trailing: Text('${e.isDue ? '+' : '−'}${Money.format(e.amount)}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: e.isDue ? cs.error : cs.primary)),
                      onLongPress: e.saleId != null
                          ? null
                          : () async {
                              final del = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete this entry?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
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
