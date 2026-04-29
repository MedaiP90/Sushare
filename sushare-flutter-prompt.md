# AI Coding Prompt: Sushare — Flutter App (Serverless / Distributed)

> **Platform:** iOS & Android  
> **Architecture:** Fully distributed, serverless — no backend, no cloud database.  
> **Purpose:** Guide an AI coding assistant to implement the complete Flutter app from scratch.  
> **Language:** All code, comments, and documentation must be written in **English**.

---

## 1. Project Overview

Build **Sushare** — a Flutter mobile app that lets a group of friends collaboratively compose a sushi all-you-can-eat order in real time. The app operates **entirely offline and peer-to-peer**: the device that creates a session acts as the session host; other devices join directly over the local network. There is no server, no cloud, and no login — each user is a local profile stored on their own device.

### Key Architectural Principles

- **No backend, no cloud:** all data lives on-device (SQLite via `drift`) or is exchanged over BLE/Bluetooth P2P.
- **Distributed sessions:** the host device advertises via BLE (`flutter_nearby_connections_plus`); participants connect directly over Bluetooth — no shared WiFi network required.
- **Local identity:** users create a local profile (username, first name, last name, optional profile photo). Usernames are unique only within a session — enforced by the host at join time.
- **Resilient local storage:** every device persists its own sub-order and session history regardless of connectivity.

---

## 2. Technology Stack

| Concern | Package |
|---|---|
| State management | `riverpod` (code-gen flavour: `flutter_riverpod` + `riverpod_annotation`) |
| Local database | `drift` (SQLite wrapper with type-safe queries) |
| BLE P2P transport (host + participant) | `flutter_nearby_connections_plus` (BLE + Bluetooth; Android: Nearby Connections API; iOS: MultipeerConnectivity) |
| Camera / image pick | `image_picker` |
| AI menu extraction | `anthropic_sdk_dart` (calls `claude-sonnet-4-20250514`) |
| Navigation | `go_router` |
| Serialisation | `json_serializable` + `freezed` |
| Dependency injection | Riverpod providers (no separate DI library needed) |
| Localisation | `flutter_localizations` (en + it) |
| Permissions | `permission_handler` |
| UUID generation | `uuid` |
| Theming | `dynamic_color` (Material You wallpaper extraction) + `flex_color_scheme` |

---

## 3. Code Quality Requirements

Apply these rules consistently across **every** Dart file.

### 3.1 Flutter Architecture (MVVM + Repository)

Follow the official Flutter architecture guide at `https://docs.flutter.dev/app-architecture/guide`:

- **View** — Widget classes. Only layout, styling, and user event forwarding. Zero business logic.
- **ViewModel** — `@riverpod` `AsyncNotifier` or `Notifier` subclass. Holds UI state, exposes commands, calls repositories.
- **Repository** — single source of truth for a domain entity. Reads/writes local DB and/or network. Returns domain models (never raw DB rows or JSON maps).
- **Service** — wraps platform APIs (camera, permissions, nearby, embedded server). No UI state.

Folder organisation follows a **hybrid model**: `data/` and `domain/` organised by type; `ui/` organised by feature.

### 3.2 OOP Principles (EPAM — https://campus.epam.com/en/blog/275)
- **Single Responsibility:** one class, one reason to change.
- **Open/Closed:** add behaviour through new classes, not by editing existing ones.
- **Liskov Substitution:** abstractions backed by concrete implementations; swap freely in tests.
- **Interface Segregation:** small, focused abstract classes — no `BaseEverything`.
- **Dependency Inversion:** ViewModels depend on abstract repository interfaces; concrete implementations are injected by Riverpod providers.

### 3.3 Performance Best Practices (`https://docs.flutter.dev/perf/best-practices`)
- Use `const` constructors everywhere possible.
- Prefer `ListView.builder` / `GridView.builder` for any list that may exceed ~20 items.
- Avoid rebuilding widget subtrees unnecessarily: scope `Consumer` / `ref.watch` to the smallest widget that needs it.
- Do not perform heavy computation on the main isolate; use `compute()` for aggregation of large orders.
- Avoid `Opacity` widget for animations; use `AnimatedOpacity` or `FadeTransition`.
- Prefer `RepaintBoundary` around complex, independently animated sub-trees.
- Never call `setState` from inside `build`.

### 3.4 Dart Style
- Maximum **2 levels of block nesting** inside any function body; extract deeper logic into named helpers.
- Use **early returns / guard clauses** to avoid nested `if-else` chains.
- Use `const` for all compile-time-constant values.
- Prefer `switch` expressions (Dart 3) over chains of `if-else`.
- All public symbols must have Dart `///` doc comments.
- All `async` functions use `await`; no `.then()` chains.
- Use `Result<T>` (see §6.1) instead of throwing exceptions across layer boundaries.

---

## 4. Project Structure

