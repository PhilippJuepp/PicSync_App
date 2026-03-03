import 'package:flutter/services.dart';

class BackgroundUploadService {
  static const MethodChannel _channel =
      MethodChannel('picsync/background_upload');

  static Future<bool> requestNotificationPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestNotificationPermission');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> start() async {
    try {
      await _channel.invokeMethod<void>('start');
    } catch (_) {}
  }

  static Future<void> stop() async {

    try {
      await _channel.invokeMethod<void>('stop');
    } catch (_) {}
  }

  static Future<void> updateNotification(int uploaded, int total) async {
    try {
      await _channel.invokeMethod<void>(
        'updateProgress',
        {'uploaded': uploaded, 'total': total},
      );
    } catch (_) {}
  }
}
