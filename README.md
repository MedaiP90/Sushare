# Sushare

A distributed, serverless Flutter mobile app that enables groups of friends to collaboratively compose restaurant orders in real-time.

---

## Overview

**Sushare** is designed for all-you-can-eat sushi restaurants where groups want to combine their individual orders. The app operates **entirely offline and peer-to-peer** — no backend, no cloud database, no login required.

### Key Features

- **Distributed Sessions** — One device acts as the host, running an embedded TCP server. Other devices join directly over the local network.
- **Local Identity** — Users create local profiles with username, first name, last name, and optional profile photo.
- **Real-time Order Merging** — Each participant adds their items; the host can merge all orders into a single aggregated order.
- **QR Code Sharing** — Host can share session code via QR or manual entry.
- **Menu AI Extraction** — Scan restaurant menus using the camera; AI extracts items and prices.
- **Checklist** — Track which participants have arrived at the restaurant.

### Architecture

- **No backend, no cloud** — All data lives on-device (SQLite via Drift) or is exchanged over LAN.
- **MVVM + Repository** — Clean separation between UI, ViewModels, and data layers.
- **Riverpod** — State management with code generation.
- **Material Design 3** — Dynamic theming with a coral/salmon fallback color (#FF7E70).

---

## Project Structure

```
lib/
├── core/
│   ├── providers.dart          # Global Riverpod providers
│   ├── router/                  # GoRouter configuration
│   ├── theme/                  # Material 3 theme + animations
│   ├── utils/                 # Order aggregation utilities
│   ├── result/                # Result type for error handling
│   └── l10n/                  # Localization (.dart files)
├── data/
│   └── database/              # Drift SQLite database
├── domain/
│   ├── models/                # Domain models (LocalUser, Session, etc.)
│   └── repositories/          # Repository interfaces
├── services/                  # Platform services (host server, client, camera, AI)
└── ui/
    ├── pages/                # Screen widgets organized by feature
    ├── viewmodels/           # Riverpod notifiers
    └── core/widgets/         # Shared reusable widgets
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

1. **Flutter SDK** (version 3.7.0 or later)
   ```bash
   # Check your Flutter version
   flutter --version
   ```

2. **Dart SDK** (included with Flutter)

3. **Android Studio** or **Xcode** (for respective platform builds)

### Platform-Specific Requirements

#### Android
- Android SDK (API 21+)
- Camera permission for menu scanning

#### iOS
- Xcode 15+
- iOS 12.0+ deployment target
- Camera permission (Info.plist configuration)

---

## Running the App for Testing

### 1. Get Dependencies

```bash
cd sushare-flutter
flutter pub get
```

### 2. Generate Code

Some code uses code generation (Freezed, Drift, Riverpod). Run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Or for continuous development:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

### 3. Run on Connected Device/Emulator

```bash
# Run on default device
flutter run

# Run on a specific device
flutter run -d <device-id>

# List available devices
flutter devices
```

### First Launch Flow

1. **Onboarding** — 3 screens explaining: Create a Table, Join a Table, Enjoy the Meal
2. **Profile Setup** — Create your username, first name, last name, optional photo
3. **Sessions** — View existing sessions, create new, or join existing

---

## Building for Android

### Debug Build

```bash
flutter build apk --debug
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`

### Release Build

1. Create a keystore (if you don't have one):
   ```bash
   keytool -genkey -v -keystore key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias sushare
   ```

2. Configure signing in `android/app/build.gradle`:
   ```groovy
   signingConfigs {
       release {
           storeFile file("key.jks")
           storePassword "your_password"
           keyAlias "sushare"
           keyPassword "your_password"
       }
   }
   ```

3. Build:
   ```bash
   flutter build apk --release
   ```

Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## Building for iOS

### Prerequisites

1. Open Xcode and configure your Apple Developer account:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. Select your team in Signing & Capabilities

3. Set the deployment target in Xcode (iOS 12.0+ recommended)

### Simulator Build

```bash
flutter build ios --simulator --no-codesign
```

To run on simulator:
```bash
# List available simulators
xcrun simctl list devices available

# Boot a simulator
xcrun simctl boot <device-id>

# Run the app
flutter run -d <simulator-id>
```

### Device Build (Ad Hoc / Development)

```bash
flutter build ios --debug
# or
flutter build ios --release
```

For device deployment, you'll need:
- An Apple Developer account
- Proper provisioning profiles
- Code signing configured in Xcode

### App Store Build

For App Store distribution, use Xcode:
1. Open `ios/Runner.xcworkspace`
2. Select "Any iOS Device" as the target
3. Product → Archive
4. Follow the App Store submission workflow

---

## Configuration Notes

### Permissions

The app requires these permissions (configured in respective platform files):

**Android** (`android/app/src/main/AndroidManifest.xml`):
- `android.permission.INTERNET` — Local network communication
- `android.permission.ACCESS_WIFI_STATE` — Wi-Fi discovery
- `android.permission.CAMERA` — Menu scanning
- `android.permission.READ_EXTERNAL_STORAGE` — Image selection

**iOS** (`ios/Runner/Info.plist`):
- `NSCameraUsageDescription` — "Sushare needs camera access to scan menus"
- `NSPhotoLibraryUsageDescription` — "Sushare needs photo library access to select profile pictures"

### Environment Variables

For AI menu extraction, set your Anthropic API key:
```bash
# Android (local.properties)
echo "ANTHROPIC_API_KEY=your_key" >> android/local.properties

# iOS (add to Runner/Info.plist or environment)
```

---

## Testing

### Unit Tests

```bash
flutter test test/unit/
```

### Widget Tests

```bash
flutter test test/widget/
```

### Integration Tests

```bash
flutter test test/integration/
```

---

## Troubleshooting

### Common Issues

1. **Build fails with "not found" errors**
   - Run `flutter pub get` again
   - Run `dart run build_runner build`

2. **iOS simulator won't start**
   - Check Xcode is properly installed
   - Try: `xcrun simctl list devices`

3. **Android APK won't install**
   - Enable "Install unknown apps" in device settings
   - Check USB debugging is enabled

4. **Session won't connect over local network**
   - Ensure devices are on the same Wi-Fi
   - Check firewall isn't blocking local ports

---

## License

This project is for educational/personal use. See LICENSE file for details.

---

## Credits

Built with Flutter and powered by the following packages:
- Riverpod, Drift, GoRouter
- Shelf, Dio, WebSocket Channel
- Anthropic SDK, Google Fonts
- Flex Color Scheme, Dynamic Color