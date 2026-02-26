import 'package:photo_manager/photo_manager.dart';
import 'file_hash.dart';
import '../../data/database/app_database.dart';

class UploadItem {
  final AssetEntity asset;
  final int size;
  late final String hash;
  String? uploadId;
  int uploaded = 0;

  UploadItem(this.asset, this.size, this.hash);

  String get mimeType => asset.mimeType ?? "application/octet-stream";
}

class UploadQueue {
  final List<UploadItem> items;

  UploadQueue(this.items);

  static Future<UploadQueue> fromAssets(
    List<AssetEntity> assets,
    AppDatabase db,
  ) async {
    final items = <UploadItem>[];

    for (final asset in assets) {
      final existing = await db.getByLocalId(asset.id);

      if (existing?.status == 'DONE') {
        continue;
      }

      final file = await asset.file;
      if (file == null) continue;

      final hash = await sha256File(file);
      final size = await file.length();

      await db.insertOrIgnore(
        localId: asset.id,
        hash: hash,
        size: size,
      );

      items.add(UploadItem(asset, size, hash));
    }

    return UploadQueue(items);
  }
}