```
sushare/
├── lib/
│   ├── main.dart                  # App entry point, ProviderScope, MaterialApp
│   ├── app.dart                   # Root widget, GoRouter setup, theme init
│   │
│   ├── core/
│   │   ├── theme/                 # M3 Expressive colour seeds, TextTheme, shape system
│   │   ├── router/                # GoRouter routes and guards
│   │   ├── result/                # Result<T, E> sealed class
│   │   ├── extensions/            # Dart extension methods
│   │   └── utils/                 # Pure utility functions (aggregation, QR, etc.)
│   │
│   ├── data/
│   │   ├── database/              # Drift database definition, DAOs
│   │   ├── network/               # NearbyConnectionsAdapter, BLE message codec
│   │   └── repositories/          # Concrete repository implementations
│   │
│   ├── domain/
│   │   ├── models/                # Freezed domain models (User, Restaurant, Session, …)
│   │   ├── repositories/          # Abstract repository interfaces
│   │   └── services/              # Abstract service interfaces
│   │
│   ├── services/                  # Concrete service implementations
│   │   ├── nearby_connections_adapter.dart  # Low-level Nearby Connections wrapper
│   │   ├── host_ble_service.dart            # Host: advertise + accept + broadcast
│   │   ├── participant_ble_service.dart     # Participant: scan + connect + push
│   │   ├── camera_service.dart    # image_picker + compression
│   │   └── menu_ai_service.dart   # Claude API integration
│   │
│   └── ui/
│       ├── core/                  # Shared widgets, theme tokens as Dart consts
│       ├── profile/               # Local profile setup & edit
│       ├── home/                  # Dashboard: active sessions + restaurants
│       ├── session/               # Session creation, join, live order
│       ├── order/                 # Personal sub-order editor
│       ├── merged_order/          # Aggregated order view
│       ├── checklist/             # Arrival tracking
│       ├── restaurant/            # Restaurant detail + menu
│       └── scan_menu/             # Camera capture + AI extraction flow
│
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
│
└── pubspec.yaml
```

---

## 5. Domain Models

All models are `@freezed` data classes with `json_serializable`. Place each in `lib/domain/models/`.

### 5.1 LocalUser
```dart
/// The local user profile stored on this device.
@freezed
class LocalUser with _$LocalUser {
  const factory LocalUser({
    required String id,              // UUID v4, generated once at first launch
    required String username,        // unique within a session (enforced by host)
    required String firstName,
    required String lastName,
    String? profilePicturePath,      // absolute path to local image file
    required int avatarColorValue,   // Color.value — fallback when no photo set
    DateTime? createdAt,
  }) = _LocalUser;
}
```

### 5.2 Restaurant
```dart
@freezed
class Restaurant with _$Restaurant {
  const factory Restaurant({
    required String id,
    required String name,
    String? address,
    String? coverImagePath,      // local file path
    required List<MenuItem> menu,
    required DateTime createdAt,
  }) = _Restaurant;
}

@freezed
class MenuItem with _$MenuItem {
  const factory MenuItem({
    required String id,
    required String name,
    required String category,
    String? description,
    String? imageUrl,
  }) = _MenuItem;
}
```

### 5.3 Session
```dart
/// A shared ordering session hosted on one device.
@freezed
class Session with _$Session {
  const factory Session({
    required String id,
    required String name,
    required String restaurantId,
    required String hostUserId,
    required List<String> participantIds,
    required SessionStatus status,
    Order? mainOrder,                   // populated when status == sent
    required List<Order> additionalOrders,
    required DateTime createdAt,
    DateTime? sentAt,
  }) = _Session;
}

enum SessionStatus { open, sent, closed }

@freezed
class Order with _$Order {
  const factory Order({
    required String id,
    required String label,          // "Main Order", "Round 2", …
    required List<OrderItem> items,
    DateTime? createdAt,
  }) = _Order;
}

@freezed
class OrderItem with _$OrderItem {
  const factory OrderItem({
    required String menuItemId,
    required String name,           // denormalized snapshot
    required int quantity,
    required List<String> contributorIds,
  }) = _OrderItem;
}
```

### 5.4 PersonalSubOrder
```dart
@freezed
class PersonalSubOrder with _$PersonalSubOrder {
  const factory PersonalSubOrder({
    required String id,
    required String sessionId,
    required String userId,
    required List<SubOrderEntry> entries,
    required List<ChecklistEntry> checklist,
    required bool locked,
    required DateTime updatedAt,
  }) = _PersonalSubOrder;
}

@freezed
class SubOrderEntry with _$SubOrderEntry {
  const factory SubOrderEntry({
    required String menuItemId,
    required String name,
    required int quantity,
  }) = _SubOrderEntry;
}

@freezed
class ChecklistEntry with _$ChecklistEntry {
  const factory ChecklistEntry({
    required String menuItemId,
    required String name,
    required int orderedQuantity,
    required int arrivedCount,
  }) = _ChecklistEntry;
}
```

### 5.5 SavedOrder
```dart
@freezed
class SavedOrder with _$SavedOrder {
  const factory SavedOrder({
    required String id,
    required String restaurantId,
    required String label,
    required List<SubOrderEntry> entries,
    required DateTime createdAt,
  }) = _SavedOrder;
}
```

---

## 6. Core Utilities

### 6.1 Result Type (`lib/core/result/`)

