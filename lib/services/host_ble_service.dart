import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';

import '../domain/models/personal_sub_order.dart';
import '../domain/models/restaurant.dart';
import '../domain/models/session.dart';
import 'ble_framing.dart';
import 'sync_message.dart';

// Custom 128-bit UUIDs for the Sushare BLE GATT service.
final _serviceUuid = UUID.fromString('19B10000-E8F2-537E-4F6C-D104768A1214');
// TX: host → participant (notify characteristic)
final _txUuid = UUID.fromString('19B10001-E8F2-537E-4F6C-D104768A1214');
// RX: participant → host (write characteristic)
final _rxUuid = UUID.fromString('19B10002-E8F2-537E-4F6C-D104768A1214');

/// Encodes session info into a BLE advertisement local name (≤ 36 chars).
/// Format: "S|{8charId}|{name≤16}|{host≤8}"
String encodeAdvertisementName({
  required String sessionId,
  required String sessionName,
  required String hostName,
}) {
  final shortId = sessionId.substring(0, 8).toUpperCase();
  final name =
      sessionName.length > 16 ? sessionName.substring(0, 16) : sessionName;
  final host = hostName.length > 8 ? hostName.substring(0, 8) : hostName;
  return 'S|$shortId|$name|$host';
}

class HostBleService {
  final _peripheral = PeripheralManager();

  Session? _session;
  Restaurant? _restaurant;
  final _subOrders = <String, PersonalSubOrder>{};

  // Keyed by Central UUID string. Only centrals that have subscribed to
  // TX notifications are tracked here so notifyCharacteristic succeeds.
  final _connectedCentrals = <String, Central>{};
  final _centralAssemblers = <String, ChunkAssembler>{};

  GATTCharacteristic? _txCharacteristic;

  StreamSubscription? _writesSub;
  StreamSubscription? _notifyStateSub;
  StreamSubscription? _authorizeSub;

  final _msgCtrl = StreamController<SyncMessage>.broadcast();
  bool _isRunning = false;

  HostBleService() {
    _authorizeSub = _peripheral.stateChanged.listen((e) async {
      if (e.state == BluetoothLowEnergyState.unauthorized &&
          Platform.isAndroid) {
        await _peripheral.authorize();
      }
    });
  }

  Future<bool> _waitForPoweredOn() async {
    if (_peripheral.state == BluetoothLowEnergyState.poweredOn) return true;
    if (_peripheral.state == BluetoothLowEnergyState.unauthorized &&
        Platform.isAndroid) {
      await _peripheral.authorize();
      if (_peripheral.state == BluetoothLowEnergyState.poweredOn) return true;
    }
    try {
      await _peripheral.stateChanged
          .where((e) => e.state == BluetoothLowEnergyState.poweredOn)
          .first
          .timeout(const Duration(seconds: 15));
      return true;
    } catch (_) {
      return false;
    }
  }

  bool get isRunning => _isRunning;
  Stream<SyncMessage> get messages => _msgCtrl.stream;

  void setSession(Session session) => _session = session;
  void setRestaurant(Restaurant restaurant) => _restaurant = restaurant;

  void upsertSubOrder(PersonalSubOrder subOrder) =>
      _subOrders[subOrder.userId] = subOrder.copyWith(checklist: []);

  void clearSubOrders() => _subOrders.clear();

  Future<void> start({
    required String sessionId,
    required String sessionName,
    required String hostName,
  }) async {
    if (_isRunning) return;
    if (!await _waitForPoweredOn()) return;

    final txChar = GATTCharacteristic.mutable(
      uuid: _txUuid,
      properties: [GATTCharacteristicProperty.notify],
      permissions: [GATTCharacteristicPermission.read],
      descriptors: [],
    );
    _txCharacteristic = txChar;

    final rxChar = GATTCharacteristic.mutable(
      uuid: _rxUuid,
      properties: [
        GATTCharacteristicProperty.write,
        GATTCharacteristicProperty.writeWithoutResponse,
      ],
      permissions: [GATTCharacteristicPermission.write],
      descriptors: [],
    );

    await _peripheral.removeAllServices();
    await _peripheral.addService(GATTService(
      uuid: _serviceUuid,
      isPrimary: true,
      includedServices: [],
      characteristics: [txChar, rxChar],
    ));

    _writesSub =
        _peripheral.characteristicWriteRequested.listen(_onWrite);
    _notifyStateSub = _peripheral.characteristicNotifyStateChanged
        .listen(_onNotifyStateChanged);

    await _peripheral.startAdvertising(Advertisement(
      name: encodeAdvertisementName(
        sessionId: sessionId,
        sessionName: sessionName,
        hostName: hostName,
      ),
      serviceUUIDs: [_serviceUuid],
    ));

    _isRunning = true;
  }

