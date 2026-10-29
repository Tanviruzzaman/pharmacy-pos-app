import 'package:intl/intl.dart';

/// All money is stored as integer poisha (1 Taka = 100 poisha) to avoid
/// floating point rounding errors. Convert only at the UI edge.
class Money {
  static final _fmt = NumberFormat('#,##0.00', 'en_US');

  static String format(int poisha) => '৳${_fmt.format(poisha / 100)}';

  /// Without the ৳ sign, for receipts: thermal printers and PDF base fonts can't draw it.
  static String plain(int poisha) => _fmt.format(poisha / 100);

  /// Parses user input like "12.5" or "1,200" into poisha. Returns 0 on bad input.
  static int parse(String input) {
    final cleaned = input.replaceAll(',', '').replaceAll('৳', '').trim();
    final value = double.tryParse(cleaned);
    if (value == null) return 0;
    return (value * 100).round();
  }

  static String toInput(int poisha) {
    if (poisha % 100 == 0) return (poisha ~/ 100).toString();
    return (poisha / 100).toStringAsFixed(2);
  }
}
