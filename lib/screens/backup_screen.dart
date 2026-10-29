import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/ids.dart';
import '../data/backup_service.dart';
import '../data/sync_outbox.dart';
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
    setState(() => _busy = true);
    try {
      await BackupService().exportAndShare();
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, 'Backup failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore backup?'),
        content: const Text('All data on this phone will be REPLACED by the backup file. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Choose file')),
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
      if (mounted) showSnack(context, 'Restored $n records');
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, 'Restore failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & restore')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text(
          'All data is stored only on this phone. Back up regularly: tap "Backup now" and choose Google Drive '
          '(or WhatsApp / email) in the share menu.',
        ),
        const SizedBox(height: 16),
        Text(_last == null ? 'Never backed up' : 'Last backup: ${displayDateTimeFmt.format(_last!)}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('$_pending records changed since install / last cloud sync'),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _busy ? null : _export,
          icon: const Icon(Icons.cloud_upload_outlined),
          label: const Text('Backup now'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _busy ? null : _restore,
          icon: const Icon(Icons.settings_backup_restore),
          label: const Text('Restore from file'),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
      ]),
    );
  }
}
