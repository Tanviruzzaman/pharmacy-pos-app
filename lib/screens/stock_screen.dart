import 'package:flutter/material.dart';

import '../core/ids.dart';
import '../core/money.dart';
import '../data/medicine_repo.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final _q = TextEditingController();
  List<Medicine> _list = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await MedicineRepo().search(_q.text, limit: 500);
    if (mounted) setState(() => _list = r);
  }

  Future<void> _open(Medicine m) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => MedicineDetailScreen(medicineId: m.id)));
    _load();
  }

  Future<void> _addMedicine() async {
    final m = await showMedicineForm(context);
    if (m == null || !mounted) return;
    // Go straight to adding the first batch.
    await showBatchForm(context, m);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: const Text('Stock')),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: _addMedicine, icon: const Icon(Icons.add), label: const Text('Add medicine')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _q,
            decoration: const InputDecoration(hintText: 'Search medicine', prefixIcon: Icon(Icons.search)),
            onChanged: (_) => _load(),
          ),
        ),
        Expanded(
          child: _list.isEmpty
              ? const EmptyState(icon: Icons.inventory_2_outlined, text: 'No medicines yet. Tap "Add medicine".')
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: _list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final m = _list[i];
                    final exp = m.nearestExpiry == null ? null : DateTime.parse(m.nearestExpiry!);
                    final soon = exp != null && exp.difference(today).inDays <= 90;
                    return ListTile(
                      title: Text(m.name),
                      subtitle: Text([
                        if (m.genericName != null) m.genericName!,
                        if (exp != null) 'Exp ${displayDateFmt.format(exp)}',
                      ].join(' · ')),
                      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('${m.stockQty} ${m.unit}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: m.stockQty == 0 ? Theme.of(context).colorScheme.error : null)),
                        Text(Money.format(m.sellPrice),
                            style: TextStyle(color: soon ? Theme.of(context).colorScheme.error : null)),
                      ]),
                      onTap: () => _open(m),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

class MedicineDetailScreen extends StatefulWidget {
  const MedicineDetailScreen({super.key, required this.medicineId});
  final String medicineId;

  @override
  State<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen> {
  Medicine? _m;
  List<StockBatch> _batches = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = MedicineRepo();
    final m = await repo.byId(widget.medicineId);
    final b = await repo.batchesFor(widget.medicineId);
    if (!mounted) return;
    setState(() {
      _m = m;
      _batches = b;
    });
  }

  Future<void> _adjust(StockBatch b) async {
    final c = TextEditingController(text: '${b.qty}');
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Batch ${b.batchNo ?? ''}'),
        content: IntField(controller: c, label: 'Quantity in hand'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, 'delete'),
              child: Text('Delete batch', style: TextStyle(color: Theme.of(ctx).colorScheme.error))),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, 'save'), child: const Text('Save')),
        ],
      ),
    );
    if (action == 'save') await MedicineRepo().adjustBatchQty(b.id, int.tryParse(c.text) ?? b.qty);
    if (action == 'delete') await MedicineRepo().deleteBatch(b.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final m = _m;
    if (m == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final today = DateTime.now();
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(m.name), actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () async {
            await showMedicineForm(context, existing: m);
            _load();
          },
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await showBatchForm(context, m);
          _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add stock'),
      ),
      body: ListView(padding: const EdgeInsets.only(bottom: 88), children: [
        ListTile(
          title: Text('${m.stockQty} ${m.unit} sellable'),
          subtitle: Text([
            if (m.genericName != null) m.genericName!,
            if (m.company != null) m.company!,
            'Price ${Money.format(m.sellPrice)}',
          ].join(' · ')),
        ),
        const Divider(),
        const Padding(padding: EdgeInsets.fromLTRB(16, 8, 16, 4), child: Text('Batches', style: TextStyle(fontWeight: FontWeight.bold))),
        if (_batches.isEmpty) const EmptyState(icon: Icons.layers_clear, text: 'No stock batches'),
        for (final b in _batches)
          ListTile(
            onTap: () => _adjust(b),
            leading: Icon(
              b.daysToExpiry(today) < 0
                  ? Icons.dangerous_outlined
                  : b.daysToExpiry(today) <= 90
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline,
              color: b.daysToExpiry(today) <= 90 ? cs.error : cs.primary,
            ),
            title: Text('${b.qty} ${m.unit}${b.batchNo != null ? ' · Batch ${b.batchNo}' : ''}'),
            subtitle: Text(
                'Exp ${displayDateFmt.format(b.expiry)} · Buy ${Money.format(b.buyPrice)} · Sell ${Money.format(b.sellPrice)}'),
          ),
      ]),
    );
  }
}

