import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../data/sale_repo.dart';
import '../data/shop_settings.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../receipt/receipt_pdf.dart';
import '../receipt/receipt_thermal.dart';
import '../receipt/thermal_printer.dart';
import '../widgets/common.dart';

Future<(Receipt, ShopSettings)> _load(String saleId) async {
  final r = await SaleRepo().receipt(saleId);
  if (r == null) throw PrinterException(PrinterError.saleNotFound);
  return (r, await ShopSettingsRepo().load());
}

/// Prints on the Bluetooth printer set in Settings, or opens Android's
/// print dialog (Wi-Fi printers, Save as PDF) when none is set.
Future<void> printReceipt(BuildContext context, String saleId) async {
  final l = context.l10n;
  try {
    final (r, shop) = await _load(saleId);
    if (shop.hasPrinter) {
      await ThermalPrinter.printBytes(shop.printerAddress!, buildThermalReceipt(r, shop));
      if (context.mounted) showSnack(context, l.receiptPrinted);
    } else {
      try {
        await Printing.layoutPdf(name: 'Invoice ${r.sale.invoiceNo}', onLayout: (_) => buildReceiptPdf(r, shop));
      } on PlatformException {
        // Some devices and emulators ship without Android's print service.
        if (context.mounted) showSnack(context, l.noPrinterSharing);
        await _share(r, shop);
      }
    }
  } catch (e) {
    if (context.mounted) showSnack(context, l.couldNotPrint(_short(l, e)), error: true);
  }
}

/// Opens the share sheet with the receipt as a PDF (WhatsApp, Messenger, email...).
Future<void> shareReceipt(BuildContext context, String saleId) async {
  final l = context.l10n;
  try {
    final (r, shop) = await _load(saleId);
    await _share(r, shop);
  } catch (e) {
    if (context.mounted) showSnack(context, l.couldNotShare(_short(l, e)), error: true);
  }
}

Future<void> _share(Receipt r, ShopSettings shop) async =>
    Printing.sharePdf(bytes: await buildReceiptPdf(r, shop), filename: 'Invoice-${r.sale.invoiceNo}.pdf');

String _short(AppLocalizations l, Object e) => switch (e) {
      PrinterException() => l.printerError(e),
      PlatformException(:final message) => message ?? e.code,
      _ => '$e',
    };

class ReceiptButtons extends StatelessWidget {
  const ReceiptButtons({super.key, required this.saleId});
  final String saleId;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Row(children: [
      Expanded(
        child: FilledButton.tonalIcon(
            onPressed: () => printReceipt(context, saleId), icon: const Icon(Icons.print), label: Text(l.print)),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: OutlinedButton.icon(
            onPressed: () => shareReceipt(context, saleId), icon: const Icon(Icons.share), label: Text(l.share)),
      ),
    ]);
  }
}
