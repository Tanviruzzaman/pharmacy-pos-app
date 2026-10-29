import 'package:flutter/material.dart';

import '../data/pin_service.dart';
import '../l10n/l10n.dart';

/// Covers the whole app with the PIN pad when a PIN is set: on start, and when
/// the app comes back after [lockAfter] in the background.
class AppLock extends StatefulWidget {
  const AppLock({super.key, required this.startLocked, required this.child});
  final bool startLocked;
  final Widget child;

  static const lockAfter = Duration(seconds: 30);

  @override
  State<AppLock> createState() => _AppLockState();
}

class _AppLockState extends State<AppLock> with WidgetsBindingObserver {
  late bool _locked = widget.startLocked;
  DateTime? _awaySince;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _awaySince ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final away = _awaySince;
      _awaySince = null;
      if (away != null && DateTime.now().difference(away) >= AppLock.lockAfter && await PinService().isSet()) {
        if (mounted) setState(() => _locked = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
        widget.child,
        if (_locked)
          Positioned.fill(
            child: _LockScreen(onUnlocked: () => setState(() => _locked = false)),
          ),
      ]);
}

class _LockScreen extends StatefulWidget {
  const _LockScreen({required this.onUnlocked});
  final VoidCallback onUnlocked;

  @override
  State<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<_LockScreen> {
  bool _help = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(children: [
            const SizedBox(height: 24),
            Icon(Icons.lock_outline, size: 48, color: Theme.of(context).colorScheme.primary),
            Text(l.appTitle, style: Theme.of(context).textTheme.titleLarge),
            PinPad(
              title: l.enterPin,
              onComplete: (pin) async {
                final ok = await PinService().check(pin);
                if (ok) widget.onUnlocked();
                return ok ? null : l.wrongPin;
              },
            ),
            TextButton(onPressed: () => setState(() => _help = !_help), child: Text(l.forgotPin)),
            if (_help)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                child: Text(l.forgotPinHelp, textAlign: TextAlign.center),
              ),
          ]),
        ),
      ),
    );
  }
}

/// 4 dots and a number pad. [onComplete] gets the PIN and returns an error to show, or null if accepted.
class PinPad extends StatefulWidget {
  const PinPad({super.key, required this.title, required this.onComplete});
  final String title;
  final Future<String?> Function(String pin) onComplete;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';
  String? _error;
  bool _busy = false;

  Future<void> _tap(String d) async {
    if (_busy || _pin.length >= PinService.length) return;
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length == PinService.length) {
      _busy = true;
      final error = await widget.onComplete(_pin);
      _busy = false;
      if (mounted) {
        setState(() {
          _pin = '';
          _error = error;
        });
      }
    }
  }

  void _back() {
    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget key(Widget child, VoidCallback? onTap) => SizedBox(
          width: 80,
          height: 64,
          child: onTap == null
              ? null
              : InkWell(
                  borderRadius: BorderRadius.circular(32),
                  onTap: onTap,
                  child: Center(child: child),
                ),
        );
    Widget digit(String d) => key(Text(d, style: const TextStyle(fontSize: 26)), () => _tap(d));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < PinService.length; i++)
            Container(
              margin: const EdgeInsets.all(8),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < _pin.length ? cs.primary : null,
                border: Border.all(color: _error != null ? cs.error : cs.primary, width: 2),
              ),
            ),
        ]),
        SizedBox(
          height: 24,
          child: _error == null ? null : Text(_error!, style: TextStyle(color: cs.error)),
        ),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(mainAxisSize: MainAxisSize.min, children: [for (final d in row) digit(d)]),
        Row(mainAxisSize: MainAxisSize.min, children: [
          key(const SizedBox(), null),
          digit('0'),
          key(const Icon(Icons.backspace_outlined), _back),
        ]),
      ]),
    );
  }
}

/// Asks for the current PIN. Returns true if it was entered correctly.
Future<bool> verifyPin(BuildContext context) async {
  final ok = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (ctx) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: PinPad(
            title: ctx.l10n.currentPin,
            onComplete: (pin) async {
              final wrong = ctx.l10n.wrongPin;
              if (!await PinService().check(pin)) return wrong;
              if (ctx.mounted) Navigator.pop(ctx, true);
              return null;
            },
          ),
        ),
      ),
    ),
  );
  return ok ?? false;
}

/// Asks for a new PIN twice and saves it. Returns true when set.
Future<bool> setupPin(BuildContext context) async {
  final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const _PinSetupScreen()));
  return ok ?? false;
}

class _PinSetupScreen extends StatefulWidget {
  const _PinSetupScreen();

  @override
  State<_PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<_PinSetupScreen> {
  String? _first;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.setPin)),
      body: Center(
        child: PinPad(
          title: _first == null ? l.newPin : l.confirmPin,
          onComplete: (pin) async {
            if (_first == null) {
              setState(() => _first = pin);
              return null;
            }
            if (pin != _first) {
              setState(() => _first = null);
              return l.pinMismatch;
            }
            await PinService().set(pin);
            if (context.mounted) Navigator.pop(context, true);
            return null;
          },
        ),
      ),
    );
  }
}
