import '../../core/services/api_client.dart';
import 'upload_queue.dart';

class UploadWorker {
  final UploadQueue queue;

  UploadWorker(this.queue);

  Future<void> start({required Function(int, int) onProgress}) async {
    int uploaded = 0;
    final total = queue.items.length;

    for (final item in queue.items) {
      await uploadItem(item);
      uploaded++;
      onProgress(uploaded, total);
    }
  }

  Future<void> uploadItem(UploadItem item) async {
    final file = await item.asset.file;
    if (file == null) return;

    Future<void> doUpload() async {
      final initResp = await ApiClient.post('/upload/init', {
          'filename': item.asset.title,
          'size': item.size,
          'mime': item.mimeType,
          'hash': item.hash,
      });

      if (initResp['status'] == 'exists') {
        return;
      }

      final uploadId = initResp['upload_id'] ?? initResp['id'];
      if (uploadId == null) throw Exception("Upload ID missing from init response");
      item.uploadId = uploadId;

      final raf = file.openSync();
      int offset = 0;
      const chunkSize = 1024 * 1024;

      while (offset < item.size) {
        final remaining = item.size - offset;
        final size = remaining < chunkSize ? remaining : chunkSize;
        final chunk = raf.readSync(size);

        await ApiClient.postBytes(
          '/upload/chunk',
          query: {'id': uploadId, 'offset': offset.toString()},
          body: chunk,
        );

        offset += size;
      }

      raf.closeSync();

      await ApiClient.post('/upload/complete?id=$uploadId', {});
    }

    try {
      await doUpload();
    } catch (e) {
      if (e.toString().contains('401')) {
        // Access Token expired → refresh
        await ApiClient.refreshToken();
        await doUpload(); // retry
      } else {
        rethrow;
      }
    }
  }
}