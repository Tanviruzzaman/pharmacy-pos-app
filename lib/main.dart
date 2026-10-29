import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_locale.dart';
import 'core/db.dart';
import 'data/pin_service.dart';
import 'l10n/l10n.dart';
import 'screens/home_screen.dart';
import 'screens/language_screen.dart';
import 'screens/pin_screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.open();
  await loadLocale();
  final locked = await PinService().isSet();
  runApp(PharmacyApp(firstRun: appLocale.value == null, startLocked: locked));
}

class PharmacyApp extends StatelessWidget {
  const PharmacyApp({super.key, required this.firstRun, required this.startLocked});
  final bool firstRun;
  final bool startLocked;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: appLocale,
      builder: (_, locale, __) => MaterialApp(
        onGenerateTitle: (ctx) => ctx.l10n.appTitle,
        debugShowCheckedModeBanner: false,
        locale: locale ?? const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF0F8A5F),
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder(), isDense: true),
        ),
        builder: (_, child) => AppLock(startLocked: startLocked, child: child!),
        home: firstRun ? const LanguageScreen() : const HomeScreen(),
      ),
    );
  }
}
