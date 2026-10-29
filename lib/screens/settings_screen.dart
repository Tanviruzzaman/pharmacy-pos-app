import 'package:flutter/material.dart';

import '../core/app_locale.dart';
import '../data/pin_service.dart';
import '../data/shop_settings.dart';
import '../l10n/l10n.dart';
import '../receipt/receipt_thermal.dart';
import '../receipt/thermal_printer.dart';
import '../widgets/common.dart';
import 'pin_screens.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _license = TextEditingController();
  final _footer = TextEditingController();
  int _paper = 58;
  String? _printerAddress;
  String? _printerName;
  bool _pinSet = false;
  bool _loaded = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await ShopSettingsRepo().load();
    final pin = await PinService().isSet();
    if (!mounted) return;
    setState(() {
      _name.text = s.name;
      _address.text = s.address;
      _phone.text = s.phone;
      _license.text = s.license;
      _footer.text = s.footer;
      _paper = s.paperWidth;
      _printerAddress = s.printerAddress;
      _printerName = s.printerName;
      _pinSet = pin;
      _loaded = true;
    });
  }

  ShopSettings get _current => ShopSettings(
        name: _name.text,
        address: _address.text,
        phone: _phone.text,
        license: _license.text,
        footer: _footer.text,
        paperWidth: _paper,
        printerAddress: _printerAddress,
        printerName: _printerName,
      );

  Future<void> _save() async {
    await ShopSettingsRepo().save(_current);
    if (!mounted) return;
    showSnack(context, context.l10n.saved);
    Navigator.pop(context);
  }

  Future<void> _choosePrinter() async {
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      final devices = await ThermalPrinter.paired();
      if (!mounted) return;
      final picked = await showDialog<Object>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: Text(l.pairedDevices),
          children: [
            if (devices.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(l.noPairedDevices),
              ),
            for (final d in devices)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, d),
                child: ListTile(
                    leading: const Icon(Icons.print), title: Text(d.name), subtitle: Text(d.macAdress), dense: true),
              ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'none'),
              child: ListTile(leading: const Icon(Icons.print_disabled), title: Text(l.noBtPrinter), dense: true),
            ),
          ],
        ),
      );
      if (picked == null || !mounted) return;
      setState(() {
        if (picked is BluetoothInfo) {
          _printerAddress = picked.macAdress;
          _printerName = picked.name;
        } else {
          _printerAddress = null;
          _printerName = null;
        }
      });
    } on PrinterException catch (e) {
      if (mounted) showSnack(context, l.printerError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _testPrint() async {
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      await ThermalPrinter.printBytes(_printerAddress!, buildTestPage(_current));
      if (mounted) showSnack(context, l.testSent);
    } on PrinterException catch (e) {
      if (mounted) showSnack(context, l.printerError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pinAction(String action) async {
    final l = context.l10n;
    if (action != 'set' && !await verifyPin(context)) return;
    if (!mounted) return;
    if (action == 'remove') {
      await PinService().clear();
      if (mounted) showSnack(context, l.pinRemoved);
    } else if (await setupPin(context)) {
      if (mounted) showSnack(context, l.pinSet);
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    Widget section(String title) => Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Text(title, style: text.titleMedium),
        );
    return Scaffold(
      appBar: AppBar(title: Text(l.settings), actions: [
        TextButton(onPressed: _loaded ? _save : null, child: Text(l.save)),
      ]),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 32), children: [
              section(l.language),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'bn', label: Text('বাংলা')),
                  ButtonSegment(value: 'en', label: Text('English')),
                ],
                selected: {Localizations.localeOf(context).languageCode},
                onSelectionChanged: (v) => setLocale(v.first),
              ),
              section(l.shopAndReceipt),
              Text(l.printedOnReceipt, style: text.bodySmall),
              const SizedBox(height: 12),
              TextField(controller: _name, decoration: InputDecoration(labelText: l.shopName)),
              const SizedBox(height: 12),
              TextField(controller: _address, decoration: InputDecoration(labelText: l.address), maxLines: 2),
              const SizedBox(height: 12),
              TextField(
                  controller: _phone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: l.phone)),
              const SizedBox(height: 12),
              TextField(controller: _license, decoration: InputDecoration(labelText: l.license)),
              const SizedBox(height: 12),
              TextField(
                  controller: _footer,
                  decoration: InputDecoration(labelText: l.receiptFooter, hintText: 'Thank you. Get well soon!')),
              const SizedBox(height: 8),
              Text(l.englishOnlyNote, style: text.bodySmall),
              section(l.receiptPrinter),
              SegmentedButton<int>(
                segments: [
                  ButtonSegment(value: 58, label: Text(l.paperMm('58'))),
                  ButtonSegment(value: 80, label: Text(l.paperMm('80'))),
                ],
                selected: {_paper},
                onSelectionChanged: (v) => setState(() => _paper = v.first),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: Icon(_printerAddress == null ? Icons.print_disabled : Icons.print),
                  title: Text(_printerAddress == null ? l.noBtPrinter : (_printerName ?? '')),
                  subtitle: Text(_printerAddress ?? l.usesAndroidPrint),
                  trailing: _busy
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.chevron_right),
                  onTap: _busy ? null : _choosePrinter,
                ),
              ),
              if (_printerAddress != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                      onPressed: _busy ? null : _testPrint, icon: const Icon(Icons.receipt), label: Text(l.testPrint)),
                ),
              section(l.security),
              Card(
                child: Column(children: [
                  ListTile(
                    leading: Icon(_pinSet ? Icons.lock : Icons.lock_open),
                    title: Text(l.pinLock),
                    subtitle: Text(_pinSet ? l.pinOn : l.pinOff),
                  ),
                  OverflowBar(alignment: MainAxisAlignment.end, children: [
                    if (_pinSet) TextButton(onPressed: () => _pinAction('remove'), child: Text(l.removePin)),
                    FilledButton.tonal(
                      onPressed: () => _pinAction(_pinSet ? 'change' : 'set'),
                      child: Text(_pinSet ? l.changePin : l.setPin),
                    ),
                    const SizedBox(width: 8),
                  ]),
                  const SizedBox(height: 8),
                ]),
              ),
            ]),
    );
  }
}
