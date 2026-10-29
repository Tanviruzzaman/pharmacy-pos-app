import 'package:flutter/material.dart';

import '../core/ids.dart';
import '../core/money.dart';
import '../data/medicine_repo.dart';
import '../l10n/l10n.dart';
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
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final today = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: Text(l.stock)),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: _addMedicine, icon: const Icon(Icons.add), label: Text(l.addMedicine)),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _q,
            decoration: InputDecoration(hintText: l.searchMedicine, prefixIcon: const Icon(Icons.search)),
            onChanged: (_) => _load(),
          ),
        ),
        Expanded(
          child: _list.isEmpty
              ? EmptyState(icon: Icons.inventory_2_outlined, text: l.noMedicines)
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: _list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final m = _list[i];
                    final exp = m.nearestExpiry == null ? null : DateTime.parse(m.nearestExpiry!);
                    final soon = exp != null && exp.difference(today).inDays <= 90;
                    return ListTile(
                      title: Row(children: [
                        Flexible(child: Text(m.name)),
                        if (m.isLowStock) ...[
                          const SizedBox(width: 8),
                          _Tag(l.lowTag, cs.error),
                        ],
                      ]),
                      subtitle: Text([
                        if (m.genericName != null) m.genericName!,
                        if (exp != null) l.expShort(displayDateFmt.format(exp)),
                      ].join(' · ')),
                      trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${m.stockQty} ${l.unit(m.unit)}',
                                style: TextStyle(fontWeight: FontWeight.bold, color: m.stockQty == 0 ? cs.error : null)),
                            Text(Money.format(m.sellPrice), style: TextStyle(color: soon ? cs.error : null)),
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

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(border: Border.all(color: color), borderRadius: BorderRadius.circular(4)),
        child: Text(text, style: TextStyle(color: color, fontSize: 12)),
      );
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
    final l = context.l10n;
    final c = TextEditingController(text: '${b.qty}');
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.batchTitle(b.batchNo ?? '')),
        content: IntField(controller: c, label: l.qtyInHand(l.unit(_m!.unit))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, 'delete'),
              child: Text(l.deleteBatch, style: TextStyle(color: Theme.of(ctx).colorScheme.error))),
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, 'save'), child: Text(l.save)),
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
    final l = context.l10n;
    final today = DateTime.now();
    final cs = Theme.of(context).colorScheme;
    final unit = l.unit(m.unit);
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
        label: Text(l.addStock),
      ),
      body: ListView(padding: const EdgeInsets.only(bottom: 88), children: [
        ListTile(
          title: Text(l.sellable(l.qty(m, m.stockQty)),
              style: TextStyle(color: m.isLowStock ? cs.error : null, fontWeight: FontWeight.bold)),
          subtitle: Text([
            if (m.genericName != null) m.genericName!,
            if (m.company != null) m.company!,
            l.priceLabel('${Money.format(m.sellPrice)} / $unit'),
            if (m.reorderLevel > 0) l.lowStockAt('${m.reorderLevel}'),
          ].join(' · ')),
        ),
        const Divider(),
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(l.batches, style: const TextStyle(fontWeight: FontWeight.bold))),
        if (_batches.isEmpty) EmptyState(icon: Icons.layers_clear, text: l.noBatches),
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
            title: Text('${b.qty} $unit${b.batchNo != null ? ' · ${l.batchTitle(b.batchNo!)}' : ''}'),
            subtitle: Text('${l.expShort(displayDateFmt.format(b.expiry))} · '
                '${l.batchPrices(Money.format(b.buyPrice), Money.format(b.sellPrice), unit)}'),
          ),
      ]),
    );
  }
}

const units = ['pcs', 'tablet', 'capsule', 'bottle', 'tube', 'vial', 'sachet', 'strip', 'box'];

int _intOr0(String s) => int.tryParse(s.trim()) ?? 0;
String _blankIf0(int v) => v == 0 ? '' : '$v';

