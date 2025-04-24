package com.example.detox

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import io.flutter.Log
import android.provider.Settings
import android.content.Context

class DetoxAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "DigitalWellbeingService"
        var isBlockingActive = false

        fun isAccessibilityServiceEnabled(context: Context): Boolean {
            val serviceId = context.packageName + "/" + DetoxAccessibilityService::class.java.canonicalName
            try {
                val accessibilityEnabled = Settings.Secure.getInt(
                    context.contentResolver, Settings.Secure.ACCESSIBILITY_ENABLED
                )
                if (accessibilityEnabled == 1) {
                    val settingValue = Settings.Secure.getString(
                        context.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
                    )
                    return settingValue?.split(':')?.contains(serviceId) ?: false
                }
            } catch (e: Settings.SettingNotFoundException) {
                Log.e(TAG, "Error checking accessibility settings", e)
            }
            return false
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (!isBlockingActive) return

        Log.d(TAG, "onAccessibilityEvent: type=${event?.eventType} pkg=${event?.packageName}")

        // Basic attempt to block navigation away from the app
        // This needs refinement based on testing across different Android versions/devices
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED ||
            event?.eventType == AccessibilityEvent.TYPE_VIEW_CLICKED) {

            val packageName = event.packageName?.toString()
            val className = event.className?.toString()

            // Check if the event is from the system UI or another app
            if (packageName != null && packageName != applicationContext.packageName) {
                // Attempt to bring our app back to the front
                bringAppToFront()
            }
            // More specific checks can be added here, e.g., for specific system UI elements
            // like the notification shade or recent apps screen.
        }
    }

    private fun bringAppToFront() {
        Log.d(TAG, "Attempting to bring app to front")
        val intent = Intent(this, MainActivity::class.java)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
        startActivity(intent)
    }

    override fun onInterrupt() {
        Log.w(TAG, "Accessibility Service Interrupted")
        // Handle interruption, maybe stop blocking
        isBlockingActive = false
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        val info = serviceInfo.apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
            notificationTimeout = 100
        }
        this.serviceInfo = info
    }

    override fun onUnbind(intent: Intent?): Boolean {
        Log.i(TAG, "Accessibility Service Unbound")
        isBlockingActive = false
        return super.onUnbind(intent)
    }
}
