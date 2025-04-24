import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode

class DetoxService {
  static const platform = MethodChannel('com.example.detox/detox_service');

  static Future<void> startDetoxService() async {
    try {
      if (kDebugMode) {
        print('Flutter: Calling startDetoxService');
      }
      await platform.invokeMethod('startDetoxService');
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to start detox service: '${e.message}'.");
      }
      // Handle error appropriately
    }
  }

  static Future<void> stopDetoxService() async {
    try {
      if (kDebugMode) {
        print('Flutter: Calling stopDetoxService');
      }
      await platform.invokeMethod('stopDetoxService');
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to stop detox service: '${e.message}'.");
      }
      // Handle error appropriately
    }
  }

  static Future<void> setBlockingActive(bool isActive) async {
    try {
      if (kDebugMode) {
        print('Flutter: Calling setBlockingActive with $isActive');
      }
      await platform.invokeMethod('setBlockingActive', {'isActive': isActive});
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to set blocking active: '${e.message}'.");
      }
      // Handle error appropriately
    }
  }

  static Future<bool> isOverlayPermissionGranted() async {
    try {
      if (kDebugMode) {
        print('Flutter: Calling isOverlayPermissionGranted');
      }
      final bool isGranted = await platform.invokeMethod('isOverlayPermissionGranted');
      return isGranted;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to check overlay permission: '${e.message}'.");
      }
      return false; // Assume not granted on error
    }
  }

  static Future<void> requestOverlayPermission() async {
    try {
      if (kDebugMode) {
        print('Flutter: Calling requestOverlayPermission');
      }
      await platform.invokeMethod('requestOverlayPermission');
      // Note: Actual grant status needs to be checked again after user interaction
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to request overlay permission: '${e.message}'.");
      }
      // Handle error appropriately
    }
  }

  static Future<bool> isAccessibilityServiceEnabled() async {
    try {
      if (kDebugMode) {
        print('Flutter: Calling isAccessibilityServiceEnabled');
      }
      final bool isEnabled = await platform.invokeMethod('isAccessibilityServiceEnabled');
      return isEnabled;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to check accessibility service: '${e.message}'.");
      }
      return false; // Assume not enabled on error
    }
  }

  static Future<void> requestAccessibilityPermission() async {
    try {
      if (kDebugMode) {
        print('Flutter: Calling requestAccessibilityPermission');
      }
      await platform.invokeMethod('requestAccessibilityPermission');
      // Note: Actual enabled status needs to be checked again after user interaction
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to request accessibility permission: '${e.message}'.");
      }
      // Handle error appropriately
    }
  }
}