Future<Medicine?> showMedicineForm(BuildContext context, {Medicine? existing}) async {
  final l = context.l10n;
  final name = TextEditingController(text: existing?.name);
  final generic = TextEditingController(text: existing?.genericName);
  final company = TextEditingController(text: existing?.company);
  final barcode = TextEditingController(text: existing?.barcode);
  final price = TextEditingController(text: existing == null ? '' : Money.toInput(existing.sellPrice));
  final strip = TextEditingController(text: _blankIf0(existing?.stripSize ?? 0));
  final box = TextEditingController(text: _blankIf0(existing?.boxSize ?? 0));
  final reorder = TextEditingController(text: _blankIf0(existing?.reorderLevel ?? 0));
  var unit = existing?.unit ?? 'tablet';
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) {
        final u = l.unit(unit);
        return AlertDialog(
          title: Text(existing == null ? l.newMedicine : l.editMedicine),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: name, autofocus: true, decoration: InputDecoration(labelText: l.brandName)),
              const SizedBox(height: 8),
              TextField(controller: generic, decoration: InputDecoration(labelText: l.genericName)),
              const SizedBox(height: 8),
              TextField(controller: company, decoration: InputDecoration(labelText: l.company)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: units.contains(unit) ? unit : 'pcs',
                decoration: InputDecoration(labelText: l.baseUnit),
                items: [for (final u in units) DropdownMenuItem(value: u, child: Text(l.unit(u)))],
                onChanged: (v) => setS(() => unit = v ?? 'pcs'),
              ),
              const SizedBox(height: 8),
              MoneyField(controller: price, label: l.sellPricePer(u)),
              const SizedBox(height: 16),
              Align(alignment: Alignment.centerLeft, child: Text(l.packSizes, style: Theme.of(ctx).textTheme.titleSmall)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: IntField(controller: strip, label: l.perStrip(u))),
                const SizedBox(width: 8),
                Expanded(child: IntField(controller: box, label: l.perBox(u))),
              ]),
              Align(alignment: Alignment.centerLeft, child: Text(l.packHint, style: Theme.of(ctx).textTheme.bodySmall)),
              const SizedBox(height: 16),
              IntField(controller: reorder, label: l.lowStockAt(u)),
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text(l.lowStockAtHint, style: Theme.of(ctx).textTheme.bodySmall)),
              const SizedBox(height: 8),
              TextField(controller: barcode, decoration: InputDecoration(labelText: l.barcode)),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.save)),
          ],
        );
      },
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
      stripSize: _intOr0(strip.text),
      boxSize: _intOr0(box.text),
      reorderLevel: _intOr0(reorder.text),
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
    stripSize: _intOr0(strip.text),
    boxSize: _intOr0(box.text),
    reorderLevel: _intOr0(reorder.text),
  );
  await repo.update(m);
  return m;
}

/// Adds a batch. Quantity and buying price can be entered per box / strip;
/// they are converted to the base unit, which is how stock is counted.
Future<bool> showBatchForm(BuildContext context, Medicine m) async {
  final l = context.l10n;
  final batchNo = TextEditingController();
  final qty = TextEditingController();
  final buy = TextEditingController();
  final sell = TextEditingController(text: m.sellPrice > 0 ? Money.toInput(m.sellPrice) : '');
  final packs = m.packUnits;
  var pack = packs.last; // usually bought by the biggest pack
  DateTime? expiry;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) {
        final p = l.packName(m, pack);
        return AlertDialog(
          title: Text(l.addStockTitle(m.name)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: batchNo, decoration: InputDecoration(labelText: l.batchNo)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.event),
                label: Text(expiry == null ? l.expiryRequired : l.expiryOn(displayDateFmt.format(expiry!))),
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
              if (packs.length > 1) ...[
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerLeft, child: Text(l.buyingIn)),
                const SizedBox(height: 4),
                SegmentedButton<PackUnit>(
                  segments: [
                    for (final pu in packs)
                      ButtonSegment(
                          value: pu,
                          label: Text(pu.name == null ? l.packName(m, pu) : '${l.packName(m, pu)} (${pu.factor})')),
                  ],
                  selected: {pack},
                  onSelectionChanged: (v) => setS(() => pack = v.first),
                ),
              ],
              const SizedBox(height: 8),
              IntField(controller: qty, label: l.quantityIn(p)),
              const SizedBox(height: 8),
              MoneyField(controller: buy, label: l.buyPricePer(p)),
              const SizedBox(height: 8),
              MoneyField(controller: sell, label: l.sellPricePerReq(l.unit(m.unit))),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
            FilledButton(
              onPressed: () {
                if (expiry == null || (int.tryParse(qty.text) ?? 0) <= 0 || Money.parse(sell.text) <= 0) {
                  showSnack(ctx, l.batchRequired, error: true);
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: Text(l.save),
            ),
          ],
        );
      },
    ),
  );
  if (ok != true) return false;
  await MedicineRepo().addBatch(
    medicineId: m.id,
    batchNo: batchNo.text,
    expiry: expiry!,
    qty: int.parse(qty.text) * pack.factor,
    buyPrice: (Money.parse(buy.text) / pack.factor).round(),
    sellPrice: Money.parse(sell.text),
  );
  return true;
}
