import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class AlbumPickerPage extends StatefulWidget {
  final List<AssetPathEntity> initiallySelected;

  const AlbumPickerPage({
    super.key,
    required this.initiallySelected,
  });

  @override
  State<AlbumPickerPage> createState() => _AlbumPickerPageState();
}

class _AlbumPickerPageState extends State<AlbumPickerPage> {
  List<AssetPathEntity> albums = [];
  List<AssetPathEntity> selected = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    selected = [...widget.initiallySelected];
    loadAlbums();
  }

  Future<void> loadAlbums() async {
    final result = await PhotoManager.requestPermissionExtend();
    if (!result.isAuth) {
      setState(() => isLoading = false);
      return;
    }

    final list = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      hasAll: false,
    );

    setState(() {
      albums = list;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alben auswählen'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, selected),
            child: const Text('Fertig'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
              ),
              child: ListTile(
                leading: const Icon(Icons.photo_album_outlined),
                title: const Text('Album-Auswahl'),
                subtitle: Text('${selected.length} von ${albums.length} ausgewählt'),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      itemCount: albums.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final album = albums[i];
                        final isSelected = selected.contains(album);

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? theme.colorScheme.primary.withValues(alpha: 0.45)
                                  : theme.dividerColor.withValues(alpha: 0.18),
                            ),
                          ),
                          child: CheckboxListTile(
                            value: isSelected,
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  selected.add(album);
                                } else {
                                  selected.remove(album);
                                }
                              });
                            },
                            secondary: const Icon(Icons.collections_outlined),
                            title: Text(album.name),
                            controlAffinity: ListTileControlAffinity.trailing,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}