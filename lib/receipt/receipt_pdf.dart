import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/ids.dart';
import '../core/money.dart';
import '../data/shop_settings.dart';
import '../models/models.dart';
import 'receipt_thermal.dart' show qtyLabel, receiptSafe;

/// Receipt as a roll-shaped PDF (58/80mm wide), for WhatsApp/email or Android printing.
/// Uses the built-in PDF font, which has no Bangla or ৳, so text goes through [receiptSafe].
Future<Uint8List> buildReceiptPdf(Receipt r, ShopSettings shop) {
  final s = r.sale;
  final format = (shop.paperWidth == 80 ? PdfPageFormat.roll80 : PdfPageFormat.roll57)
      .copyWith(marginLeft: 3 * PdfPageFormat.mm, marginRight: 3 * PdfPageFormat.mm);
  const small = pw.TextStyle(fontSize: 8);
  final bold = pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold);
  pw.Widget t(String text, {pw.TextStyle style = small, pw.TextAlign? align}) =>
      pw.Text(receiptSafe(text), style: style, textAlign: align);
  pw.Widget row(String l, String rt, {pw.TextStyle style = small}) =>
      pw.Row(children: [pw.Expanded(child: t(l, style: style)), t(rt, style: style)]);
  final divider = pw.Divider(thickness: 0.5, height: 8, borderStyle: pw.BorderStyle.dashed);

  final doc = pw.Document(title: 'Invoice ${s.invoiceNo}');
  doc.addPage(pw.Page(
    pageFormat: format,
    build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
      t(shop.displayName, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold), align: pw.TextAlign.center),
      if (shop.address.isNotEmpty) t(shop.address, align: pw.TextAlign.center),
      if (shop.phone.isNotEmpty) t('Phone: ${shop.phone}', align: pw.TextAlign.center),
      if (shop.license.isNotEmpty) t('DL No: ${shop.license}', align: pw.TextAlign.center),
      divider,
      t('Invoice: ${s.invoiceNo}'),
      t('Date: ${displayDateTimeFmt.format(r.soldAt)}'),
      if (s.customerName != null)
        t('Customer: ${s.customerName}${r.customerPhone != null ? ' (${r.customerPhone})' : ''}'),
      divider,
      for (final i in r.items) ...[
        t(i.name),
        row('   ${qtyLabel(i)} x ${Money.plain(i.unitPrice)}', Money.plain(i.lineTotal)),
        if (i.returnedQty > 0) t('   (returned ${i.returnedQty})'),
      ],
      divider,
      if (s.discount > 0) ...[
        row('Subtotal', Money.plain(r.subtotal)),
        row('Discount', '-${Money.plain(s.discount)}'),
      ],
      row('TOTAL (Tk)', Money.plain(s.total), style: bold),
      row('Paid', Money.plain(s.paid)),
      if (s.returned > 0) row('Returned', '-${Money.plain(s.returned)}'),
      if (s.due > 0) row('Due (baki)', Money.plain(s.due), style: bold),
      divider,
      t(shop.footer.isEmpty ? 'Thank you. Get well soon!' : shop.footer, align: pw.TextAlign.center),
    ]),
  ));
  return doc.save();
}
