import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';

import '../domain/models/personal_sub_order.dart';
import 'ble_framing.dart';
import 'sync_message.dart';

// Must match the UUIDs declared in HostBleService.
final _serviceUuid = UUID.fromString('19B10000-E8F2-537E-4F6C-D104768A1214');
final _txUuid = UUID.fromString('19B10001-E8F2-537E-4F6C-D104768A1214');
final _rxUuid = UUID.fromString('19B10002-E8F2-537E-4F6C-D104768A1214');

/// A Sushare session discovered via BLE advertisement scanning.
class DiscoveredSession {
  final String endpointId; // Peripheral UUID string
  final String shortId;
  final String sessionName;
  final String hostName;

  const DiscoveredSession({
    required this.endpointId,
    required this.shortId,
    required this.sessionName,
    required this.hostName,
  });
}

/// Parses a Sushare host advertisement local name.
/// Expected format: "S|{8charId}|{sessionName}|{hostName}"
DiscoveredSession? parseAdvertisement(String endpointId, String? name) {
  if (name == null) return null;
  final parts = name.split('|');
  if (parts.length != 4 || parts[0] != 'S') return null;
  return DiscoveredSession(
    endpointId: endpointId,
    shortId: parts[1],
    sessionName: parts[2],
    hostName: parts[3],
  );
}

class ParticipantBleService {
  final _central = CentralManager();

  Peripheral? _hostPeripheral;
  GATTCharacteristic? _rxCharacteristic;

  final _assembler = ChunkAssembler();

  StreamSubscription? _discoveredSub;
  StreamSubscription? _connStateSub;
  StreamSubscription? _notifiedSub;
  StreamSubscription? _authorizeSub;

  final _msgCtrl = StreamController<SyncMessage>.broadcast();
  final _connCtrl = StreamController<bool>.broadcast();
  final _sessionClosedCtrl = StreamController<void>.broadcast();
  final _discoveredCtrl =
      StreamController<List<DiscoveredSession>>.broadcast();

  // UUID string → DiscoveredSession / Peripheral for lookup during connect().
  final _discoveredMap = <String, DiscoveredSession>{};
  final _peripheralMap = <String, Peripheral>{};

  bool _isConnected = false;
  bool _isSessionClosed = false;
  bool _isDiscovering = false;

  ParticipantBleService() {
    // On Android, authorize() must be called when the manager enters the
    // unauthorized state so the OS permission prompt is shown.
    _authorizeSub = _central.stateChanged.listen((e) async {
      if (e.state == BluetoothLowEnergyState.unauthorized &&
          Platform.isAndroid) {
        await _central.authorize();
      }
    });
  }

  /// Waits until the central radio is powered on (max 15 s).
  /// On Android, proactively calls authorize() if the state is unauthorized.
  Future<bool> _waitForPoweredOn() async {
    if (_central.state == BluetoothLowEnergyState.poweredOn) return true;
    if (_central.state == BluetoothLowEnergyState.unauthorized &&
        Platform.isAndroid) {
      await _central.authorize();
      if (_central.state == BluetoothLowEnergyState.poweredOn) return true;
    }
    try {
      await _central.stateChanged
          .where((e) => e.state == BluetoothLowEnergyState.poweredOn)
          .first
          .timeout(const Duration(seconds: 15));
      return true;
    } catch (_) {
      return false;
    }
  }

  bool get isConnected => _isConnected;
  bool get isSessionClosed => _isSessionClosed;

  Stream<SyncMessage> get messages => _msgCtrl.stream;
  Stream<bool> get connectionStatus => _connCtrl.stream;
  Stream<void> get sessionClosed => _sessionClosedCtrl.stream;
  Stream<List<DiscoveredSession>> get discoveredSessions =>
      _discoveredCtrl.stream;

  Future<void> startDiscovery({String? myDeviceName}) async {
    if (_isDiscovering) return;
    if (!await _waitForPoweredOn()) return;

    _discoveredSub = _central.discovered.listen(_onDiscovered);
    _connStateSub =
        _central.connectionStateChanged.listen(_onConnectionStateChanged);
    _notifiedSub =
        _central.characteristicNotified.listen(_onCharacteristicNotified);
    await _central.startDiscovery(serviceUUIDs: [_serviceUuid]);
    _isDiscovering = true;
  }

  Future<void> stopDiscovery() async {
    if (!_isDiscovering) return;
    _discoveredSub?.cancel();
    _discoveredSub = null;
    try {
      await _central.stopDiscovery();
    } catch (_) {}
    _isDiscovering = false;
    _discoveredMap.clear();
    _peripheralMap.clear();
  }

  void _onDiscovered(DiscoveredEventArgs e) {
    final id = e.peripheral.uuid.toString();
    final session = parseAdvertisement(id, e.advertisement.name);
    if (session == null) return;
    _peripheralMap[id] = e.peripheral;
    if (_discoveredMap[id]?.sessionName != session.sessionName) {
      _discoveredMap[id] = session;
      _discoveredCtrl
          .add(List.unmodifiable(_discoveredMap.values.toList()));
    }
  }

