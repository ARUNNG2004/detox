package com.example.detox

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.Log

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.detox/detox_service"
    private val OVERLAY_PERMISSION_REQ_CODE = 1234
    private val ACCESSIBILITY_SERVICE_REQ_CODE = 1235

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "startDetoxService" -> {
                    startDetoxForegroundService()
                    result.success(null)
                }
                "stopDetoxService" -> {
                    stopDetoxForegroundService()
                    result.success(null)
                }
                "setBlockingActive" -> {
                    val isActive = call.argument<Boolean>("isActive") ?: false
                    DetoxAccessibilityService.isBlockingActive = isActive
                    Log.d("MainActivity", "Accessibility blocking set to: $isActive")
                    result.success(null)
                }
                "requestOverlayPermission" -> {
                    requestOverlayPermission()
                    // Result will be handled in onActivityResult
                    // For simplicity, we just acknowledge the request here
                    result.success(null) 
                }
                 "isOverlayPermissionGranted" -> {
                    result.success(isOverlayPermissionGranted())
                }
                "requestAccessibilityPermission" -> {
                    requestAccessibilityPermission()
                    result.success(null) // Acknowledge request
                }
                "isAccessibilityServiceEnabled" -> {
                    result.success(DetoxAccessibilityService.isAccessibilityServiceEnabled(this))
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun startDetoxForegroundService() {
        Log.d("MainActivity", "Attempting to start foreground service")
        val serviceIntent = Intent(this, DetoxForegroundService::class.java)
        serviceIntent.action = DetoxForegroundService.ACTION_START_SERVICE
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
    }

    private fun stopDetoxForegroundService() {
        Log.d("MainActivity", "Attempting to stop foreground service")
        val serviceIntent = Intent(this, DetoxForegroundService::class.java)
        serviceIntent.action = DetoxForegroundService.ACTION_STOP_SERVICE
        startService(serviceIntent) // Use startService to send stop command
    }

    private fun isOverlayPermissionGranted(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true // Overlay permission not required before Marshmallow
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(this)) {
                val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                    Uri.parse("package:$packageName"))
                startActivityForResult(intent, OVERLAY_PERMISSION_REQ_CODE)
            } else {
                 Log.d("MainActivity", "Overlay permission already granted")
            }
        }
    }

    private fun requestAccessibilityPermission() {
        if (!DetoxAccessibilityService.isAccessibilityServiceEnabled(this)) {
             Log.d("MainActivity", "Requesting Accessibility permission")
            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
            // Optionally, you could try to guide the user directly to your service's settings
            // intent.data = Uri.parse("package:$packageName") // This might not work reliably
            startActivityForResult(intent, ACCESSIBILITY_SERVICE_REQ_CODE)
        } else {
            Log.d("MainActivity", "Accessibility permission already granted")
        }
    }

    // Handle results from permission requests (Overlay, Accessibility)
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == OVERLAY_PERMISSION_REQ_CODE) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (Settings.canDrawOverlays(this)) {
                    Log.d("MainActivity", "Overlay permission granted after request")
                    // Optionally notify Flutter
                } else {
                    Log.w("MainActivity", "Overlay permission denied after request")
                    // Handle denial - maybe show a message to the user
                }
            }
        }
        // Note: There's no direct result code for Accessibility settings.
        // We typically re-check if the service is enabled after the user returns.
        if (requestCode == ACCESSIBILITY_SERVICE_REQ_CODE) {
             Log.d("MainActivity", "Returned from Accessibility Settings. Re-checking status.")
             // Re-check and potentially notify Flutter if needed
             val isEnabled = DetoxAccessibilityService.isAccessibilityServiceEnabled(this)
             Log.d("MainActivity", "Accessibility Service Enabled: $isEnabled")
        }
    }
}

class MainActivity : FlutterActivity() {
    private val requiredPermissions = arrayOf(
        android.Manifest.permission.POST_NOTIFICATIONS,
        android.Manifest.permission.SCHEDULE_EXACT_ALARM
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handlePermissions()
    }

    private fun handlePermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val ungranted = requiredPermissions.filter {
                ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
            }

            if (ungranted.isNotEmpty()) {
                ActivityCompat.requestPermissions(
                    this,
                    ungranted.toTypedArray(),
                    PERMISSION_REQUEST_CODE
                )
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            grantResults.forEach {
                if (it != PackageManager.PERMISSION_GRANTED) {
                    Toast.makeText(
                        this,
                        "Required permissions were not granted",
                        Toast.LENGTH_LONG
                    ).show()
                    return
                }
            }
        }
    }

    companion object {
        private const val PERMISSION_REQUEST_CODE = 1001
    }
}
