import 'package:flutter/services.dart';

class BackgroundUploadService {
  static const MethodChannel _channel =
      MethodChannel('picsync/background_upload');

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
}