```dart
/// A sealed class representing success or failure without throwing exceptions.
/// Use as the return type of all repository and service methods.
sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.error);
  final Object error;
}

extension ResultExtension<T> on Result<T> {
  bool get isOk => this is Ok<T>;
  T get value => (this as Ok<T>).value;
  Object get error => (this as Err<T>).error;

  R fold<R>({required R Function(T) onOk, required R Function(Object) onErr}) =>
      switch (this) {
        Ok(:final value) => onOk(value),
        Err(:final error) => onErr(error),
      };
}
```

### 6.2 Order Aggregation (`lib/core/utils/order_aggregator.dart`)

```dart
/// Merges multiple personal sub-orders into a single [Order].
/// Runs in a separate isolate via [compute] for large groups.
///
/// Dishes sharing the same [menuItemId] are merged: quantities are summed
/// and contributor IDs are collected.
///
/// [subOrders] — list of locked personal sub-orders
/// [label]     — display label for the resulting order
Order aggregateSubOrders(List<PersonalSubOrder> subOrders, String label) {
  final itemMap = <String, OrderItem>{};

  for (final subOrder in subOrders) {
    for (final entry in subOrder.entries) {
      final existing = itemMap[entry.menuItemId];

      itemMap[entry.menuItemId] = existing == null
          ? OrderItem(
              menuItemId: entry.menuItemId,
              name: entry.name,
              quantity: entry.quantity,
              contributorIds: [subOrder.userId],
            )
          : existing.copyWith(
              quantity: existing.quantity + entry.quantity,
              contributorIds: [...existing.contributorIds, subOrder.userId],
            );
    }
  }

  return Order(
    id: const Uuid().v4(),
    label: label,
    items: itemMap.values.toList(),
    createdAt: DateTime.now(),
  );
}
```

---

## 7. Data Layer

### 7.1 Drift Database (`lib/data/database/`)

Define a single `AppDatabase` class with the following tables:

| Table | Columns (in addition to `id TEXT PK`) |
|---|---|
| `local_users` | `username`, `first_name`, `last_name`, `profile_picture_path`, `avatar_color_value`, `created_at` |
| `restaurants` | `name`, `address`, `cover_image_path`, `menu_json TEXT`, `created_at` |
| `sessions` | `name`, `restaurant_id`, `host_user_id`, `participant_ids_json`, `status TEXT`, `main_order_json`, `additional_orders_json`, `created_at`, `sent_at` |
| `personal_sub_orders` | `session_id`, `user_id`, `entries_json`, `checklist_json`, `locked INTEGER`, `updated_at` |
| `saved_orders` | `restaurant_id`, `label`, `entries_json`, `created_at` |

