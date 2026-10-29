import '../core/db.dart';

/// Shop details printed on receipts, plus this device's receipt printer.
/// Stored in app_meta, so they stay on the device and are not synced.
class ShopSettings {
  ShopSettings({
    this.name = '',
    this.address = '',
    this.phone = '',
    this.license = '',
    this.footer = '',
    this.paperWidth = 58,
    this.printerAddress,
    this.printerName,
  });

  final String name;
  final String address;
  final String phone;
  final String license; // drug license no.
  final String footer;
  final int paperWidth; // mm: 58 or 80
  final String? printerAddress; // Bluetooth MAC of a paired printer
  final String? printerName;

  bool get hasPrinter => printerAddress != null && printerAddress!.isNotEmpty;
  String get displayName => name.trim().isEmpty ? 'Pharmacy' : name.trim();

  /// Characters per line in the printer's default font.
  int get lineChars => paperWidth == 80 ? 48 : 32;

  ShopSettings withPrinter(String? address, String? name) => ShopSettings(
        name: this.name,
        address: this.address,
        phone: phone,
        license: license,
        footer: footer,
        paperWidth: paperWidth,
        printerAddress: address,
        printerName: name,
      );
}

class ShopSettingsRepo {
  ShopSettingsRepo([AppDatabase? db]) : _db = db ?? AppDatabase.instance;
  final AppDatabase _db;

  /// Keys that describe the shop and are carried in backups.
  /// The printer is per-device, so it is not included.
  static const shopKeys = ['shop_name', 'shop_address', 'shop_phone', 'shop_license', 'receipt_footer', 'receipt_paper'];

  Future<ShopSettings> load() async {
    Future<String> s(String k) async => await _db.meta(k) ?? '';
    final printer = await _db.meta('printer_address');
    return ShopSettings(
      name: await s('shop_name'),
      address: await s('shop_address'),
      phone: await s('shop_phone'),
      license: await s('shop_license'),
      footer: await s('receipt_footer'),
      paperWidth: int.tryParse(await s('receipt_paper')) ?? 58,
      printerAddress: (printer == null || printer.isEmpty) ? null : printer,
      printerName: await _db.meta('printer_name'),
    );
  }

  Future<void> save(ShopSettings s) async {
    await _db.db.transaction((txn) async {
      final values = {
        'shop_name': s.name.trim(),
        'shop_address': s.address.trim(),
        'shop_phone': s.phone.trim(),
        'shop_license': s.license.trim(),
        'receipt_footer': s.footer.trim(),
        'receipt_paper': '${s.paperWidth}',
        'printer_address': s.printerAddress ?? '',
        'printer_name': s.printerName ?? '',
      };
      for (final e in values.entries) {
        await _db.setMeta(e.key, e.value, txn: txn);
      }
    });
  }
}
