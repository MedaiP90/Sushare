import 'dart:async';
import 'dart:convert';
import 'package:flutter_nearby_connections_plus/flutter_nearby_connections_plus.dart';
import '../domain/models/personal_sub_order.dart';
import '../domain/models/restaurant.dart';
import '../domain/models/session.dart';
import 'sync_message.dart';

/// Encodes session info into a BLE advertisement name (≤ 42 chars for iOS MCPeerID).
/// Format: "S|{8charId}|{name≤20}|{host≤10}"
String encodeAdvertisementName({
  required String sessionId,
  required String sessionName,
  required String hostName,
}) {
  final shortId = sessionId.substring(0, 8).toUpperCase();
  final name = sessionName.length > 20 ? sessionName.substring(0, 20) : sessionName;
  final host = hostName.length > 10 ? hostName.substring(0, 10) : hostName;
  return 'S|$shortId|$name|$host';
}

class HostBleService {
  NearbyService? _nearby;
  Session? _session;
  Restaurant? _restaurant;
  final _subOrders = <String, PersonalSubOrder>{};
  StreamSubscription? _stateSub;
  StreamSubscription? _dataSub;
  Set<String> _connectedIds = {};
  final _msgCtrl = StreamController<SyncMessage>.broadcast();

  bool _isRunning = false;

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

    final advName = encodeAdvertisementName(
      sessionId: sessionId,
      sessionName: sessionName,
      hostName: hostName,
    );

    _nearby = NearbyService();
    await _nearby!.init(
      serviceType: 'sushare',
      strategy: Strategy.P2P_STAR,
      deviceName: advName,
      callback: (isRunning) async {
        if (isRunning) await _nearby!.startAdvertisingPeer();
      },
    );

    _stateSub = _nearby!.stateChangedSubscription(callback: _onStateChanged);
    _dataSub = _nearby!.dataReceivedSubscription(callback: _onDataReceived);
    _isRunning = true;
  }

  void _onStateChanged(List<Device> devices) {
    final nowConnected = devices
        .where((d) => d.state == SessionState.connected)
        .map((d) => d.deviceId)
        .toSet();
    _connectedIds = nowConnected;
  }

  void _onDataReceived(dynamic data) {
    try {
      final msg = SyncMessage.fromJson(
          jsonDecode(data.message as String) as Map<String, dynamic>);
      _handleClientMessage(data.deviceId as String, msg);
    } catch (_) {}
  }

  void _handleClientMessage(String senderId, SyncMessage msg) {
    switch (msg.type) {
      case SyncMessageType.userInfo:
        if (_session == null || _session!.status == SessionStatus.closed) {
          _sendTo(senderId,
              const SyncMessage(type: SyncMessageType.sessionClosed, data: {}));
          return;
        }
        _sendTo(
          senderId,
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
          excludeId: senderId,
        );
        _msgCtrl.add(msg);

      default:
        break;
    }
  }

  void _sendTo(String endpointId, SyncMessage msg) {
    try {
      _nearby?.sendMessage(endpointId, jsonEncode(msg.toJson()));
    } catch (_) {}
  }

  void _broadcastExcept(SyncMessage msg, {String? excludeId}) {
    final json = jsonEncode(msg.toJson());
    for (final id in List.of(_connectedIds)) {
      if (id != excludeId) {
        try {
          _nearby?.sendMessage(id, json);
        } catch (_) {}
      }
    }
  }

  void broadcast(SyncMessage msg) => _broadcastExcept(msg);

  void broadcastSessionUpdate(Session session) {
    _session = session;
    broadcast(
        SyncMessage(type: SyncMessageType.sessionUpdate, data: session.toJson()));
  }

  void broadcastRestaurantUpdate(Restaurant restaurant) {
    _restaurant = restaurant;
    broadcast(SyncMessage(
        type: SyncMessageType.restaurantUpdate,
        data: restaurant.toJson()));
  }

  void sendSessionClosedToGuests() {
    broadcast(const SyncMessage(type: SyncMessageType.sessionClosed, data: {}));
    _connectedIds.clear();
  }

  Future<void> stop() async {
    if (!_isRunning) return;
    _stateSub?.cancel();
    _dataSub?.cancel();
    _stateSub = null;
    _dataSub = null;
    try {
      await _nearby?.stopAdvertisingPeer();
    } catch (_) {}
    _connectedIds.clear();
    _nearby = null;
    _isRunning = false;
  }

  void dispose() {
    stop();
    _msgCtrl.close();
  }
}
