import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/ids.dart';
import '../data/backup_service.dart';
import '../data/sync_outbox.dart';
import '../l10n/l10n.dart';
import '../widgets/common.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  DateTime? _last;
  int _pending = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final l = await BackupService().lastBackupAt();
    final p = await SyncOutbox().pendingCount();
    if (!mounted) return;
    setState(() {
      _last = l;
      _pending = p;
    });
  }

  Future<void> _export() async {
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      await BackupService().exportAndShare();
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, l.backupFailed('$e'), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final l = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.restoreTitle),
        content: Text(l.restoreWarning),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.chooseFile)),
        ],
      ),
    );
    if (confirm != true) return;
    final picked = await FilePicker.platform.pickFiles(type: FileType.any);
    final path = picked?.files.single.path;
    if (path == null) return;
    setState(() => _busy = true);
    try {
      final n = await BackupService().restoreFromFile(File(path));
      if (mounted) showSnack(context, l.restoredCount('$n'));
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, l.restoreFailed('$e'), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.backupRestore)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(l.backupInfo),
        const SizedBox(height: 16),
        Text(_last == null ? l.neverBackedUp : l.lastBackup(displayDateTimeFmt.format(_last!)),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(l.changedRecords('$_pending')),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _busy ? null : _export,
          icon: const Icon(Icons.cloud_upload_outlined),
          label: Text(l.backupNow),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _busy ? null : _restore,
          icon: const Icon(Icons.settings_backup_restore),
          label: Text(l.restoreFromFile),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
      ]),
    );
  }
}
