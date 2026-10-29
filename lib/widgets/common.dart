import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void showSnack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: error ? Theme.of(context).colorScheme.error : null,
  ));
}

/// Text field for Taka amounts (allows digits and one decimal point).
class MoneyField extends StatelessWidget {
  const MoneyField({super.key, required this.controller, required this.label, this.onChanged, this.autofocus = false});

  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        autofocus: autofocus,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
        decoration: InputDecoration(labelText: label, prefixText: '৳ '),
        onChanged: onChanged,
      );
}

class IntField extends StatelessWidget {
  const IntField({super.key, required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(labelText: label),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          ]),
        ),
      );
}

class StatRow extends StatelessWidget {
  const StatRow(this.label, this.value, {super.key, this.bold = false, this.color});
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 17 : 15, color: color);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [Expanded(child: Text(label, style: style)), Text(value, style: style)]),
    );
  }
}
