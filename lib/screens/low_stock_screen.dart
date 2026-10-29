import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../core/ids.dart';
import '../data/medicine_repo.dart';
import '../data/shop_settings.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../widgets/common.dart';

/// Medicines at or below their low-stock level, i.e. what to order next.
class LowStockScreen extends StatefulWidget {
  const LowStockScreen({super.key});

  @override
  State<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends State<LowStockScreen> {
  List<Medicine>? _list;

  @override
  void initState() {
    super.initState();
    MedicineRepo().lowStock().then((r) {
      if (mounted) setState(() => _list = r);
    });
  }

  /// Plain-text list to send to a supplier on WhatsApp / SMS.
  Future<void> _share() async {
    final l = context.l10n;
    final shop = await ShopSettingsRepo().load();
    final lines = [
      '${l.orderListTitle} - ${shop.displayName} - ${displayDateFmt.format(DateTime.now())}',
      '',
      for (final m in _list!)
        '• ${m.name}${m.company != null ? ' (${m.company})' : ''}: ${l.lowStockLine(l.qty(m, m.stockQty), '${m.reorderLevel}')}',
    ];
    await Share.share(lines.join('\n'), subject: l.orderListTitle);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final list = _list;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.lowStock), actions: [
        if (list != null && list.isNotEmpty)
          IconButton(tooltip: l.shareOrderList, icon: const Icon(Icons.share), onPressed: _share),
      ]),
      body: list == null
          ? const Center(child: CircularProgressIndicator())
          : list.isEmpty
              ? EmptyState(icon: Icons.inventory_outlined, text: l.lowStockEmpty)
              : ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final m = list[i];
                    return ListTile(
                      leading: Icon(m.stockQty == 0 ? Icons.remove_shopping_cart_outlined : Icons.trending_down,
                          color: cs.error),
                      title: Text(m.name),
                      subtitle: Text(l.lowStockLine(l.qty(m, m.stockQty), '${m.reorderLevel} ${l.unit(m.unit)}')),
                      trailing: m.company == null ? null : Text(m.company!),
                    );
                  },
                ),
    );
  }
}
