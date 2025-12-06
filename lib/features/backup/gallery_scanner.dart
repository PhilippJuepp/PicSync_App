import 'package:photo_manager/photo_manager.dart';

class GalleryScanner {
  static Future<List<AssetEntity>> scanAlbums(
    List<AssetPathEntity> albums, {
    required Function(double) onProgress,
  }) async {
    List<AssetEntity> all = [];

    int total = 0;
    for (final a in albums) {
      total += await a.assetCountAsync;
    }

    int processed = 0;

    for (final album in albums) {
      final assets = await album.getAssetListPaged(page: 0, size: total);

      for (final asset in assets) {
        all.add(asset);
        processed++;
        onProgress(processed / total);
      }
    }

    return all;
  }
}