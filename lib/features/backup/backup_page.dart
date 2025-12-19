import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'album_picker_page.dart';
import 'gallery_scanner.dart';
import 'upload_queue.dart';
import 'upload_worker.dart';
import '../../core/widgets/app_bar.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  List<AssetPathEntity> selectedAlbums = [];
  List<AssetEntity> foundAssets = [];
  double progress = 0;
  bool isScanning = false;
  bool isUploading = false;
  int uploaded = 0;

  @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: buildAppBar(
          title: "Backup",
          onReload: () {
            // Optional: Neuladen der Alben oder Status
          },
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AlbumPickerPage(
                        initiallySelected: selectedAlbums,
                      ),
                    ),
                  );
                  if (result != null) setState(() => selectedAlbums = result);
                },
                child: Text("Alben auswählen (${selectedAlbums.length})"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: selectedAlbums.isEmpty || isScanning
                    ? null
                    : () async {
                        setState(() {
                          isScanning = true;
                          progress = 0;
                        });
                        final assets = await GalleryScanner.scanAlbums(
                          selectedAlbums,
                          onProgress: (p) => setState(() => progress = p),
                        );
                        setState(() {
                          foundAssets = assets;
                          isScanning = false;
                        });
                      },
                child: Text(isScanning ? "Scanne..." : "Medien suchen"),
              ),
              const SizedBox(height: 12),
              Text("Gefundene Medien: ${foundAssets.length}"),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: foundAssets.isEmpty || isUploading
                    ? null
                    : () async {
                        setState(() {
                          isUploading = true;
                          uploaded = 0;
                          progress = 0;
                        });
                        final queue = await UploadQueue.fromAssets(foundAssets);
                        final worker = UploadWorker(queue);
                        await worker.start(onProgress: (u, total) {
                          setState(() {
                            uploaded = u;
                            progress = u / total;
                          });
                        });
                        setState(() => isUploading = false);
                      },
                child: Text(isUploading ? "Lädt hoch..." : "Sicherung starten"),
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(value: progress == 0 ? null : progress),
              const SizedBox(height: 8),
              if (isUploading)
                Text("Hochgeladen: $uploaded / ${foundAssets.length}")
            ],
        ),
          ),
      );
    }
}