const units = ['pcs', 'tablet', 'capsule', 'strip', 'box', 'bottle', 'tube', 'vial', 'sachet'];

Future<Medicine?> showMedicineForm(BuildContext context, {Medicine? existing}) async {
  final name = TextEditingController(text: existing?.name);
  final generic = TextEditingController(text: existing?.genericName);
  final company = TextEditingController(text: existing?.company);
  final barcode = TextEditingController(text: existing?.barcode);
  final price = TextEditingController(text: existing == null ? '' : Money.toInput(existing.sellPrice));
  var unit = existing?.unit ?? 'pcs';
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        title: Text(existing == null ? 'New medicine' : 'Edit medicine'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, autofocus: true, decoration: const InputDecoration(labelText: 'Brand name *')),
            const SizedBox(height: 8),
            TextField(controller: generic, decoration: const InputDecoration(labelText: 'Generic name')),
            const SizedBox(height: 8),
            TextField(controller: company, decoration: const InputDecoration(labelText: 'Company')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: units.contains(unit) ? unit : 'pcs',
              decoration: const InputDecoration(labelText: 'Selling unit'),
              items: [for (final u in units) DropdownMenuItem(value: u, child: Text(u))],
              onChanged: (v) => setS(() => unit = v ?? 'pcs'),
            ),
            const SizedBox(height: 8),
            MoneyField(controller: price, label: 'Selling price per unit'),
            const SizedBox(height: 8),
            TextField(controller: barcode, decoration: const InputDecoration(labelText: 'Barcode')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    ),
  );
  if (ok != true || name.text.trim().isEmpty) return null;
  final repo = MedicineRepo();
  if (existing == null) {
    return repo.add(
      name: name.text,
      genericName: generic.text,
      company: company.text,
      unit: unit,
      sellPrice: Money.parse(price.text),
      barcode: barcode.text,
    );
  }
  final m = Medicine(
    id: existing.id,
    name: name.text,
    genericName: generic.text,
    company: company.text,
    unit: unit,
    sellPrice: Money.parse(price.text),
    barcode: barcode.text,
  );
  await repo.update(m);
  return m;
}

Future<bool> showBatchForm(BuildContext context, Medicine m) async {
  final batchNo = TextEditingController();
  final qty = TextEditingController();
  final buy = TextEditingController();
  final sell = TextEditingController(text: m.sellPrice > 0 ? Money.toInput(m.sellPrice) : '');
  DateTime? expiry;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        title: Text('Add stock · ${m.name}'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: batchNo, decoration: const InputDecoration(labelText: 'Batch no.')),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.event),
              label: Text(expiry == null ? 'Expiry date *' : 'Expiry ${displayDateFmt.format(expiry!)}'),
              onPressed: () async {
                final now = DateTime.now();
                final d = await showDatePicker(
                  context: ctx,
                  initialDate: expiry ?? DateTime(now.year + 1, now.month, 1),
                  firstDate: DateTime(now.year - 1),
                  lastDate: DateTime(now.year + 10),
                  initialDatePickerMode: DatePickerMode.year,
                );
                if (d != null) setS(() => expiry = d);
              },
            ),
            const SizedBox(height: 8),
            IntField(controller: qty, label: 'Quantity (${m.unit}) *'),
            const SizedBox(height: 8),
            MoneyField(controller: buy, label: 'Buying price per ${m.unit} *'),
            const SizedBox(height: 8),
            MoneyField(controller: sell, label: 'Selling price per ${m.unit} *'),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (expiry == null || (int.tryParse(qty.text) ?? 0) <= 0 || Money.parse(sell.text) <= 0) {
                showSnack(ctx, 'Expiry, quantity and selling price are required', error: true);
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  if (ok != true) return false;
  await MedicineRepo().addBatch(
    medicineId: m.id,
    batchNo: batchNo.text,
    expiry: expiry!,
    qty: int.parse(qty.text),
    buyPrice: Money.parse(buy.text),
    sellPrice: Money.parse(sell.text),
  );
  return true;
}
