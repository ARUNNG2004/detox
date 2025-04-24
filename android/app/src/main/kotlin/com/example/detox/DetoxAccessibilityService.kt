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
        private const val TAG = "DetoxAccessibility"
        // Flag to control blocking logic, potentially set via Flutter
        var isBlockingActive = false

        // Helper function to check if the service is enabled
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
                Log.e(TAG, "Error finding setting, default accessibility to not found: ", e)
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
        Log.i(TAG, "Accessibility Service Connected")
        val info = AccessibilityServiceInfo()
        // Configure the service programmatically if needed, complementing the XML config
        info.eventTypes = AccessibilityEvent.TYPES_ALL_MASK // Listen to more events initially for debugging
        info.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
        info.flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS or
                     AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                     AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
        info.notificationTimeout = 100
        this.serviceInfo = info
        // isBlockingActive = true // Activate blocking immediately or wait for Flutter command
    }

    override fun onUnbind(intent: Intent?): Boolean {
        Log.i(TAG, "Accessibility Service Unbound")
        isBlockingActive = false
        return super.onUnbind(intent)
    }
}