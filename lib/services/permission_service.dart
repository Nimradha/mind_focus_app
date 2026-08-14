import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PermissionService {
  static const MethodChannel _channel =
      MethodChannel('com.example.first_app/permissions');

  /// Checks if "Appear on top" / Overlay permission is granted on Android
  static Future<bool> checkOverlayPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final bool hasPermission =
          await _channel.invokeMethod('checkOverlayPermission');
      return hasPermission;
    } catch (e) {
      debugPrint('Error checking overlay permission: $e');
      return true;
    }
  }

  /// Opens Android System Settings for "Appear on top" / Overlay permission
  static Future<void> requestOverlayPermission() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (e) {
      debugPrint('Error requesting overlay permission: $e');
    }
  }

  /// Checks if exact alarm permission is granted on Android 12+
  static Future<bool> checkExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final bool hasPermission =
          await _channel.invokeMethod('checkExactAlarmPermission');
      return hasPermission;
    } catch (e) {
      debugPrint('Error checking exact alarm permission: $e');
      return true;
    }
  }

  /// Opens Android System Settings for "Alarms & Reminders" permission
  static Future<void> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestExactAlarmPermission');
    } catch (e) {
      debugPrint('Error requesting exact alarm permission: $e');
    }
  }

  /// Opens Android System Settings for Battery Optimization
  static Future<void> requestBatteryOptimizationPermission() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestBatteryOptimizationPermission');
    } catch (e) {
      debugPrint('Error requesting battery optimization permission: $e');
    }
  }

  /// Convenience helper to check overlay permission and prompt the user if missing
  static Future<bool> checkAndRequestOverlayPermission(
      BuildContext context) async {
    if (!Platform.isAndroid) return true;

    bool hasOverlay = await checkOverlayPermission();
    if (!hasOverlay && context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Full-Screen Alarm Permission'),
            content: const Text(
              'To display alarms directly on your screen without having to pull down notifications, please turn ON "Appear on top" / "Display over other apps" in settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  await requestOverlayPermission();
                },
                child: const Text(
                  'Open Settings',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );
      return false;
    }
    return true;
  }
}