  void _onConnectionStateChanged(PeripheralConnectionStateChangedEventArgs e) {
    if (_hostPeripheral?.uuid.toString() != e.peripheral.uuid.toString()) return;
    if (e.state == ConnectionState.disconnected) {
      _hostPeripheral = null;
      _rxCharacteristic = null;
      _isConnected = false;
      _connCtrl.add(false);
    }
  }

  void _onCharacteristicNotified(GATTCharacteristicNotifiedEventArgs e) {
    final complete = _assembler.feed(e.value);
    if (complete == null) return;
    try {
      final msg = SyncMessage.fromJson(
          jsonDecode(utf8.decode(complete)) as Map<String, dynamic>);
      if (msg.type == SyncMessageType.sessionClosed) {
        _isSessionClosed = true;
        _isConnected = false;
        _sessionClosedCtrl.add(null);
      } else {
        _msgCtrl.add(msg);
      }
    } catch (_) {}
  }

  /// Connect to [endpointId] (a peripheral UUID string from [DiscoveredSession]),
  /// subscribe to TX notifications, then send [userInfo] to register with the host.
  Future<bool> connect({
    required String endpointId,
    required Map<String, dynamic> userInfo,
    String? myDeviceName,
  }) async {
    if (_isConnected) return true;

    final peripheral = _peripheralMap[endpointId];
    if (peripheral == null) return false;

    if (!_isDiscovering) await startDiscovery(myDeviceName: myDeviceName);

    // Wait for connectionStateChanged to confirm the link is up.
    final completer = Completer<bool>();
    StreamSubscription? sub;
    sub = _central.connectionStateChanged.listen((e) {
      if (e.peripheral.uuid.toString() != endpointId) return;
      if (completer.isCompleted) return;
      if (e.state == ConnectionState.connected) {
        sub?.cancel();
        completer.complete(true);
      } else if (e.state == ConnectionState.disconnected) {
        sub?.cancel();
        completer.complete(false);
      }
    });

    try {
      await _central.connect(peripheral);
    } catch (_) {
      sub.cancel();
      return false;
    }

    final connected = await completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        sub?.cancel();
        return false;
      },
    );
    if (!connected) return false;

    try {
      final services = await _central.discoverGATT(peripheral);

      final svcMatch = _serviceUuid.toString().toUpperCase();
      final service = services.firstWhere(
        (s) => s.uuid.toString().toUpperCase() == svcMatch,
        orElse: () =>
            throw Exception('Sushare GATT service not found on host device'),
      );

      final txMatch = _txUuid.toString().toUpperCase();
      final rxMatch = _rxUuid.toString().toUpperCase();
      final txChar = service.characteristics
          .firstWhere((c) => c.uuid.toString().toUpperCase() == txMatch);
      final rxChar = service.characteristics
          .firstWhere((c) => c.uuid.toString().toUpperCase() == rxMatch);

      // Subscribe to host notifications before writing so the host can respond.
      await _central.setCharacteristicNotifyState(
          peripheral, txChar,
          state: true);

      _hostPeripheral = peripheral;
      _rxCharacteristic = rxChar;
      _isConnected = true;
      _connCtrl.add(true);

      // Register with the host; it will reply with initialSync via notify.
      await _sendMsg(
          SyncMessage(type: SyncMessageType.userInfo, data: userInfo));

      return true;
    } catch (_) {
      try {
        await _central.disconnect(peripheral);
      } catch (_) {}
      return false;
    }
  }

  Future<void> _sendMsg(SyncMessage msg) async {
    final peripheral = _hostPeripheral;
    final rxChar = _rxCharacteristic;
    if (peripheral == null || rxChar == null) return;
    final bytes =
        Uint8List.fromList(utf8.encode(jsonEncode(msg.toJson())));
    for (final chunk in chunkBytes(bytes)) {
      try {
        await _central.writeCharacteristic(
          peripheral,
          rxChar,
          value: chunk,
          type: GATTCharacteristicWriteType.withResponse,
        );
      } catch (_) {
        break;
      }
    }
  }

  void pushSubOrderUpdate(PersonalSubOrder subOrder) {
    if (!_isConnected) return;
    final stripped = subOrder.copyWith(checklist: []);
    _sendMsg(SyncMessage(
        type: SyncMessageType.subOrderUpdate, data: stripped.toJson()));
  }

  void markSessionClosed() => _isSessionClosed = true;

  Future<void> disconnect() async {
    final peripheral = _hostPeripheral;
    _hostPeripheral = null;
    _rxCharacteristic = null;
    _isConnected = false;
    if (peripheral != null) {
      try {
        await _central.disconnect(peripheral);
      } catch (_) {}
    }
  }

  void dispose() {
    disconnect();
    stopDiscovery();
    _authorizeSub?.cancel();
    _connStateSub?.cancel();
    _notifiedSub?.cancel();
    _msgCtrl.close();
    _connCtrl.close();
    _sessionClosedCtrl.close();
    _discoveredCtrl.close();
  }
}
