import 'package:flutter/material.dart';

import '../core/ids.dart';
import '../core/money.dart';
import '../data/medicine_repo.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class ExpiryScreen extends StatefulWidget {
  const ExpiryScreen({super.key});

  @override
  State<ExpiryScreen> createState() => _ExpiryScreenState();
}

class _ExpiryScreenState extends State<ExpiryScreen> {
  int _days = 90;
  List<StockBatch> _list = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await MedicineRepo().expiring(withinDays: _days);
    if (mounted) setState(() => _list = r);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final today = DateTime.now();
    final cs = Theme.of(context).colorScheme;
    final lossValue = _list.fold<int>(0, (s, b) => s + b.qty * b.buyPrice);
    return Scaffold(
      appBar: AppBar(title: Text(l.expiryAlert)),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 30, label: Text(l.days('30'))),
              ButtonSegment(value: 60, label: Text(l.days('60'))),
              ButtonSegment(value: 90, label: Text(l.days('90'))),
              ButtonSegment(value: 180, label: Text(l.sixMonths)),
            ],
            selected: {_days},
            onSelectionChanged: (s) {
              setState(() => _days = s.first);
              _load();
            },
          ),
        ),
        if (_list.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StatRow(l.atRiskValue, Money.format(lossValue), bold: true, color: cs.error),
          ),
        Expanded(
          child: _list.isEmpty
              ? EmptyState(icon: Icons.verified_outlined, text: l.nothingExpiring)
              : ListView.separated(
                  itemCount: _list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final b = _list[i];
                    final d = b.daysToExpiry(today);
                    final label = d < 0 ? l.expiredAgo('${-d}') : d == 0 ? l.expiresToday : l.inDays('$d');
                    return ListTile(
                      leading: Icon(d < 0 ? Icons.dangerous_outlined : Icons.warning_amber_rounded,
                          color: d < 30 ? cs.error : Colors.orange),
                      title: Text(b.medicineName ?? ''),
                      subtitle: Text([
                        l.stockLabel('${b.qty}'),
                        if (b.batchNo != null) l.batchTitle(b.batchNo!),
                        l.expShort(displayDateFmt.format(b.expiry)),
                      ].join(' · ')),
                      trailing: Text(label,
                          style: TextStyle(color: d < 30 ? cs.error : Colors.orange, fontWeight: FontWeight.bold)),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
