import 'package:flutter/widgets.dart';

import '../data/sale_repo.dart';
import '../models/models.dart';
import '../receipt/thermal_printer.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension L10nText on AppLocalizations {
  /// Unit keys are stored in English ('tablet', 'strip'...); this shows them in the app language.
  String unit(String? key) => switch (key) {
        'pcs' => unit_pcs,
        'tablet' => unit_tablet,
        'capsule' => unit_capsule,
        'strip' => unit_strip,
        'box' => unit_box,
        'bottle' => unit_bottle,
        'tube' => unit_tube,
        'vial' => unit_vial,
        'sachet' => unit_sachet,
        _ => key ?? '',
      };

  /// Name of a pack unit for [m]: its base unit when [pack] is the base.
  String packName(Medicine m, PackUnit pack) => unit(pack.name ?? m.unit);

  /// "150 capsule (1 box, 5 strip)": base quantity plus the pack breakdown when the medicine has packs.
  String qty(Medicine m, int baseQty) {
    final base = '$baseQty ${unit(m.unit)}';
    final packs = m.packUnits.where((p) => p.name != null).toList().reversed;
    if (packs.isEmpty || baseQty <= 0) return base;
    var rest = baseQty;
    final parts = <String>[];
    for (final p in packs) {
      if (rest >= p.factor) {
        parts.add('${rest ~/ p.factor} ${unit(p.name)}');
        rest %= p.factor;
      }
    }
    if (parts.isEmpty) return base;
    if (rest > 0) parts.add('$rest ${unit(m.unit)}');
    return '$base (${parts.join(', ')})';
  }

  String saleError(SaleException e) => switch (e.code) {
        SaleError.emptyCart => errEmptyCart,
        SaleError.invalidDiscount => errInvalidDiscount,
        SaleError.invalidPaid => errInvalidPaid,
        SaleError.dueNeedsCustomer => errDueNeedsCustomer,
        SaleError.invalidQty => errInvalidQty(e.name ?? ''),
        SaleError.notEnoughStock => errNotEnoughStock(e.name ?? ''),
        SaleError.notFound => errSaleNotFound,
        SaleError.returnTooMuch => errReturnTooMuch,
        SaleError.nothingToReturn => errNothingToReturn,
      };

  String printerError(PrinterException e) => switch (e.code) {
        PrinterError.permission => errBtPermission,
        PrinterError.bluetoothOff => errBtOff,
        PrinterError.connect => errPrinterConnect,
        PrinterError.failed => errPrintFailed,
        PrinterError.saleNotFound => errSaleNotFound,
      };
}
