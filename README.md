# Sushare

A distributed, serverless Flutter mobile app that enables groups of friends to collaboratively compose restaurant orders in real-time — entirely over Bluetooth, with no internet connection required.

---

Available on:

- Android: [Sushare on Google Play](https://play.google.com/store/apps/details?id=com.medai.sushishare)

---

## Overview

**Sushare** is designed for all-you-can-eat sushi restaurants where groups want to combine their individual orders. The app operates **entirely offline and peer-to-peer** — no backend, no cloud database, no login required.

### Key Features

- **Distributed Sessions** — One device acts as the host, advertising a GATT server over BLE. Other devices discover and connect directly via Bluetooth.
- **Local Identity** — Users create local profiles with username, first name, last name, and an optional avatar icon.
- **Real-time Order Merging** — Each participant builds their own sub-order; the host sees a real-time merged view ready to hand to the waiter.
- **QR Code & Short Code Sharing** — Host shares the session via QR code or an 8-character short code. Guests join by scanning or typing it.
- **Menu AI Extraction** — Scan restaurant menus using the camera; Claude AI extracts items and prices automatically.
- **Arrival Checklist** — Each participant tracks which of their ordered dishes have arrived at the table, with a progress indicator per item.
- **Saved Orders** — Frequently visit the same spot? Save your usual order and load it in one tap next time.
- **Yummies** — Mark favourite menu items with a personal flag, preserved locally and never synced to other devices.

### Architecture

- **No backend, no cloud** — All data lives on-device (SQLite via `sqflite`) or is exchanged directly over BLE between devices.
- **BLE P2P** — The host runs a GATT peripheral (`PeripheralManager`); guests use a GATT central (`CentralManager`). A custom chunked framing protocol handles payloads larger than the BLE MTU.
- **MVVM + Repository** — Clean separation between UI (pages), ViewModels (Riverpod notifiers), and data layers (repositories over sqflite).
- **Riverpod 3.x** — State management using `Notifier`, `AsyncNotifier`, and `FutureProvider.family` without code generation.
- **Material Design 3** — Dynamic theming with a coral/salmon fallback color (`#FF7E70`).

---

## Project Structure

```
lib/
├── core/
│   ├── providers.dart          # Global Riverpod providers
│   ├── router/                 # GoRouter configuration
│   ├── theme/                  # Material 3 theme
│   ├── utils/                  # Order aggregation utilities
│   └── result/                 # Result type for error handling
├── data/
│   └── database/               # SQLite database setup (sqflite)
├── domain/
│   ├── models/                 # Domain models (LocalUser, Session, Restaurant, …)
│   └── repositories/           # Repository classes (sqflite-backed)
├── l10n/                       # ARB localization files + generated Dart
├── services/
│   ├── host_ble_service.dart        # BLE GATT peripheral (host side)
│   ├── participant_ble_service.dart # BLE GATT central (guest side)
│   ├── ble_framing.dart             # Chunked message framing
│   ├── sync_message.dart            # BLE sync message protocol
│   ├── menu_ai_service.dart         # AI menu extraction (Anthropic Claude)
│   ├── camera_service.dart          # Camera / image picking
│   └── permission_service.dart      # Runtime permission helpers
└── ui/
    ├── pages/                  # Screen widgets organized by feature
    ├── viewmodels/             # Riverpod notifiers
    └── widgets/                # Shared reusable widgets
```

---

## Supported Languages

- English (en)
- Italian (it)
- Spanish (es)
- French (fr)
- German (de)

---

## Prerequisites

### Required Tools

1. **Flutter SDK** (3.7.0 or later)
   ```bash
   flutter --version
   ```

2. **Dart SDK** (included with Flutter)

3. **Android Studio** or **Xcode** (for respective platform builds)

### Platform-Specific Requirements

#### Android
- Android SDK (API 21+)
- A physical device is strongly recommended — BLE advertising is not supported on most emulators

#### iOS
- Xcode 15+
- iOS 13.0+ deployment target
- A physical device is required — BLE is not available on simulators

---

## Running the App

### 1. Get Dependencies

```bash
flutter pub get
```

### 2. Run on a Connected Device

```bash
# Run on default connected device
flutter run

# Run on a specific device
flutter run -d <device-id>

# List available devices
flutter devices
```

> **Note:** No code generation step is needed. Riverpod, models, and localization do not use `build_runner` in this project.

### First Launch Flow

1. **Onboarding** — 3 screens explaining the app concepts
2. **Profile Setup** — Create your username, name, and choose an avatar
3. **Sessions** — View existing sessions, create a new table, or join one

---

## Configuration

### AI Menu Extraction

The app uses the Anthropic Claude API to extract menu items from photos. To enable it, store your API key via the in-app settings screen. The key is saved securely using `flutter_secure_storage` and never leaves the device except in API calls to Anthropic.

### Permissions

**Android** (`android/app/src/main/AndroidManifest.xml`):
- `CAMERA` — Scanning menu photos and QR codes
- `READ_EXTERNAL_STORAGE` (≤ API 32) — Image selection from gallery
- `BLUETOOTH`, `BLUETOOTH_ADMIN` (≤ API 30) — BLE on Android 6–11
- `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` (≤ API 30) — Required for BLE scanning on Android 6–11
- `BLUETOOTH_SCAN`, `BLUETOOTH_ADVERTISE`, `BLUETOOTH_CONNECT` (API 31+) — BLE on Android 12+
- `INTERNET` — Anthropic API calls for AI menu extraction only

**iOS** (`ios/Runner/Info.plist`):
- `NSCameraUsageDescription` — Camera for menu scanning and QR codes
- `NSPhotoLibraryUsageDescription` — Gallery access for menu and profile photos
- `NSBluetoothAlwaysUsageDescription` — BLE session hosting and joining

---

## Building for Android

### Debug APK

```bash
flutter build apk --debug
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`

### Release APK / App Bundle

1. Create a keystore (if you don't have one):
   ```bash
   keytool -genkey -v -keystore key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias sushare
   ```

2. Configure signing in `android/app/build.gradle.kts`:
   ```kotlin
   signingConfigs {
       create("release") {
           storeFile = file("key.jks")
           storePassword = "your_password"
           keyAlias = "sushare"
           keyPassword = "your_password"
       }
   }
   ```

3. Build:
   ```bash
   flutter build apk --release
   # or for Play Store
   flutter build appbundle --release
   ```

---

## Building for iOS

### Prerequisites

1. Open the workspace in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. Select your Apple Developer team in Signing & Capabilities

3. Run CocoaPods install if needed:
   ```bash
   cd ios && pod install
   ```

### Device Build

```bash
flutter build ios --release
```

### App Store

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select "Any iOS Device" as target
3. Product → Archive
4. Follow the App Store submission workflow in Xcode Organizer

---

## Troubleshooting

### Common Issues

1. **`flutter pub get` fails**
   - Ensure your Flutter SDK is 3.7.0 or later (`flutter --version`)

2. **BLE session not discoverable**
   - Ensure Bluetooth is enabled on both devices
   - On Android 6–11, location permission must be granted for BLE scanning
   - Check that the host device has granted Bluetooth advertise permission
   - BLE advertising does not work on emulators or simulators — use physical devices

3. **Guest cannot connect to host**
   - Devices should be within normal Bluetooth range (≤ 10 m)
   - Ensure neither device runs the app as both host and guest simultaneously
   - Try stopping and restarting the host session

4. **AI menu extraction not working**
   - Verify the Anthropic API key is saved in the app settings
   - The device needs an active internet connection for this feature only

5. **iOS build fails with pod errors**
   - Run `cd ios && pod install --repo-update`
   - Ensure Xcode Command Line Tools are installed: `xcode-select --install`

---

## License

This project is for educational/personal use. See LICENSE file for details.

---

## Credits

Built with Flutter and powered by:

- **State management** — `flutter_riverpod`
- **Navigation** — `go_router`
- **Local database** — `sqflite`, `path_provider`
- **Bluetooth P2P** — `bluetooth_low_energy`
- **QR code** — `qr_flutter`, `mobile_scanner`
- **AI menu extraction** — `anthropic_sdk_dart`
- **Camera & images** — `image_picker`, `flutter_image_compress`
- **Secure storage** — `flutter_secure_storage`
- **Theming** — `flex_color_scheme`, `dynamic_color`, `google_fonts`
- **Utilities** — `uuid`, `freezed_annotation`, `json_annotation`, `shared_preferences`, `permission_handler`, `share_plus`, `package_info_plus`
