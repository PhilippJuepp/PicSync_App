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

  @override
  void initState() {
    super.initState();
    selected = [...widget.initiallySelected];
    loadAlbums();
  }

  Future<void> loadAlbums() async {
    final result = await PhotoManager.requestPermissionExtend();
    if (!result.isAuth) return;

    final list = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      hasAll: false,
    );

    setState(() => albums = list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Alben auswählen"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, selected),
            child: const Text("Fertig", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: albums.length,
        itemBuilder: (_, i) {
          final album = albums[i];
          final isSelected = selected.contains(album);

          return ListTile(
            title: Text(album.name),
            trailing: Checkbox(
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
            ),
          );
        },
      ),
    );
  }
}