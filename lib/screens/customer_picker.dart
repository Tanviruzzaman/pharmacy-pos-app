import 'package:flutter/material.dart';

import '../core/money.dart';
import '../data/customer_repo.dart';
import '../models/models.dart';

/// Search existing customers or create a new one. Returns the chosen customer.
Future<Customer?> pickCustomer(BuildContext context) => showDialog<Customer>(
      context: context,
      builder: (_) => const _CustomerPicker(),
    );

/// Simple add/edit customer dialog. Returns the saved customer.
Future<Customer?> editCustomer(BuildContext context, {Customer? existing, String initialName = ''}) async {
  final name = TextEditingController(text: existing?.name ?? initialName);
  final phone = TextEditingController(text: existing?.phone ?? '');
  final address = TextEditingController(text: existing?.address ?? '');
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(existing == null ? 'New customer' : 'Edit customer'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, autofocus: true, decoration: const InputDecoration(labelText: 'Name *')),
        const SizedBox(height: 8),
        TextField(
            controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')),
        const SizedBox(height: 8),
        TextField(controller: address, decoration: const InputDecoration(labelText: 'Address')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
      ],
    ),
  );
  if (ok != true || name.text.trim().isEmpty) return null;
  final repo = CustomerRepo();
  if (existing == null) {
    return repo.add(name: name.text, phone: phone.text, address: address.text);
  }
  final updated = Customer(id: existing.id, name: name.text, phone: phone.text, address: address.text);
  await repo.update(updated);
  return updated;
}

class _CustomerPicker extends StatefulWidget {
  const _CustomerPicker();

  @override
  State<_CustomerPicker> createState() => _CustomerPickerState();
}

class _CustomerPickerState extends State<_CustomerPicker> {
  final _q = TextEditingController();
  List<Customer> _list = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await CustomerRepo().list(query: _q.text);
    if (mounted) setState(() => _list = r);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Customer'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(children: [
          TextField(
            controller: _q,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Search name or phone', prefixIcon: Icon(Icons.search)),
            onChanged: (_) => _load(),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(children: [
              for (final c in _list)
                ListTile(
                  title: Text(c.name),
                  subtitle: c.phone == null ? null : Text(c.phone!),
                  trailing: c.balance > 0 ? Text(Money.format(c.balance)) : null,
                  onTap: () => Navigator.pop(context, c),
                ),
            ]),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton.icon(
          icon: const Icon(Icons.person_add),
          label: const Text('New'),
          onPressed: () async {
            final c = await editCustomer(context, initialName: _q.text);
            if (c != null && context.mounted) Navigator.pop(context, c);
          },
        ),
      ],
    );
  }
}
