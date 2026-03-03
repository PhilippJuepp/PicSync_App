import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:picsync_app/gen_l10n/app_localizations.dart';
import 'album_picker_page.dart';
import 'gallery_scanner.dart';
import 'upload_queue.dart';
import 'upload_worker.dart';
import '../../core/widgets/app_bar.dart';
import '../../data/database/database_provider.dart';
import '../../core/services/api_client.dart';
import '../../core/services/background_upload_service.dart';
import '../auth/login_screen.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  List<AssetPathEntity> selectedAlbums = [];
  List<AssetEntity> foundAssets = [];
  double scanProgress = 0;
  double uploadProgress = 0;
  bool isScanning = false;
  bool isUploading = false;
  int uploaded = 0;
  String? errorText;
  DateTime? lastScanAt;
  DateTime? lastBackupAt;

  Future<void> _selectAlbums() async {
    final result = await Navigator.push<List<AssetPathEntity>>(
      context,
      MaterialPageRoute(
        builder: (_) => AlbumPickerPage(
          initiallySelected: selectedAlbums,
        ),
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      selectedAlbums = result;
      errorText = null;
    });
  }

  Future<void> _scanAlbums() async {
    setState(() {
      isScanning = true;
      scanProgress = 0;
      foundAssets = [];
      errorText = null;
    });

    try {
      final assets = await GalleryScanner.scanAlbums(
        selectedAlbums,
        onProgress: (p) {
          if (!mounted) return;
          setState(() => scanProgress = p);
        },
      );

      if (!mounted) return;
      setState(() {
        foundAssets = assets;
        isScanning = false;
        lastScanAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isScanning = false;
        errorText = 'Scan fehlgeschlagen: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorText!)),
      );
    }
  }

  Future<void> _startBackup() async {
    setState(() {
      isUploading = true;
      uploaded = 0;
      uploadProgress = 0;
      errorText = null;
    });

    await BackgroundUploadService.start();

    try {
      final db = DatabaseProvider.instance;
      final queue = await UploadQueue.fromAssets(foundAssets, db);
      final worker = UploadWorker(queue, db);
      await worker.start(onProgress: (u, total) {
        if (!mounted) return;
        setState(() {
          uploaded = u;
          uploadProgress = total == 0 ? 0 : (u / total);
        });
      });

      if (!mounted) return;
      setState(() {
        isUploading = false;
        lastBackupAt = DateTime.now();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup abgeschlossen.')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        isUploading = false;
        errorText = 'Session abgelaufen. Bitte erneut anmelden.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anmeldung abgelaufen. Bitte neu einloggen.'),
        ),
      );
      await _showReLoginDialog(e);
    } catch (e) {
      if (!mounted) return;
      final description = _errorDescription(e);
      setState(() {
        isUploading = false;
        errorText = 'Upload fehlgeschlagen: $description';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorText!),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      await BackgroundUploadService.stop();
    }
  }

  String _errorDescription(dynamic error) {
    final msg = error.toString();
    if (msg.contains('software caused connection abort')) {
      return 'Verbindung unterbrochen beim Finalisieren des Uploads.';
    }
    if (msg.contains('Timeout') || msg.contains('timeout')) {
      return 'Timeout: Upload dauert zu lange.';
    }
    if (msg.contains('Connection')) {
      return 'Verbindungsfehler zum Server.';
    }
    return msg;
  }

  Future<void> _showReLoginDialog(AuthException exception) async {
    if (!mounted) return;

    final reasonText = switch (exception.reason) {
      AuthFailureReason.missingRefreshToken =>
        'Es ist kein Refresh-Token gespeichert.',
      AuthFailureReason.refreshRejected =>
        'Der Server hat den Refresh-Token abgelehnt.',
      AuthFailureReason.unauthorized =>
        'Die Sitzung ist nicht mehr gültig.',
    };

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Neu anmelden erforderlich'),
          content: Text('$reasonText\n\nBitte melde dich erneut an.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Später'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              },
              child: const Text('Jetzt anmelden'),
            ),
          ],
        );
      },
    );
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return 'Noch nicht ausgeführt';
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatShortDate(value);
    final time = localizations.formatTimeOfDay(TimeOfDay.fromDateTime(value));
    return '$date · $time';
  }

  double get _activeProgress {
    if (isUploading) return uploadProgress;
    if (isScanning) return scanProgress;
    return 0;
  }

  String get _activeProgressLabel {
    if (isScanning) {
      return 'Scannen: ${(scanProgress * 100).toStringAsFixed(0)}%';
    }
    if (isUploading) {
      return 'Upload: $uploaded / ${foundAssets.length}';
    }
    if (lastBackupAt != null) {
      return 'Letztes Backup: ${_formatDateTime(lastBackupAt)}';
    }
    return 'Bereit';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: buildAppBar(title: l10n.backup),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.25)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                          child: Icon(Icons.cloud_done_rounded, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Backup-Status',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _activeProgressLabel,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: _activeProgress == 0 ? 0 : _activeProgress,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorText!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    title: 'Alben',
                    value: '${selectedAlbums.length}',
                    subtitle: 'Ausgewählt',
                    icon: Icons.photo_album_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoCard(
                    title: 'Medien',
                    value: '${foundAssets.length}',
                    subtitle: 'Gefunden',
                    icon: Icons.perm_media_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoCard(
                    title: 'Upload',
                    value: '$uploaded',
                    subtitle: 'Hochgeladen',
                    icon: Icons.cloud_upload_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text('1) Alben auswählen', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isScanning || isUploading ? null : _selectAlbums,
                icon: const Icon(Icons.folder_copy_outlined),
                label: Text('Alben auswählen (${selectedAlbums.length})'),
              ),
            ),
            const SizedBox(height: 12),
            if (selectedAlbums.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedAlbums
                    .map(
                      (album) => Chip(
                        avatar: const Icon(Icons.collections_outlined, size: 16),
                        label: Text(album.name),
                      ),
                    )
                    .toList(),
              )
            else
              Text(
                'Noch keine Alben gewählt.',
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: 18),
            Text('2) Medien scannen', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: selectedAlbums.isEmpty || isScanning || isUploading
                    ? null
                    : _scanAlbums,
                icon: Icon(isScanning ? Icons.hourglass_top_rounded : Icons.search_rounded),
                label: Text(isScanning ? 'Scanne...' : 'Scan starten'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Letzter Scan: ${_formatDateTime(lastScanAt)}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            Text('3) Backup hochladen', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: foundAssets.isEmpty || isScanning || isUploading
                    ? null
                    : _startBackup,
                icon: Icon(isUploading ? Icons.sync_rounded : Icons.cloud_upload_rounded),
                label: Text(isUploading ? 'Lädt hoch...' : 'Sicherung starten'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Letztes Backup: ${_formatDateTime(lastBackupAt)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}