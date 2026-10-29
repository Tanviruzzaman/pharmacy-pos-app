import 'package:flutter/widgets.dart';

import 'db.dart';

/// The language the user picked ('en' or 'bn'); null until chosen on first launch.
final appLocale = ValueNotifier<Locale?>(null);

Future<void> loadLocale() async {
  final code = await AppDatabase.instance.meta('locale');
  appLocale.value = (code == null || code.isEmpty) ? null : Locale(code);
}

Future<void> setLocale(String code) async {
  await AppDatabase.instance.setMeta('locale', code);
  appLocale.value = Locale(code);
}
