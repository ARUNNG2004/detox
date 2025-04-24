package com.example.detox

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import io.flutter.Log

class DetoxForegroundService : Service() {

    companion object {
        const val NOTIFICATION_CHANNEL_ID = "DetoxServiceChannel"
        const val NOTIFICATION_ID = 1
        const val ACTION_START_SERVICE = "ACTION_START_SERVICE"
        const val ACTION_STOP_SERVICE = "ACTION_STOP_SERVICE"
        private var isServiceRunning = false
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        Log.d("DetoxForegroundService", "Service Created")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("DetoxForegroundService", "onStartCommand received action: ${intent?.action}")
        try {
            when (intent?.action) {
                ACTION_START_SERVICE -> {
                    if (!isServiceRunning) {
                        startForeground(NOTIFICATION_ID, createNotification())
                        isServiceRunning = true
                        Log.d("DetoxForegroundService", "Foreground Service Started")
                    } else {
                        Log.d("DetoxForegroundService", "Service already running")
                    }
                }
                ACTION_STOP_SERVICE -> {
                    stopForeground(true)
                    stopSelf()
                    isServiceRunning = false
                    Log.d("DetoxForegroundService", "Foreground Service Stopped")
                }
                null -> {
                    // Handle null intent action by restarting service if it was running
                    if (isServiceRunning) {
                        startForeground(NOTIFICATION_ID, createNotification())
                        Log.d("DetoxForegroundService", "Service restarted after system kill")
                    }
                }
            }
        } catch (e: Exception) {
            Log.e("DetoxForegroundService", "Error in onStartCommand: ${e.message}")
            // Attempt to recover from error
            if (isServiceRunning) {
                startForeground(NOTIFICATION_ID, createNotification())
            }
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent): IBinder? {
        // We don't provide binding, so return null
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        isServiceRunning = false
        Log.d("DetoxForegroundService", "Service Destroyed")
        // Attempt to restart service if it was killed unexpectedly
        if (isServiceRunning) {
            val intent = Intent(this, DetoxForegroundService::class.java)
            intent.action = ACTION_START_SERVICE
            startService(intent)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Detox Foreground Service Channel",
                NotificationManager.IMPORTANCE_HIGH
            )
            serviceChannel.apply {
                enableLights(true)
                setShowBadge(true)
                enableVibration(true)
                description = "Shows the active distraction blocking status"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(serviceChannel)
            Log.d("DetoxForegroundService", "Notification Channel Created")
        }
    }

    private fun createNotification(): Notification {
        // Customize this notification as needed
        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("Detox Active")
            .setContentText("Blocking distractions...")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()
    }
}