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
          'Camera access is needed to scan menus and take photos. Please enable it in settings.',
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
          'Photo library access is needed to select profile pictures and menu images. Please enable it in settings.',
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
    
    final hasPermission = await requestCamera(context);
    if (!hasPermission) {
      if (context.mounted) {
        _showRationale(context);
      }
    }
    return hasPermission;
  }

  static Future<bool> checkAndRequestPhotos(BuildContext context) async {
    final hasPhotos = await Permission.photos.isGranted;
    if (hasPhotos) return true;
    
    final hasPermission = await requestPhotoLibrary(context);
    if (!hasPermission) {
      if (context.mounted) {
        _showRationale(context, 'To select profile pictures and menu images.');
      }
    }
    return hasPermission;
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

  /// Requests all permissions required for BLE P2P (Nearby Connections).
  /// On Android 12+ this includes BLUETOOTH_SCAN, BLUETOOTH_ADVERTISE, and
  /// BLUETOOTH_CONNECT; older Android also needs ACCESS_FINE_LOCATION.
  /// On iOS the system prompt is triggered automatically by the plugin.
  static Future<bool> requestBluetooth(BuildContext context) async {
    if (Platform.isAndroid) {
      final permissions = [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
        Permission.nearbyWifiDevices,
      ];
      final statuses = await permissions.request();
      final allGranted =
          statuses.values.every((s) => s.isGranted || s.isLimited);
      if (!allGranted && context.mounted) {
        await _showSettingsDialog(
          context,
          'Bluetooth Access Required',
          'Bluetooth and location permissions are needed to discover and '
              'connect to nearby devices. Please enable them in settings.',
        );
      }
      return allGranted;
    }
    // iOS: permissions are declared in Info.plist; request triggers system prompt.
    final status = await Permission.bluetooth.request();
    return status.isGranted;
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
      final bluetoothStatus = await Permission.bluetooth.status;
      final locationStatus = await Permission.locationWhenInUse.status;
      return bluetoothStatus.isGranted && locationStatus.isGranted;
    } else {
      final status = await Permission.bluetooth.status;
      return status.isGranted;
    }
  }

  static Future<bool> checkBluetoothPermissions() async {
    if (Platform.isAndroid) {
      final permissions = [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
        Permission.nearbyWifiDevices,
      ];
      final statuses = await permissions.request();
      return statuses.values.every((s) => s.isGranted || s.isLimited);
    } else {
      final status = await Permission.bluetooth.request();
      return status.isGranted;
    }
  }
}