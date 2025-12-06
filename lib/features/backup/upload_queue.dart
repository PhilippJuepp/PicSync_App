import 'package:photo_manager/photo_manager.dart';

class UploadItem {
  final AssetEntity asset;
  final int size;
  String? uploadId;
  int uploaded = 0;

  UploadItem(this.asset, this.size);

  String get mimeType => asset.mimeType ?? "application/octet-stream";
}

class UploadQueue {
  final List<UploadItem> items;

  UploadQueue(this.items);

  static Future<UploadQueue> fromAssets(List<AssetEntity> assets) async {
    final items = <UploadItem>[];

    for (final asset in assets) {
      final file = await asset.file;
      if (file == null) continue;

      items.add(UploadItem(asset, await file.length()));
    }

    return UploadQueue(items);
  }
}