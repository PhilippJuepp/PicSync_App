import '../../core/services/api_client.dart';
import '../../core/services/background_upload_service.dart';
import 'upload_queue.dart';
import 'dart:math';
import 'package:mutex/mutex.dart';
import '../../data/database/app_database.dart';

class UploadWorker {
  final UploadQueue queue;
  final AppDatabase db;
  final _indexMutex = Mutex();
  final _progressMutex = Mutex();

  bool _aborted = false;
  int _index = 0;
  DateTime _lastNotificationAt = DateTime.fromMillisecondsSinceEpoch(0);

  UploadWorker(this.queue, this.db);

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  int _chunkSizeForItem(UploadItem item) {
    final isVideo = item.mimeType.startsWith('video');
    return isVideo ? 16 * 1024 * 1024 : 8 * 1024 * 1024;
  }

  int _estimateUnitsForItem(UploadItem item) {
    final chunkSize = _chunkSizeForItem(item);
    final units = (item.size / chunkSize).ceil();
    return max(1, units);
  }

  Future<void> start({required Function(int, int) onProgress}) async {
    const int parallelFiles = 1;

    int uploaded = 0;
    final totalFiles = queue.items.length;

    final totalUnitsRaw = queue.items.fold<int>(
      0,
      (sum, item) => sum + _estimateUnitsForItem(item),
    );
    final totalUnits = max(1, totalUnitsRaw);
    int completedUnits = 0;

    Future<void> reportUnits(int delta) async {
      await _progressMutex.protect(() async {
        completedUnits += delta;
        if (completedUnits > totalUnits) {
          completedUnits = totalUnits;
        }

        final now = DateTime.now();
        final shouldPush = completedUnits >= totalUnits ||
            now.difference(_lastNotificationAt).inMilliseconds >= 350;
        if (shouldPush) {
          _lastNotificationAt = now;
          await BackgroundUploadService.updateNotification(completedUnits, totalUnits);
        }
      });
    }

    await BackgroundUploadService.updateNotification(0, totalUnits);

    Future<void> worker() async {
      while (!_aborted) {
        final item = await _nextItem();
        if (item == null) break;

        try {
          await db.updateStatus(item.asset.id, 'UPLOADING');

          await uploadItem(
            item,
            onUnitsProgress: reportUnits,
          );

          await db.markDone(item.asset.id, item.hash);

          uploaded++;
          onProgress(uploaded, totalFiles);
        } catch (e) {
          await db.updateStatus(item.asset.id, 'ERROR');

          _aborted = true;
          rethrow;
        }
      }
    }

    await Future.wait(
      List.generate(parallelFiles, (_) => worker()),
    );

    await BackgroundUploadService.updateNotification(totalUnits, totalUnits);
  }

  Future<UploadItem?> _nextItem() async {
    return _indexMutex.protect(() async {
      if (_index >= queue.items.length) {
        return null;
      }
      return queue.items[_index++];
    });
  }

  Future<void> uploadItem(
    UploadItem item, {
    required Future<void> Function(int deltaUnits) onUnitsProgress,
  }) async {
    final file = await item.asset.file;
    if (file == null) return;

    final chunkSize = _chunkSizeForItem(item);
    final estimatedUnits = _estimateUnitsForItem(item);
    final int parallelChunks = item.mimeType.startsWith('video') ? 2 : 3;

    Future<void> doUpload() async {
      final initResp = await ApiClient.post(
        '/upload/init',
        {
          'filename': item.asset.title,
          'size': item.size,
          'mime': item.mimeType,
          'hash': item.hash,
        },
        timeoutSeconds: 60,
      );

      final status = initResp['status']?.toString();
      if (status == 'exists') {
        await onUnitsProgress(estimatedUnits);
        return;
      }

      int resumeOffset = 0;

      resumeOffset = _asInt(initResp['offset']);

      final uploadIdRaw = initResp['upload_id'];
      final uploadId = uploadIdRaw?.toString();
      if (uploadId == null || uploadId.isEmpty) {
        throw Exception('Upload ID missing (status=$status, response=$initResp)');
      }

      if (resumeOffset < 0) {
        resumeOffset = 0;
      }
      if (resumeOffset > item.size) {
        resumeOffset = item.size;
      }

      final totalChunks = (item.size / chunkSize).ceil();
      final alreadyDoneChunks = max(0, (resumeOffset / chunkSize).floor());
      if (alreadyDoneChunks > 0) {
        await onUnitsProgress(alreadyDoneChunks);
      }

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
            await onUnitsProgress(1);
          }
        } finally {
          await raf.close();
        }
      }

      await Future.wait(
        List.generate(parallelChunks, (_) => chunkWorker()),
      );

      await completeUploadWithRetry(uploadId);
    }

    await doUpload();
  }

  Future<void> completeUploadWithRetry(String uploadId) async {
    const maxAttempts = 3;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await ApiClient.post(
          '/upload/complete?id=$uploadId',
          {},
          timeoutSeconds: 60,
        );
        return;
      } catch (e) {
        if (attempt == maxAttempts) {
          throw Exception('Upload completion failed after $maxAttempts attempts: $e');
        }
        await Future.delayed(Duration(seconds: attempt * 5));
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
        ).timeout(const Duration(seconds: 60));

        return;
      } catch (_) {
        if (attempt == maxAttempts) rethrow;
        await Future.delayed(Duration(milliseconds: 300 * attempt));
      }
    }
  }
}