  void _onNotifyStateChanged(
      GATTCharacteristicNotifyStateChangedEventArgs e) {
    final id = e.central.uuid.toString();
    if (e.state) {
      _connectedCentrals[id] = e.central;
      _centralAssemblers.putIfAbsent(id, ChunkAssembler.new);
    } else {
      _connectedCentrals.remove(id);
      _centralAssemblers.remove(id);
    }
  }

  void _onWrite(GATTCharacteristicWriteRequestedEventArgs e) {
    // Always respond to write-with-response so the central doesn't time out.
    _peripheral.respondWriteRequest(e.request).catchError((_) {});

    final id = e.central.uuid.toString();
    final assembler =
        _centralAssemblers.putIfAbsent(id, ChunkAssembler.new);
    final complete = assembler.feed(e.request.value);
    if (complete == null) return;
    try {
      final msg = SyncMessage.fromJson(
          jsonDecode(utf8.decode(complete)) as Map<String, dynamic>);
      _handleClientMessage(id, e.central, msg);
    } catch (_) {}
  }

  void _handleClientMessage(
      String centralId, Central central, SyncMessage msg) {
    // Track the central even if the notify-state event arrived slightly late.
    _connectedCentrals.putIfAbsent(centralId, () => central);

    switch (msg.type) {
      case SyncMessageType.userInfo:
        if (_session == null || _session!.status == SessionStatus.closed) {
          _sendTo(central,
              const SyncMessage(type: SyncMessageType.sessionClosed, data: {}));
          return;
        }
        _sendTo(
          central,
          SyncMessage(
            type: SyncMessageType.initialSync,
            data: {
              if (_session != null) 'session': _session!.toJson(),
              if (_restaurant != null) 'restaurant': _restaurant!.toJson(),
              'subOrders':
                  _subOrders.values.map((o) => o.toJson()).toList(),
            },
          ),
        );
        _msgCtrl.add(msg);

      case SyncMessageType.subOrderUpdate:
        final subOrder = PersonalSubOrder.fromJson(msg.data);
        final stripped = subOrder.copyWith(checklist: []);
        _subOrders[stripped.userId] = stripped;
        _broadcastExcept(
          SyncMessage(
              type: SyncMessageType.subOrderBroadcast,
              data: stripped.toJson()),
          excludeId: centralId,
        );
        _msgCtrl.add(msg);

      default:
        break;
    }
  }

  void _sendTo(Central central, SyncMessage msg) {
    if (_txCharacteristic == null) return;
    final bytes =
        Uint8List.fromList(utf8.encode(jsonEncode(msg.toJson())));
    _sendChunks(central, bytes);
  }

  // Sends chunks sequentially so the BLE stack is not overwhelmed.
  // Payload size per chunk is derived from the negotiated MTU for this central.
  Future<void> _sendChunks(Central central, Uint8List bytes) async {
    int payloadSize = defaultChunkPayloadSize;
    try {
      final maxNotify = await _peripheral.getMaximumNotifyLength(central);
      payloadSize = (maxNotify - 4).clamp(20, 512);
    } catch (_) {}

    for (final chunk in chunkBytes(bytes, payloadSize: payloadSize)) {
      try {
        await _peripheral.notifyCharacteristic(
            central, _txCharacteristic!,
            value: chunk);
      } catch (_) {
        break;
      }
    }
  }

  void _broadcastExcept(SyncMessage msg, {String? excludeId}) {
    final bytes =
        Uint8List.fromList(utf8.encode(jsonEncode(msg.toJson())));
    for (final entry in List.of(_connectedCentrals.entries)) {
      if (entry.key != excludeId) {
        _sendChunks(entry.value, bytes);
      }
    }
  }

  void broadcast(SyncMessage msg) => _broadcastExcept(msg);

  void broadcastSessionUpdate(Session session) {
    _session = session;
    broadcast(SyncMessage(
        type: SyncMessageType.sessionUpdate, data: session.toJson()));
  }

  void broadcastRestaurantUpdate(Restaurant restaurant) {
    _restaurant = restaurant;
    broadcast(SyncMessage(
        type: SyncMessageType.restaurantUpdate,
        data: restaurant.toJson()));
  }

  void sendSessionClosedToGuests() {
    broadcast(
        const SyncMessage(type: SyncMessageType.sessionClosed, data: {}));
    _connectedCentrals.clear();
    _centralAssemblers.clear();
  }

  Future<void> stop() async {
    if (!_isRunning) return;
    _writesSub?.cancel();
    _notifyStateSub?.cancel();
    _writesSub = null;
    _notifyStateSub = null;
    try {
      await _peripheral.stopAdvertising();
      await _peripheral.removeAllServices();
    } catch (_) {}
    _connectedCentrals.clear();
    _centralAssemblers.clear();
    _txCharacteristic = null;
    _isRunning = false;
  }

  void dispose() {
    stop();
    _authorizeSub?.cancel();
    _msgCtrl.close();
  }
}
