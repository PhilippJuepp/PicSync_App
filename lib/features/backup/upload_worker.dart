import '../../core/services/api_client.dart';
import 'upload_queue.dart';
import 'dart:math';
import 'package:mutex/mutex.dart';

class UploadWorker {
  final UploadQueue queue;
  final _indexMutex = Mutex();

  bool _aborted = false;
  int _index = 0;

  UploadWorker(this.queue);

  Future<void> start({required Function(int, int) onProgress}) async {
    const int parallelFiles = 1;

    int uploaded = 0;
    final total = queue.items.length;

    Future<void> worker() async {
      while (!_aborted) {
        final item = await _nextItem();
        if (item == null) break;

        try {
          await uploadItem(item);
          uploaded++;
          onProgress(uploaded, total);
        } catch (e) {
          _aborted = true;
          rethrow;
        }
      }
    }

    await Future.wait(
      List.generate(parallelFiles, (_) => worker()),
    );
  }

  Future<UploadItem?> _nextItem() async {
    return _indexMutex.protect(() async {
      if (_index >= queue.items.length) {
        return null;
      }
      return queue.items[_index++];
    });
  }

  Future<void> uploadItem(UploadItem item) async {
    final file = await item.asset.file;
    if (file == null) return;

    final bool isVideo = item.mimeType.startsWith('video');

    final int chunkSize = isVideo
        ? 16 * 1024 * 1024
        : 8 * 1024 * 1024;

    final int parallelChunks = isVideo ? 2 : 3;

    Future<void> doUpload() async {
      final initResp = await ApiClient.post('/upload/init', {
        'filename': item.asset.title,
        'size': item.size,
        'mime': item.mimeType,
        'hash': item.hash,
      });

      int resumeOffset = 0;

      if (initResp['status'] == 'exists') {
        resumeOffset = initResp['offset'];
      }

      final uploadId = initResp['upload_id'];
      if (uploadId == null) {
        throw Exception('Upload ID missing');
      }

      final totalChunks = (item.size / chunkSize).ceil();
      int nextChunk = (resumeOffset / chunkSize).floor();
      final chunkMutex = Mutex();

      Future<int?> nextChunkIndex() async {
        return chunkMutex.protect(() async {
          if (nextChunk >= totalChunks) {
            return null;
          }
          return nextChunk++;
        });
      }

      Future<void> chunkWorker() async {
        final raf = await file.open();
        try {
          while (true) {
            final index = await nextChunkIndex();
            if (index == null) break;

            final offset = index * chunkSize;
            final size = min(chunkSize, item.size - offset);

            await raf.setPosition(offset);
            final chunk = await raf.read(size);

            await postChunkWithRetry(
              uploadId: uploadId,
              offset: offset,
              data: chunk,
            );

            await Future.delayed(const Duration(milliseconds: 1));
          }
        } finally {
          await raf.close();
        }
      }

      await Future.wait(
        List.generate(parallelChunks, (_) => chunkWorker()),
      );

      await ApiClient.post('/upload/complete?id=$uploadId', {});
    }

    try {
      await doUpload();
    } catch (e) {
      if (e.toString().contains('401')) {
        await ApiClient.refreshToken();
        await doUpload();
      } else {
        rethrow;
      }
    }
  }

  Future<void> postChunkWithRetry({
    required String uploadId,
    required int offset,
    required List<int> data,
  }) async {
    const maxAttempts = 3;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await ApiClient.postBytes(
          '/upload/chunk',
          query: {
            'id': uploadId,
            'offset': offset.toString(),
          },
          body: data,
        ).timeout(const Duration(seconds: 30));

        return;
      } catch (_) {
        if (attempt == maxAttempts) rethrow;
        await Future.delayed(Duration(milliseconds: 300 * attempt));
      }
    }
  }
}