Store complex nested structures as JSON text columns (serialised with `jsonEncode`/`jsonDecode` using the model's `toJson`/`fromJson`).

Create one DAO per table:
- `LocalUserDao` — CRUD + `watchCurrentUser()`
- `RestaurantDao` — CRUD + `watchAll()` + `watchById(id)`
- `SessionDao` — CRUD + `watchAll()` + `watchById(id)`
- `PersonalSubOrderDao` — `upsert`, `watchBySessionAndUser`, `watchAllBySession`
- `SavedOrderDao` — CRUD + `watchByRestaurant(restaurantId)`

### 7.2 Repository Interfaces (`lib/domain/repositories/`)

```dart
abstract class RestaurantRepository {
  Stream<List<Restaurant>> watchAll();
  Stream<Restaurant?> watchById(String id);
  Future<Result<Restaurant>> create(Restaurant restaurant);
  Future<Result<Restaurant>> addMenuItem(String restaurantId, MenuItem item);
  Future<Result<void>> delete(String id);
}

abstract class SessionRepository {
  Stream<List<Session>> watchAll();
  Stream<Session?> watchById(String id);
  Future<Result<Session>> create(Session session);
  Future<Result<Session>> update(Session session);
}

abstract class PersonalSubOrderRepository {
  Stream<PersonalSubOrder?> watchBySessionAndUser(String sessionId, String userId);
  Stream<List<PersonalSubOrder>> watchAllBySession(String sessionId);
  Future<Result<PersonalSubOrder>> upsert(PersonalSubOrder subOrder);
}

abstract class SavedOrderRepository {
  Stream<List<SavedOrder>> watchByRestaurant(String restaurantId);
  Future<Result<SavedOrder>> save(SavedOrder order);
  Future<Result<void>> delete(String id);
}
```

Implement each interface in `lib/data/repositories/` using the corresponding Drift DAO.

---

## 8. Networking: Distributed Session Architecture

A session is hosted entirely on one device. The host uses standard Bluetooth Low Energy GATT via `bluetooth_low_energy` to advertise the session and exchange data with participants. **No shared WiFi network is required** — all communication runs over BLE.

### 8.1 BLE Session Discovery

Use `bluetooth_low_energy` (`PeripheralManager` / `CentralManager`) for zero-config BLE device discovery and data transfer:
- **Host** runs as a GATT peripheral: advertises service UUID `19B10000-E8F2-537E-4F6C-D104768A1214` and sets the local name to `"S|{8charId}|{sessionName≤16}|{hostName≤8}"` (≤ 36 chars).
- **Participant** runs as a GATT central: scans filtered by the same service UUID; each discovered peripheral whose name matches the `"S|…"` format is shown as a joinable session card.
- When a participant selects a session, `CentralManager.connect()` is called, GATT is discovered, the TX notify characteristic is subscribed, and a `userInfo` write is sent to the RX characteristic.
- The host receives the write and immediately sends back an `initialSync` notification containing the full session snapshot.

**Cross-platform note:** `bluetooth_low_energy` uses standard BLE GATT and supports **Android↔Android, iOS↔iOS, and Android↔iOS** connections — no cross-platform limitation. The QR-code / manual session-code join path (§10.4) is retained as a convenience when BLE discovery is slow or blocked by system permissions.

### 8.2 Host: BLE P2P Service (`lib/services/host_ble_service.dart`)

The host runs as a `PeripheralManager` GATT server. Two characteristics are exposed under the service UUID:

| Characteristic UUID | Direction | Properties |
|---|---|---|
| `19B10001-…` (TX) | host → participant | Notify |
| `19B10002-…` (RX) | participant → host | Write, WriteWithoutResponse |

```dart
/// Manages the host-side BLE GATT peripheral.
/// Lifecycle: start() when a session is created, stop() when the session is closed.
class HostBleService {
  Future<void> start({required String sessionId, required String sessionName, required String hostName});
  Future<void> stop();
  Stream<SyncMessage> get messages; // incoming writes from participants
  void broadcast(SyncMessage msg);
  void broadcastSessionUpdate(Session session);
  void broadcastRestaurantUpdate(Restaurant restaurant);
  void sendSessionClosedToGuests();
  void setSession(Session session);
  void setRestaurant(Restaurant restaurant);
  void upsertSubOrder(PersonalSubOrder subOrder);
  void clearSubOrders();
  void dispose();
}
```

All inter-device messages are UTF-8 JSON bytes. Large payloads are split into 500-byte chunks by `chunkBytes()` in `lib/services/ble_framing.dart`; each chunk has a 4-byte header `[totalChunks:2][chunkIndex:2]`. The receiver uses `ChunkAssembler` to reassemble before parsing.

### 8.3 BLE Message Protocol

All P2P messages are JSON objects with a `type` discriminator:

```dart
/// All possible BLE P2P message types.
enum WsMessageType {
  // Host → Participants
  sessionSnapshot,     // full session state on join or major change
  subOrderUpdated,     // a participant updated their sub-order
  sessionSent,         // host sent the order; payload = aggregated Order
  additionalOrderAdded,
  participantJoined,
  participantLeft,

  // Participant → Host
  subOrderPush,        // participant pushes their sub-order update
  checklistUpdate,     // participant updates arrival counts
  requestSnapshot,     // participant re-requests full state
}
```

```dart
@freezed
class NetworkMessage with _$NetworkMessage {
  const factory NetworkMessage({
    required WsMessageType type,
    required String senderId,
    required Map<String, dynamic> payload,
    required DateTime timestamp,
  }) = _NetworkMessage;
}
```

### 8.4 Participant BLE Client (`lib/services/participant_ble_service.dart`)

The participant runs as a `CentralManager`. Discovery is filtered by the Sushare service UUID; GATT connection flow: connect → discoverGATT → subscribe TX → write userInfo to RX → receive initialSync notify.

```dart
/// Manages the participant-side BLE GATT central connection to the session host.
class ParticipantBleService {
  Future<void> startDiscovery({String? myDeviceName});
  Future<void> stopDiscovery();
  Stream<List<DiscoveredSession>> get discoveredSessions;

  /// Connect to [endpointId] (peripheral UUID), subscribe to notifications,
  /// and send [userInfo] to register. Returns true on success.
  Future<bool> connect({
    required String endpointId,
    required Map<String, dynamic> userInfo,
    String? myDeviceName,
  });
  Future<void> disconnect();
  void pushSubOrderUpdate(PersonalSubOrder subOrder);
  void markSessionClosed();
  Stream<SyncMessage> get messages;
  Stream<bool> get connectionStatus;
  Stream<void> get sessionClosed;
  bool get isConnected;
  bool get isSessionClosed;
  void dispose();
}
```

---

## 9. Services

### 9.1 Menu AI Service (`lib/services/menu_ai_service.dart`)

```dart
/// Sends a menu image to the Anthropic Claude API and parses the response
/// into a list of [MenuItem] objects.
abstract class MenuAiService {
  /// [imageBytes] — raw image bytes (JPEG or PNG, max 5 MB after compression)
  Future<Result<List<MenuItem>>> extractFromImage(Uint8List imageBytes);
}
```

Implementation details:
- Compress the image with `flutter_image_compress` to ≤ 1280 px on the long edge and ≤ 1.5 MB before sending.
- Encode as base64.
- Call the Anthropic API using `anthropic_sdk_dart` with the following system prompt:

```
You are a menu digitisation assistant.
Analyse the provided restaurant menu image.
Return ONLY a valid JSON array — no markdown fences, no preamble.
Each element: { "name": string, "category": string, "description": string }
Rules:
- "name": exact dish name as printed.
- "category": logical group (e.g. "Nigiri", "Maki", "Temaki", "Sashimi", "Dessert").
- "description": one short English sentence if visible; empty string otherwise.
- Do not invent dishes not present in the image.
```

- Parse the JSON response; skip malformed entries silently.
- Deduplicate against existing menu items (case-insensitive name match).
- The API key is stored in `flutter_secure_storage` — the user provides it once in Settings.

### 9.2 Camera Service (`lib/services/camera_service.dart`)

```dart
abstract class CameraService {
  /// Capture a photo for menu scanning — returns raw compressed bytes.
  Future<Result<Uint8List>> captureFromCamera();
  Future<Result<Uint8List>> pickFromGallery();

  /// Capture or pick a profile picture.
  /// Launches [image_cropper] with a square crop UI after capture/pick.
  /// Saves the result to the app's documents directory and returns the file path.
  Future<Result<String>> pickAndCropProfilePicture(ImageSource source);
}
```

Use `image_picker` to capture/pick and `flutter_image_compress` to compress.

### 9.3 BLE P2P Transport (`lib/services/`)

Discovery and data transfer are unified in two services:
- **`HostBleService`** (§8.2) — host advertising + accepting connections + sending/receiving messages.
- **`ParticipantBleService`** (§8.4) — participant scanning + connecting + sending/receiving messages.

Both use `bluetooth_low_energy` directly (`PeripheralManager` for host, `CentralManager` for participant). Shared framing logic (chunking + reassembly) lives in `lib/services/ble_framing.dart` and is imported by both services.

---

## 10. UI Layer

### 10.1 Material 3 Expressive Theme (`lib/core/theme/`)

Implement a `AppTheme` class that builds both light and dark `ThemeData` using `flex_color_scheme` and `dynamic_color`:

```dart
/// Seeds the colour scheme from the device wallpaper (Material You) when
/// available; falls back to the app's custom seed colour (deep sushi red).
const Color _fallbackSeed = Color(0xFFC0392B);

/// Shape system — M3 Expressive uses generous rounded corners and
/// shape-morphing for interactive elements.
final shapeSystem = {
  ShapeRole.extraSmall:  RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
  ShapeRole.small:       RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ShapeRole.medium:      RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ShapeRole.large:       RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
  ShapeRole.extraLarge:  RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
};
```

M3 Expressive design directives to apply:
- **Bold containment:** use `Card` with elevated surface tones and strong corner radii (`large` shape) to group related content — never rely on whitespace alone.
- **Colour as signal:** primary-coloured `FilledButton` for the single most important action per screen; `OutlinedButton` for secondary actions.
- **Expressive FAB:** use `FloatingActionButton.extended` as the primary CTA on list screens; animate its label visibility with `AnimatedSize`.
- **Physics-based motion:** use `SpringSimulation` or `CurvedAnimation` with `Curves.elasticOut` for card expansion and item insertions; use `Curves.easeInOutCubicEmphasized` for screen transitions (M3 spec).
- **Dynamic colour tonal surfaces:** `ColorScheme.surfaceContainerLow`, `surfaceContainer`, `surfaceContainerHigh` for layered card elevation.
- **Typography:** use `google_fonts` to load `Nunito` (display/headline — expressive, rounded) paired with `Source Serif 4` (body/label — readable, classic). Apply `fontVariations` for weight adjustments on headings.
- **Size contrast:** primary action buttons are visually larger than secondary ones (use `ButtonStyle` with custom `minimumSize`); key data (dish names, quantities) use `displaySmall` / `headlineMedium`.

```dart
TextTheme buildTextTheme() => GoogleFonts.nunitoTextTheme().copyWith(
  displayLarge:   GoogleFonts.nunito(fontWeight: FontWeight.w800),
  displayMedium:  GoogleFonts.nunito(fontWeight: FontWeight.w700),
  headlineLarge:  GoogleFonts.nunito(fontWeight: FontWeight.w700),
  headlineMedium: GoogleFonts.nunito(fontWeight: FontWeight.w600),
  titleLarge:     GoogleFonts.nunito(fontWeight: FontWeight.w600),
  bodyLarge:      GoogleFonts.sourceSerif4(),
  bodyMedium:     GoogleFonts.sourceSerif4(),
  bodySmall:      GoogleFonts.sourceSerif4(),
  labelLarge:     GoogleFonts.nunito(fontWeight: FontWeight.w600),
);
```

### 10.2 Navigation (GoRouter)

```dart
// All routes defined in lib/core/router/app_router.dart
/                          → splash / profile setup check
/profile/setup             → ProfileSetupPage    (first launch only)
/home                      → HomePage            (shell route with NavigationBar)
  /home/sessions           → SessionsPage
  /home/restaurants        → RestaurantsPage
  /home/settings           → SettingsPage
/restaurants/:id           → RestaurantDetailPage
/sessions/new              → NewSessionPage
/sessions/join             → JoinSessionPage     (shows discovered + manual entry)
/sessions/:id              → SessionPage         (live session shell)
  /sessions/:id/order      → PersonalOrderPage
  /sessions/:id/merged     → MergedOrderPage
  /sessions/:id/checklist  → ChecklistPage
/scan-menu/:restaurantId   → ScanMenuPage
```

### 10.3 ViewModels (Riverpod Notifiers)

Implement one `AsyncNotifier` per feature. Each ViewModel:
- Declares all commands as methods (Command pattern per Flutter architecture guide).
- Returns `void` from commands; exposes a `Stream` or `AsyncValue` for state.
- Never imports Flutter widgets.

#### `ProfileViewModel`
```dart
@riverpod
class ProfileViewModel extends _$ProfileViewModel {
  // Commands
  Future<void> createProfile({
    required String username,
    required String firstName,
    required String lastName,
    required Color avatarColor,
  });
  Future<void> updateProfile({
    String? username,
    String? firstName,
    String? lastName,
  });
  Future<void> updateProfilePicture();   // triggers CameraService, saves local file
  Future<void> removeProfilePicture();
}
```

#### `SessionViewModel`
```dart
@riverpod
class SessionViewModel extends _$SessionViewModel {
  // Commands
  Future<void> loadSession(String sessionId);
  Future<void> createSession(String name, String restaurantId);
  Future<void> joinSession(DiscoveredSession discovered);
  Future<void> joinSessionManually(String sessionCode);  // QR / manual code fallback
  Future<void> addParticipant(String userId);   // host only
  Future<void> sendOrder();                     // host only
  Future<void> addAdditionalOrder(List<SubOrderEntry> entries);
}
```

#### `PersonalOrderViewModel`
```dart
@riverpod
class PersonalOrderViewModel extends _$PersonalOrderViewModel {
  Future<void> loadForSession(String sessionId);
  Future<void> updateEntry(String menuItemId, String name, int delta);
  Future<void> loadFromSaved(SavedOrder saved);
}
```

#### `ChecklistViewModel`
```dart
@riverpod
class ChecklistViewModel extends _$ChecklistViewModel {
  Future<void> loadForSession(String sessionId);
  Future<void> markArrived(String menuItemId, int count);
}
```

#### `RestaurantViewModel`
```dart
@riverpod
class RestaurantViewModel extends _$RestaurantViewModel {
  Future<void> createRestaurant(String name, String? address);
  Future<void> addMenuItem(String restaurantId, MenuItem item);
  Future<void> scanAndExtractMenu(String restaurantId);
}
```

### 10.4 Screen-by-Screen UI Specifications

#### `ProfileSetupPage`
- Full-screen onboarding — shown only on first launch.
- Top: tappable avatar circle. If no photo is set, shows initials on the chosen colour background; if a photo is set, displays it cropped to circle. Tap opens an `ActionSheet` with "Take Photo" / "Choose from Gallery" / "Remove Photo".
- `TextField` for username (3–30 chars, no spaces; validated for uniqueness within sessions at join time).
- `TextField` for first name (max 50 chars).
- `TextField` for last name (max 50 chars).
- Avatar colour picker row: 8 tappable `CircleAvatar` colour swatches from the M3 tonal palette; used as fallback when no profile photo is set.
- `FilledButton` "Start" — disabled until username, first name, and last name are all valid.
- Transition to `/home` with a `ZoomPageTransitionsBuilder`.

#### `HomePage` (NavigationBar shell)
Three tabs: **Sessions**, **Restaurants**, **Settings**.

- `NavigationBar` with M3 Expressive indicator pills.
- Each tab lazily mounted with `IndexedStack`.

#### `SessionsPage`
- `SliverAppBar.large` with "Sushare" title and current user avatar.
- `FloatingActionButton.extended` "New Session".
- `SliverList` of `SessionCard` widgets.
- Empty state: illustration + "Create or join a session" text.

#### `SessionCard`
- M3 `Card` with `surfaceContainerHigh` fill.
- Session name as `titleLarge`; restaurant name as `bodyMedium`.
- Status `Chip` with semantic colour (green = open, amber = sent, grey = closed).
- Row of `CircleAvatar` for participants (max 5 shown, then "+N more").

#### `NewSessionPage`
- `DropdownMenu` to pick existing restaurant or create new.
- Text field for session name.
- "Create & Start Hosting" `FilledButton`.

#### `JoinSessionPage`
- `AnimatedList` of `DiscoveredSessionTile` (auto-refreshes from Nearby scan).
- "Enter Code Manually" bottom sheet with a 6-character session code field.
- QR scanner option via `mobile_scanner`.

#### `SessionPage` (live session shell)
State-machine driven by `session.status`:

| Status | Content shown |
|---|---|
| `open` | Participant list + "Edit My Order" card + "Send Order" FAB (host only) |
| `sent` | Merged order panel + "Add Round" button + "My Checklist" shortcut |
| `closed` | Read-only history |

The host sees a "Send Order" `FloatingActionButton.extended` that triggers a confirmation `AlertDialog` before proceeding.

#### `PersonalOrderPage`
- Grouped `SliverList` by category (uses `SliverStickyHeader` or a custom sliver).
- Each `MenuItemTile` has: name (`titleMedium`), category chip, description (`bodySmall`), and a quantity stepper (`-` `[N]` `+`).
- Stepper uses `AnimatedSwitcher` with a scale transition for the counter.
- Bottom `BottomAppBar` with total item count and "Save as Preset" `TextButton`.

#### `MergedOrderPage`
- Full aggregated order, sorted by category then quantity descending.
- Each `OrderItem` shows name, total quantity (large `displaySmall`), and a `Wrap` of contributor avatar chips.
- Share button exports the order as plain text via `share_plus`.

#### `ChecklistPage`
- Per-item arrival tracker: `[Arrived: N / Ordered: M]` with `+` / `-` buttons.
- Items with `arrivedCount == orderedQuantity` are styled with a strikethrough and tinted green.
- Progress `LinearProgressIndicator` at the top.

#### `RestaurantDetailPage`
- `SliverAppBar` with cover image (or placeholder gradient).
- Category-grouped menu list.
- `FloatingActionButton.extended` "Scan Menu" — triggers `ScanMenuPage`.
- Each `MenuItemCard`: name, category `Chip`, description.

#### `ScanMenuPage`
- Camera preview using `image_picker` capture flow.
- After capture: shows image thumbnail + "Extract Menu" `FilledButton`.
- Progress indicator while calling the Claude API.
- Result bottom sheet: list of extracted items with checkboxes; "Add Selected" button.

#### `SettingsPage`
- `ListTile` for Anthropic API key (masked; stored in `flutter_secure_storage`).
- Theme mode toggle (System / Light / Dark).
- App version info.

### 10.5 Shared Widgets (`lib/ui/core/widgets/`)

| Widget | Description |
|---|---|
| `QuantityStepper` | `−` · count · `+` with `AnimatedSwitcher` counter |
| `SessionStatusChip` | Colour-coded M3 `Chip` for session status |
| `ParticipantAvatarRow` | Row of `CircleAvatar`s with overflow count |
| `CategoryChip` | Small `FilterChip`-style label for menu categories |
| `MenuItemTile` | Reusable tile for both menu browser and order editor |
| `OrderItemTile` | Read-only tile for merged/additional orders |
| `EmptyStateWidget` | Illustration + message + optional action button |
| `LoadingOverlay` | Semi-transparent scrim with `CircularProgressIndicator` |
| `AppSnackBar` | Standardised SnackBar builder (success / error / info) |

---

## 11. Session Flow: Step-by-Step

### Host Flow
1. Host creates session → `HostBleService.start(AdvertisePayload)` → begins BLE advertising.
2. For each `connectionRequested` event the host calls `acceptConnection(endpointId)`.
3. On `connected` event → sends `sessionSnapshot` to the newly joined endpoint; broadcasts `participantJoined` to all others.
4. Participants push BLE `subOrderPush` messages → host persists them.
5. Host taps "Send Order" → `compute(aggregateSubOrders, allSubOrders, "Main Order")` → updates `session.mainOrder` → sets `status = sent` → broadcasts `sessionSent`.
6. Any participant (including host) can add additional rounds; host broadcasts `additionalOrderAdded`.
7. Each participant tracks arrivals locally; updates pushed via BLE `checklistUpdate`.

### Participant Flow
1. Discovers session via BLE scan (`ParticipantBleService.startDiscovery()`) or enters the host's 6-character session code manually.
2. Calls `ParticipantBleService.join(hostEndpointId, localUser)` → host accepts the BLE connection.
3. Receives `sessionSnapshot` from host over the BLE channel.
4. Edits personal sub-order → sends `subOrderPush` on every change (debounced 500 ms).
5. On `sessionSent` event → navigates to `MergedOrderPage`.
6. Updates checklist → sends `checklistUpdate` messages.

---

## 12. Local Persistence Strategy

- The host device's `SessionRepository` is the source of truth for the session document.
- Each participant's `PersonalSubOrderRepository` persists their own sub-order locally — so they can review their order even if disconnected.
- All devices persist the final `mainOrder` and `additionalOrders` locally once received via BLE, so session history is available offline.
- `RestaurantRepository` and `SavedOrderRepository` are purely local and never synced.

---

## 13. Permissions

Request permissions at runtime with `permission_handler`, gracefully handling denial:

| Permission | When needed | Platform |
|---|---|---|
| `bluetooth` | BLE operations (legacy) | Android ≤ 11 |
| `bluetoothScan` | Scanning for nearby sessions | Android 12+ |
| `bluetoothAdvertise` | Hosting / advertising a session | Android 12+ |
| `bluetoothConnect` | Connecting to a discovered host | Android 12+ |
| `locationWhenInUse` | Required for BLE scanning | Android ≤ 11 |
| `camera` | Menu photo scan + QR scanning | Both |
| `photos` | Gallery menu pick | Both |

Show a permission rationale `AlertDialog` before each system prompt. On iOS, add `NSBluetoothAlwaysUsageDescription` and `NSBluetoothPeripheralUsageDescription` to `Info.plist`.

---

## 14. Error Handling

- All repository and service methods return `Result<T>`.
- ViewModels catch `Result.Err` and expose an error state consumed by the View.
- Views show errors via `AppSnackBar.error(message)`.
- BLE disconnection (`connectionLost` event) is surfaced as a persistent `MaterialBanner` at the top of `SessionPage` with a "Reconnect" action that re-runs the join flow.
- `HostBleService` and `ParticipantBleService` catch all plugin exceptions internally; upper layers receive typed `SyncMessage` events or boolean success/failure.

---

## 15. Testing

### Unit Tests (`test/unit/`)
- `order_aggregator_test.dart` — covers all aggregation edge cases (single user, N users, duplicate dishes, empty sub-orders).
- `result_test.dart` — covers `Ok`, `Err`, `fold`.
- `session_viewmodel_test.dart` — mock repositories via Riverpod overrides.

### Widget Tests (`test/widget/`)
- `quantity_stepper_test.dart`
- `session_card_test.dart`
- `checklist_page_test.dart`

### Integration Tests (`test/integration/`)
- `session_host_join_test.dart` — spins up the embedded server, connects a mock client, verifies join + sub-order push + aggregation.

---

## 16. Implementation Order

Implement in this sequence to enable early testing at each step:

1. **Scaffolding** — project structure, `pubspec.yaml`, Drift DB schema, Riverpod setup.
2. **Profile** — local user creation, persistence, profile setup page.
3. **Restaurants** — CRUD, menu display, `RestaurantDetailPage`.
4. **Session host (no network)** — create session, embedded server stub, `SessionPage` state machine.
5. **Order editing** — `PersonalOrderPage`, `QuantityStepper`, sub-order persistence.
6. **Order aggregation** — `aggregateSubOrders` util + `MergedOrderPage`.
7. **BLE host service** — `ble_framing.dart`, `HostBleService` (`PeripheralManager`), advertising GATT service, receiving writes, sending notify.
8. **BLE participant client** — `ParticipantBleService` (`CentralManager`), discovery + connect + GATT subscribe + join flow, `JoinSessionPage`.
9. **BLE message routing** — full round-trip: sub-order push → host aggregation → broadcast snapshot.
10. **Checklist** — `ChecklistPage`, arrival tracking, BLE sync.
11. **Additional rounds** — post-send order flow.
12. **Saved orders** — save/load preset orders.
13. **Menu scanning** — `CameraService`, `MenuAiService`, `ScanMenuPage`.
14. **QR fallback** — `qr_flutter` generation on host, `mobile_scanner` on participant.
15. **M3 Expressive polish** — dynamic colour, animations, transitions, typography.
16. **Permissions** — runtime permission requests with rationale dialogs.
17. **Testing** — unit, widget, integration tests.

---

## 17. pubspec.yaml Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # Architecture & State
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.3.5

  # Data & Serialisation
  drift: ^2.20.0
  sqlite3_flutter_libs: ^0.5.0
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  uuid: ^4.5.1

  # BLE P2P via standard GATT (Android ↔ iOS cross-platform, no shared WiFi required)
  bluetooth_low_energy: ^6.0.0

  # Navigation
  go_router: ^14.8.1

  # UI & Theme
  dynamic_color: ^1.7.0
  flex_color_scheme: ^8.0.2
  google_fonts: ^6.2.1

  # Media
  image_picker: ^1.1.2
  flutter_image_compress: ^2.3.0
  path_provider: ^2.1.5      # resolve local file paths for profile picture storage
  image_cropper: ^7.1.0      # crop profile photo to square before saving

  # AI
  anthropic_sdk_dart: ^0.9.0

  # Storage
  flutter_secure_storage: ^9.2.4

  # Utilities
  permission_handler: ^11.3.1
  share_plus: ^10.1.3
  qr_flutter: ^4.1.0
  mobile_scanner: ^5.2.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.13
  drift_dev: ^2.20.0
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.3
  riverpod_lint: ^2.3.13
  custom_lint: ^0.6.9
  mocktail: ^1.0.4
```

---

## 18. Critical Limitations to Document

1. **Standard BLE GATT is cross-platform** — `bluetooth_low_energy` supports Android↔iOS connections. The QR-code / manual code join path is retained as a fallback for when BLE discovery is unavailable or slow (e.g. system permission denied, BT radio off).
2. **No shared WiFi required** — all session data flows over standard BLE GATT. Devices do not need to be on the same network. Typical BLE range is 10–30 m; throughput is lower than WiFi.
3. **Payload size and throughput** — large payloads (full menu JSON) are chunked into 500-byte BLE packets by `chunkBytes()` in `ble_framing.dart` (§8.2). Avoid sending raw image bytes over the channel. Send menu data only once on join, not on every sub-order update.
4. **Android ≤ 11 requires location permission** for BLE scanning (OS restriction). On Android 12+ only `BLUETOOTH_SCAN` / `BLUETOOTH_ADVERTISE` / `BLUETOOTH_CONNECT` are needed.
4. **Anthropic API key management:** the key is stored locally in `flutter_secure_storage`. Clearly warn the user in the Settings screen that the key is not shared with other devices and is used exclusively for menu scanning.
5. **Host device must remain awake** during an active session; instruct the user to disable auto-lock while hosting. Acquire a `WakeLock` (`wakelock_plus`) when hosting.
6. **Session resilience:** if the host device disconnects, participants lose the BLE connection. Design the `SessionPage` to detect Nearby endpoint disconnection and show a reconnection banner with a "Try Reconnect" button that re-runs the `ParticipantBleService.join` flow.
7. **No user accounts:** usernames are unique only within a session. The same person could appear under different names in different sessions. Profile data (username, name, photo) lives exclusively on the device and is never synced. This is by design and should be clearly communicated in onboarding.
