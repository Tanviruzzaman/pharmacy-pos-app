import 'package:flutter/material.dart';

import '../core/app_locale.dart';
import 'home_screen.dart';

/// First launch: pick English or Bangla. Shown in both languages on purpose.
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  Future<void> _pick(BuildContext context, String code) async {
    await setLocale(code);
    if (context.mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Icon(Icons.local_pharmacy, size: 64, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text('ভাষা বেছে নিন', textAlign: TextAlign.center, style: text.headlineSmall),
                Text('Choose your language', textAlign: TextAlign.center, style: text.titleMedium),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () => _pick(context, 'bn'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                  child: const Text('বাংলা', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _pick(context, 'en'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                  child: const Text('English', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(height: 16),
                Text('পরে সেটিংস থেকে বদলানো যাবে · You can change this later in Settings',
                    textAlign: TextAlign.center, style: text.bodySmall),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
