package com.example.detox

import android.app.ActivityManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.app.AppOpsManager
import android.content.Context
import android.view.accessibility.AccessibilityManager
import android.accessibilityservice.AccessibilityServiceInfo
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.detox/detox_service"
    private val OVERLAY_PERMISSION_REQ_CODE = 1234
    private val USAGE_STATS_PERMISSION_REQ_CODE = 1235

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isOverlayPermissionGranted" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        // For Android 12+, check PACKAGE_USAGE_STATS instead
                        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
                        val mode = appOps.checkOpNoThrow(
                            AppOpsManager.OPSTR_GET_USAGE_STATS,
                            android.os.Process.myUid(),
                            packageName
                        )
                        result.success(mode == AppOpsManager.MODE_ALLOWED)
                    } else {
                        result.success(Settings.canDrawOverlays(this))
                    }
                }
                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        // For Android 12+, request PACKAGE_USAGE_STATS
                        startActivityForResult(
                            Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS),
                            USAGE_STATS_PERMISSION_REQ_CODE
                        )
                    } else {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        startActivityForResult(intent, OVERLAY_PERMISSION_REQ_CODE)
                    }
                    result.success(null)
                }
                "isAccessibilityServiceEnabled" -> {
                    result.success(DetoxAccessibilityService.isAccessibilityServiceEnabled(this))
                }
                "requestAccessibilityPermission" -> {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(null)
                }
                "startDetoxService" -> {
                    // Implement your service start logic here
                    result.success(null)
                }
                "stopDetoxService" -> {
                    // Implement your service stop logic here
                    result.success(null)
                }
                "setBlockingActive" -> {
                    val active = call.argument<Boolean>("active") ?: false
                    // Implement your blocking logic here
                    result.success(null)
                }
                "isScreenPinningActive" -> {
                    val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                    result.success(am.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE)
                }
                "startScreenPinning" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                            startLockTask()
                            result.success(null)
                        } else {
                            result.error("UNSUPPORTED", "Screen pinning not supported on this device", null)
                        }
                    } catch (e: Exception) {
                        result.error("FAILED", "Failed to start screen pinning", e.message)
                    }
                }
                "stopScreenPinning" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                            stopLockTask()
                            result.success(null)
                        } else {
                            result.error("UNSUPPORTED", "Screen pinning not supported on this device", null)
                        }
                    } catch (e: Exception) {
                        result.error("FAILED", "Failed to stop screen pinning", e.message)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            OVERLAY_PERMISSION_REQ_CODE -> {
                if (Settings.canDrawOverlays(this)) {
                    MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger!!, CHANNEL)
                        .invokeMethod("onOverlayPermissionResult", true)
                }
            }
            USAGE_STATS_PERMISSION_REQ_CODE -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
                    val mode = appOps.checkOpNoThrow(
                        AppOpsManager.OPSTR_GET_USAGE_STATS,
                        android.os.Process.myUid(),
                        packageName
                    )
                    MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger!!, CHANNEL)
                        .invokeMethod("onOverlayPermissionResult", mode == AppOpsManager.MODE_ALLOWED)
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            setTaskDescription(ActivityManager.TaskDescription(getString(R.string.app_name)))
        }
    }
}
