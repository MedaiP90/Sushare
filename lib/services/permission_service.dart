import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

enum AppPermission {
  camera,
  photoLibrary,
  notifications,
  bluetooth,
}

class PermissionService {
  static Future<bool> requestCamera(BuildContext context) async {
    final status = await Permission.camera.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        final shouldOpen = await _showSettingsDialog(
          context,
          'Camera Access Required',
          'Camera access was previously denied. Go to Settings → Privacy & Security → Camera and enable it for this app.',
        );
        if (shouldOpen) {
          openAppSettings();
        }
      }
      return false;
    }

    return false;
  }

  static Future<bool> requestPhotoLibrary(BuildContext context) async {
    final status = await Permission.photos.status;

    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.photos.request();
      return result.isGranted || result.isLimited;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        final shouldOpen = await _showSettingsDialog(
          context,
          'Photo Access Required',
          'Photo library access was previously denied. Go to Settings → Privacy & Security → Photos and enable it for this app.',
        );
        if (shouldOpen) {
          openAppSettings();
        }
      }
      return false;
    }
    
    return false;
  }

  static Future<bool> requestNotification(BuildContext context) async {
    final status = await Permission.notification.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      final result = await Permission.notification.request();
      return result.isGranted;
    }
    
    return false;
  }

  static Future<bool> checkAndRequestCamera(BuildContext context) async {
    final hasCamera = await Permission.camera.isGranted;
    if (hasCamera) return true;
    return requestCamera(context);
  }

  static Future<bool> checkAndRequestPhotos(BuildContext context) async {
    final status = await Permission.photos.status;
    if (status.isGranted || status.isLimited) return true;
    return requestPhotoLibrary(context);
  }

  static Future<bool> checkAndRequestCameraQuiet() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;
    
    if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }
    
    return false;
  }

  static Future<bool> checkAndRequestPhotosQuiet() async {
    final status = await Permission.photos.status;
    if (status.isGranted || status.isLimited) return true;
    
    if (status.isDenied) {
      final result = await Permission.photos.request();
      return result.isGranted || result.isLimited;
    }
    
    return false;
  }

  static Future<bool> _showSettingsDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static void _showRationale(BuildContext context, [String reason = '']) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          reason.isEmpty 
              ? 'Camera permission is required for this feature.'
              : 'Photo permission is required $reason',
        ),
        action: SnackBarAction(
          label: 'Settings',
          onPressed: () => openAppSettings(),
        ),
      ),
    );
  }

  /// Requests all permissions required for standard BLE (bluetooth_low_energy).
  /// Android 12+: BLUETOOTH_SCAN, BLUETOOTH_ADVERTISE, BLUETOOTH_CONNECT.
  /// Android 6–11: legacy BLUETOOTH + location for BLE scanning.
  /// iOS: system prompt triggered by NSBluetoothAlwaysUsageDescription in Info.plist.
  static Future<bool> requestBluetooth(BuildContext context) async {
    if (Platform.isAndroid) {
      // Android 12+ (API 31+)
      final permissions = [
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
      ];
      final statuses = await permissions.request();
      final allGranted =
          statuses.values.every((s) => s.isGranted || s.isLimited);
      if (!allGranted && context.mounted) {
        await _showSettingsDialog(
          context,
          'Bluetooth Access Required',
          'Bluetooth permissions are needed to discover and connect to '
              'nearby devices. Please enable them in settings.',
        );
      }
      return allGranted;
    }
    // iOS: CoreBluetooth triggers the system prompt automatically when the
    // CentralManager first scans. permission_handler cannot trigger it
    // reliably — let bluetooth_low_energy handle authorization natively.
    return true;
  }

  static Future<Map<Permission, PermissionStatus>> checkAllPermissions() async {
    return {
      Permission.camera: await Permission.camera.status,
      Permission.photos: await Permission.photos.status,
    };
  }

  static Future<void> openSettings() async {
    await openAppSettings();
  }

  static Future<bool> isBluetoothEnabled() async {
    if (Platform.isAndroid) {
      final status = await Permission.bluetoothScan.status;
      return status.isGranted;
    } else {
      final status = await Permission.bluetooth.status;
      return status.isGranted;
    }
  }

  static Future<bool> checkBluetoothPermissions() async {
    if (Platform.isAndroid) {
      final permissions = [
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
      ];
      final statuses = await permissions.request();
      return statuses.values.every((s) => s.isGranted || s.isLimited);
    } else {
      final status = await Permission.bluetooth.request();
      return status.isGranted;
    }
  }
}