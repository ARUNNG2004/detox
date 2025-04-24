package com.example.detox

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.Log

class BootReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "DetoxBootReceiver"
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED && context != null) {
            Log.i(TAG, "Device Boot Completed. Checking if Detox service needs restart.")

            // TODO: Implement logic to check if a detox session was active before reboot
            // This would likely involve reading a persistent flag (e.g., from SharedPreferences)
            // that was set when a session started and cleared when it ended normally.

            val shouldRestartService = checkDetoxState(context) // Placeholder for checking state

            if (shouldRestartService) {
                Log.i(TAG, "Restarting Detox Foreground Service.")
                val serviceIntent = Intent(context, DetoxForegroundService::class.java)
                serviceIntent.action = DetoxForegroundService.ACTION_START_SERVICE

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
            } else {
                Log.i(TAG, "No active detox session found. Service not restarted.")
            }
        }
    }

    // Placeholder function - replace with actual logic to check persistent state
    private fun checkDetoxState(context: Context): Boolean {
        // Example: Read from SharedPreferences
        // val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        // return prefs.getBoolean("flutter.isDetoxActive", false) // Key must match Flutter side
        Log.w(TAG, "checkDetoxState: Persistence check not implemented yet.")
        return false
    }
}