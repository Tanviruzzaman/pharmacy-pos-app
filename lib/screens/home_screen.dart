import 'package:flutter/material.dart';

import '../core/money.dart';
import '../data/customer_repo.dart';
import '../data/medicine_repo.dart';
import '../data/report_repo.dart';
import 'backup_screen.dart';
import 'customers_screen.dart';
import 'expiry_screen.dart';
import 'report_screen.dart';
import 'sale_screen.dart';
import 'stock_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _todaySales = 0;
  int _todayProfit = 0;
  int _expiring = 0;
  int _outstanding = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final r = await ReportRepo().daily(DateTime.now());
    final exp = await MedicineRepo().expiringCount();
    final out = await CustomerRepo().totalOutstanding();
    if (!mounted) return;
    setState(() {
      _todaySales = r.totalSales;
      _todayProfit = r.profit;
      _expiring = exp;
      _outstanding = out;
    });
  }

  Future<void> _go(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacy POS'),
        actions: [
          IconButton(
              tooltip: 'Backup', icon: const Icon(Icons.cloud_upload_outlined), onPressed: () => _go(const BackupScreen())),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Card(
            color: cs.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(child: _Metric('Today\'s sales', Money.format(_todaySales))),
                Expanded(child: _Metric('Today\'s profit', Money.format(_todayProfit))),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: FilledButton.icon(
              onPressed: () => _go(const SaleScreen()),
              icon: const Icon(Icons.point_of_sale, size: 28),
              label: const Text('New Sale', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _Tile(Icons.inventory_2_outlined, 'Stock', null, () => _go(const StockScreen())),
              _Tile(Icons.warning_amber_rounded, 'Expiry alert', _expiring > 0 ? '$_expiring batches' : 'All good',
                  () => _go(const ExpiryScreen()),
                  highlight: _expiring > 0),
              _Tile(Icons.menu_book_outlined, 'Baki khata', _outstanding > 0 ? Money.format(_outstanding) : null,
                  () => _go(const CustomersScreen())),
              _Tile(Icons.bar_chart, 'Daily report', null, () => _go(const ReportScreen())),
            ],
          ),
        ]),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
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
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            if (subtitle != null) Text(subtitle!, style: TextStyle(color: highlight ? cs.error : cs.outline)),
          ]),
        ),
      ),
    );
  }
}
