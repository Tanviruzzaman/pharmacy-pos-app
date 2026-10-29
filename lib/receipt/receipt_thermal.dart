import 'dart:convert';

import '../core/ids.dart';
import '../core/money.dart';
import '../data/shop_settings.dart';
import '../models/models.dart';

/// Minimal ESC/POS command builder: enough for text receipts on 58/80mm printers.
class EscPos {
  EscPos() {
    _bytes.addAll([0x1B, 0x40]); // initialize
  }

  final _bytes = <int>[];
  List<int> get bytes => List.unmodifiable(_bytes);

  static const left = 0, center = 1;

  void align(int a) => _bytes.addAll([0x1B, 0x61, a]);
  void bold(bool on) => _bytes.addAll([0x1B, 0x45, on ? 1 : 0]);
  void tall(bool on) => _bytes.addAll([0x1D, 0x21, on ? 0x01 : 0x00]); // double height, same width
  void line(String s) {
    _bytes.addAll(ascii.encode(receiptSafe(s)));
    _bytes.add(0x0A);
  }

  void feed(int lines) => _bytes.addAll([0x1B, 0x64, lines]);
  void cut() => _bytes.addAll([0x1D, 0x56, 0x42, 0x00]); // feed and partial cut; ignored by printers without a cutter
}

/// Printers' built-in fonts are ASCII only, so anything else (e.g. Bangla) becomes '?'.
String receiptSafe(String s) => String.fromCharCodes(s.runes.map((r) => r < 0x20 || r > 0x7E ? 0x3F : r));

/// Splits [s] into chunks of at most [width] characters, breaking on spaces where possible.
List<String> wrap(String s, int width) {
  final out = <String>[];
  var rest = s.trim();
  while (rest.length > width) {
    var cut = rest.lastIndexOf(' ', width);
    if (cut <= 0) cut = width;
    out.add(rest.substring(0, cut).trimRight());
    rest = rest.substring(cut).trimLeft();
  }
  if (rest.isNotEmpty) out.add(rest);
  return out;
}

/// [left] and [right] on one line, padded to [width].
String leftRight(String left, String right, int width) {
  final space = width - right.length;
  if (space <= 1) return '$left $right';
  final l = left.length >= space ? left.substring(0, space - 1) : left;
  return l.padRight(space) + right;
}

/// "3" for the base unit, "2 strip" / "1 box" for packs. Receipts are always English.
String qtyLabel(ReceiptLine i) => i.soldUnit == null ? '${i.qty}' : '${i.qty} ${i.soldUnit}';

List<int> buildThermalReceipt(Receipt r, ShopSettings shop) {
  final w = shop.lineChars;
  final dash = '-' * w;
  final s = r.sale;
  final p = EscPos();

  p.align(EscPos.center);
  p.bold(true);
  p.tall(true);
  for (final l in wrap(shop.displayName, w)) {
    p.line(l);
  }
  p.tall(false);
  p.bold(false);
  for (final l in wrap(shop.address, w)) {
    p.line(l);
  }
  if (shop.phone.isNotEmpty) p.line('Phone: ${shop.phone}');
  if (shop.license.isNotEmpty) p.line('DL No: ${shop.license}');

  p.align(EscPos.left);
  p.line(dash);
  p.line('Invoice: ${s.invoiceNo}');
  p.line('Date: ${displayDateTimeFmt.format(r.soldAt)}');
  if (s.customerName != null) {
    p.line('Customer: ${s.customerName}${r.customerPhone != null ? ' (${r.customerPhone})' : ''}');
  }
  p.line(dash);

  for (final i in r.items) {
    for (final l in wrap(i.name, w)) {
      p.line(l);
    }
    p.line(leftRight('  ${qtyLabel(i)} x ${Money.plain(i.unitPrice)}', Money.plain(i.lineTotal), w));
    if (i.returnedQty > 0) p.line('  (returned ${i.returnedQty})');
  }
  p.line(dash);

  if (s.discount > 0) {
    p.line(leftRight('Subtotal', Money.plain(r.subtotal), w));
    p.line(leftRight('Discount', '-${Money.plain(s.discount)}', w));
  }
  p.bold(true);
  p.line(leftRight('TOTAL (Tk)', Money.plain(s.total), w));
  p.bold(false);
  p.line(leftRight('Paid', Money.plain(s.paid), w));
  if (s.returned > 0) p.line(leftRight('Returned', '-${Money.plain(s.returned)}', w));
  if (s.due > 0) {
    p.bold(true);
    p.line(leftRight('Due (baki)', Money.plain(s.due), w));
    p.bold(false);
  }
  p.line(dash);

  p.align(EscPos.center);
  for (final l in wrap(shop.footer.isEmpty ? 'Thank you. Get well soon!' : shop.footer, w)) {
    p.line(l);
  }
  p.feed(3);
  p.cut();
  return p.bytes;
}

/// A short test page to check the printer and paper width.
List<int> buildTestPage(ShopSettings shop) {
  final w = shop.lineChars;
  final p = EscPos();
  p.align(EscPos.center);
  p.bold(true);
  p.line(shop.displayName);
  p.bold(false);
  p.line('Printer test - ${shop.paperWidth}mm');
  p.align(EscPos.left);
  p.line('-' * w);
  p.line(leftRight('Left', 'Right', w));
  p.line('-' * w);
  p.feed(3);
  p.cut();
  return p.bytes;
}
