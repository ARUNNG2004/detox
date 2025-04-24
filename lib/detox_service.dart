import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DetoxService {
  static const platform = MethodChannel('com.example.detox/detox_service');

  static Future<bool> isOverlayPermissionGranted() async {
    try {
      if (kDebugMode) {
        print('Flutter: Checking overlay permission');
      }
      final bool isGranted = await platform.invokeMethod('isOverlayPermissionGranted');
      return isGranted;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to check overlay permission: '${e.message}'.");
      }
      return false;
    }
  }

  static Future<void> requestOverlayPermission() async {
    try {
      if (kDebugMode) {
        print('Flutter: Requesting overlay permission');
      }
      await platform.invokeMethod('requestOverlayPermission');
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to request overlay permission: '${e.message}'.");
      }
      rethrow;
    }
  }

  static Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final bool isEnabled = await platform.invokeMethod('isAccessibilityServiceEnabled');
      return isEnabled;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to check accessibility service: '${e.message}'.");
      }
      return false;
    }
  }

  static Future<void> requestAccessibilityPermission() async {
    try {
      await platform.invokeMethod('requestAccessibilityPermission');
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to request accessibility permission: '${e.message}'.");
      }
      rethrow;
    }
  }

  static Future<void> startDetoxService() async {
    try {
      await platform.invokeMethod('startDetoxService');
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to start detox service: '${e.message}'.");
      }
      rethrow;
    }
  }

  static Future<void> stopDetoxService() async {
    try {
      await platform.invokeMethod('stopDetoxService');
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to stop detox service: '${e.message}'.");
      }
      rethrow;
    }
  }

  static Future<void> setBlockingActive(bool active) async {
    try {
      await platform.invokeMethod('setBlockingActive', {'active': active});
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to set blocking active: '${e.message}'.");
      }
      rethrow;
    }
  }

  static Future<bool> isScreenPinningActive() async {
    try {
      final bool isActive = await platform.invokeMethod('isScreenPinningActive');
      return isActive;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to check screen pinning status: '${e.message}'.");
      }
      return false;
    }
  }

  static Future<void> startScreenPinning() async {
    try {
      await platform.invokeMethod('startScreenPinning');
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to start screen pinning: '${e.message}'.");
      }
      rethrow;
    }
  }

  static Future<void> stopScreenPinning() async {
    try {
      await platform.invokeMethod('stopScreenPinning');
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to stop screen pinning: '${e.message}'.");
      }
      rethrow;
    }
  }
}
