package com.example.picsync_app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "picsync/background_upload"
    private val tag = "PicSync"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "requestNotificationPermission" -> {
                            val granted = requestNotificationPermissionIfNeeded()
                            result.success(granted)
                        }
                        "start" -> {
                            startUploadService()
                            result.success(null)
                        }
                        "stop" -> {
                            stopUploadService()
                            result.success(null)
                        }
                        "updateProgress" -> {
                            val uploaded = call.argument<Int>("uploaded") ?: 0
                            val total = call.argument<Int>("total") ?: 0
                            updateUploadProgress(uploaded, total)
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    Log.e(tag, "Method channel error: ${e.message}")
                    result.error("ERROR", e.message, null)
                }
            }
    }

    private fun requestNotificationPermissionIfNeeded(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return true
        }
        val granted = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.POST_NOTIFICATIONS
        ) == PackageManager.PERMISSION_GRANTED
        if (!granted) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                1001
            )
            return true
        }
        return granted
    }

    private fun startUploadService() {
        val intent = Intent(this, UploadService::class.java).apply {
            action = UploadService.ACTION_START
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
        } catch (e: Exception) {
            Log.e(tag, "Failed to start service: ${e.message}")
        }
    }

    private fun stopUploadService() {
        val intent = Intent(this, UploadService::class.java).apply {
            action = UploadService.ACTION_STOP
        }
        try {
            startService(intent)
        } catch (e: Exception) {
            Log.e(tag, "Failed to stop service: ${e.message}")
        }
    }

    private fun updateUploadProgress(uploaded: Int, total: Int) {
        val intent = Intent(this, UploadService::class.java).apply {
            action = UploadService.ACTION_UPDATE_PROGRESS
            putExtra(UploadService.EXTRA_UPLOADED, uploaded)
            putExtra(UploadService.EXTRA_TOTAL, total)
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
        } catch (e: Exception) {
            Log.e(tag, "Failed to update progress: ${e.message}")
        }
    }
}