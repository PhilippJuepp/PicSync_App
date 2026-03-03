package com.example.picsync_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat

class UploadService : Service() {
    companion object {
        const val ACTION_START = "picsync.action.START"
        const val ACTION_STOP = "picsync.action.STOP"
        const val ACTION_UPDATE_PROGRESS = "picsync.action.UPDATE_PROGRESS"

        const val EXTRA_UPLOADED = "uploaded"
        const val EXTRA_TOTAL = "total"

        private const val CHANNEL_ID = "picsync_upload"
        private const val NOTIFICATION_ID = 2001
    }

    private var uploadedCount = 0
    private var totalCount = 0
    private var isForegroundStarted = false
    private lateinit var notificationManager: NotificationManager
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onCreate() {
        super.onCreate()
        notificationManager = getSystemService(NotificationManager::class.java)
        val powerManager = getSystemService(POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "picsync:UploadWakeLock")
        wakeLock?.setReferenceCounted(false)
        wakeLock?.acquire(10 * 60 * 60 * 1000L)
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                ensureForegroundStarted()
                publishProgressNotification(indeterminate = true)
            }
            ACTION_UPDATE_PROGRESS -> {
                ensureForegroundStarted()
                uploadedCount = intent.getIntExtra(EXTRA_UPLOADED, uploadedCount)
                totalCount = intent.getIntExtra(EXTRA_TOTAL, totalCount)
                val indeterminate = totalCount <= 0
                publishProgressNotification(indeterminate = indeterminate)
                if (totalCount > 0 && uploadedCount >= totalCount) {
                    publishDoneNotification()
                    stopForeground(STOP_FOREGROUND_DETACH)
                    stopSelf()
                }
            }
            ACTION_STOP -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
            else -> {
                ensureForegroundStarted()
                publishProgressNotification(indeterminate = true)
            }
        }
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        wakeLock?.let {
            if (it.isHeld) {
                it.release()
            }
        }
        wakeLock = null
        isForegroundStarted = false
    }

    private fun ensureForegroundStarted() {
        if (isForegroundStarted) {
            return
        }
        startForeground(NOTIFICATION_ID, buildProgressNotification(indeterminate = true))
        isForegroundStarted = true
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }
        val channel = NotificationChannel(
            CHANNEL_ID,
            "PicSync Upload",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Hintergrund-Upload"
        }
        notificationManager.createNotificationChannel(channel)
    }

    private fun buildProgressNotification(indeterminate: Boolean): Notification {
        val contentText = if (totalCount > 0) {
            "$uploadedCount / $totalCount"
        } else {
            "Upload läuft im Hintergrund..."
        }
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("PicSync")
            .setContentText(contentText)
            .setSmallIcon(android.R.drawable.stat_sys_upload)
            .setOnlyAlertOnce(true)
            .setOngoing(true)
            .setProgress(
                if (indeterminate) 0 else totalCount,
                if (indeterminate) 0 else uploadedCount,
                indeterminate
            )
            .build()
    }

    private fun publishProgressNotification(indeterminate: Boolean) {
        notificationManager.notify(NOTIFICATION_ID, buildProgressNotification(indeterminate))
    }

    private fun publishDoneNotification() {
        val doneNotification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("PicSync")
            .setContentText("Upload abgeschlossen")
            .setSmallIcon(android.R.drawable.stat_sys_upload_done)
            .setOnlyAlertOnce(true)
            .setOngoing(false)
            .setAutoCancel(true)
            .build()
        notificationManager.notify(NOTIFICATION_ID, doneNotification)
    }
}
