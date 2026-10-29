import 'package:flutter/material.dart';

import '../core/money.dart';
import '../data/customer_repo.dart';
import '../data/medicine_repo.dart';
import '../data/report_repo.dart';
import '../data/shop_settings.dart';
import '../l10n/l10n.dart';
import 'backup_screen.dart';
import 'customers_screen.dart';
import 'expiry_screen.dart';
import 'low_stock_screen.dart';
import 'report_screen.dart';
import 'sale_screen.dart';
import 'settings_screen.dart';
import 'stock_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _todaySales = 0;
  int _todayProfit = 0;
  int _todayDue = 0;
  int _expiring = 0;
  int _lowStock = 0;
  int _outstanding = 0;
  bool _needsShopSetup = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final r = await ReportRepo().daily(DateTime.now());
    final exp = await MedicineRepo().expiringCount();
    final low = (await MedicineRepo().lowStock()).length;
    final out = await CustomerRepo().totalOutstanding();
    final shop = await ShopSettingsRepo().load();
    if (!mounted) return;
    setState(() {
      _needsShopSetup = shop.name.trim().isEmpty;
      _todaySales = r.netSales;
      _todayProfit = r.profit;
      _todayDue = r.dueGiven;
      _expiring = exp;
      _lowStock = low;
      _outstanding = out;
    });
  }

  Future<void> _go(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final wide = MediaQuery.sizeOf(context).width >= 700;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle),
        actions: [
          IconButton(tooltip: l.settings, icon: const Icon(Icons.settings_outlined), onPressed: () => _go(const SettingsScreen())),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (_needsShopSetup)
            Card(
              child: ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: Text(l.addShopDetails),
                subtitle: Text(l.addShopDetailsHint),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _go(const SettingsScreen()),
              ),
            ),
          Card(
            color: cs.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Row(children: [
                  Expanded(child: _Metric(l.todaySales, Money.format(_todaySales))),
                  Expanded(child: _Metric(l.todayProfit, Money.format(_todayProfit))),
                ]),
                const Divider(height: 24),
                InkWell(
                  onTap: () => _go(const CustomersScreen()),
                  child: Row(children: [
                    Expanded(child: _Metric(l.todayDue, Money.format(_todayDue), warn: _todayDue > 0)),
                    Expanded(child: _Metric(l.totalDue, Money.format(_outstanding), warn: _outstanding > 0)),
                  ]),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: FilledButton.icon(
              onPressed: () => _go(const SaleScreen()),
              icon: const Icon(Icons.point_of_sale, size: 28),
              label: Text(l.newSale, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(height: 12),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            // Fixed height, not an aspect ratio: Bangla text is taller than English.
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: wide ? 3 : 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 128,
            ),
            children: [
              _Tile(Icons.inventory_2_outlined, l.stock, null, () => _go(const StockScreen())),
              _Tile(Icons.warning_amber_rounded, l.expiryAlert, _expiring > 0 ? l.batchesCount('$_expiring') : l.allGood,
                  () => _go(const ExpiryScreen()),
                  highlight: _expiring > 0),
              _Tile(Icons.trending_down, l.lowStock, _lowStock > 0 ? l.medicinesCount('$_lowStock') : l.allGood,
                  () => _go(const LowStockScreen()),
                  highlight: _lowStock > 0),
              _Tile(Icons.menu_book_outlined, l.bakiKhata, _outstanding > 0 ? Money.format(_outstanding) : null,
                  () => _go(const CustomersScreen())),
              _Tile(Icons.bar_chart, l.dailyReport, null, () => _go(const ReportScreen())),
              _Tile(Icons.cloud_upload_outlined, l.backup, null, () => _go(const BackupScreen())),
            ],
          ),
        ]),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, {this.warn = false});
  final String label;
  final String value;
  final bool warn; // due amounts in red

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold, color: warn ? Theme.of(context).colorScheme.error : null)),
      ]);
}

class _Tile extends StatelessWidget {
  const _Tile(this.icon, this.title, this.subtitle, this.onTap, {this.highlight = false});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: highlight ? cs.errorContainer : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 30, color: highlight ? cs.error : cs.primary),
            const SizedBox(height: 8),
            Text(title,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            if (subtitle != null)
              Text(subtitle!,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: highlight ? cs.error : cs.outline)),
          ]),
        ),
      ),
    );
  }
}
