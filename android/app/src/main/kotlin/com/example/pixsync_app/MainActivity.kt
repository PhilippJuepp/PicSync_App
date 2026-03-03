package com.example.picsync_app

import android.content.Intent
import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "picsync/background_upload"
    private val TAG = "PicSync"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "start" -> {
                            startUploadService()
                            result.success(null)
                        }
                        "stop" -> {
                            stopUploadService()
                            result.success(null)
                        }
                        else -> {
                            result.notImplemented()
                        }
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Method channel error: ${e.message}")
                    result.error("ERROR", e.message, null)
                }
            }
    }

    private fun startUploadService() {
        try {
            val intent = Intent(this, UploadService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start service: ${e.message}")
        }
    }

    private fun stopUploadService() {
        try {
            val intent = Intent(this, UploadService::class.java)
            stopService(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop service: ${e.message}")
        }
    }
}