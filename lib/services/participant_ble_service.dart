import 'dart:async';
import 'dart:convert';
import 'package:flutter_nearby_connections_plus/flutter_nearby_connections_plus.dart';
import '../domain/models/personal_sub_order.dart';
import 'sync_message.dart';

/// A nearby session discovered via BLE advertisement.
class DiscoveredSession {
  final String endpointId;
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

/// Parses a Sushare host advertisement name.
/// Expected format: "S|{8charId}|{sessionName}|{hostName}"
/// Returns null when the name does not match the format.
DiscoveredSession? parseAdvertisement(String endpointId, String deviceName) {
  final parts = deviceName.split('|');
  if (parts.length != 4 || parts[0] != 'S') return null;
  return DiscoveredSession(
    endpointId: endpointId,
    shortId: parts[1],
    sessionName: parts[2],
    hostName: parts[3],
  );
}

class ParticipantBleService {
  NearbyService? _nearby;
  String? _hostEndpointId;
  String? _pendingEndpointId;
  Map<String, dynamic>? _pendingUserInfo;
  Completer<bool>? _connectCompleter;

  StreamSubscription? _stateSub;
  StreamSubscription? _dataSub;

  final _msgCtrl = StreamController<SyncMessage>.broadcast();
  final _connCtrl = StreamController<bool>.broadcast();
  final _sessionClosedCtrl = StreamController<void>.broadcast();
  final _discoveredCtrl =
      StreamController<List<DiscoveredSession>>.broadcast();

  final _discoveredMap = <String, DiscoveredSession>{};

  bool _isConnected = false;
  bool _isSessionClosed = false;
  bool _isDiscovering = false;

  bool get isConnected => _isConnected;
  bool get isSessionClosed => _isSessionClosed;

  Stream<SyncMessage> get messages => _msgCtrl.stream;
  Stream<bool> get connectionStatus => _connCtrl.stream;
  Stream<void> get sessionClosed => _sessionClosedCtrl.stream;
  Stream<List<DiscoveredSession>> get discoveredSessions =>
      _discoveredCtrl.stream;

  Future<void> startDiscovery({String? myDeviceName}) async {
    if (_isDiscovering) return;
    _nearby = NearbyService();
    await _nearby!.init(
      serviceType: 'sushare',
      strategy: Strategy.P2P_STAR,
      deviceName: myDeviceName,
      callback: (isRunning) async {
        if (isRunning) await _nearby!.startBrowsingForPeers();
      },
    );
    _stateSub = _nearby!.stateChangedSubscription(callback: _onStateChanged);
    _dataSub = _nearby!.dataReceivedSubscription(callback: _onDataReceived);
    _isDiscovering = true;
  }

  Future<void> stopDiscovery() async {
    if (!_isDiscovering) return;
    try {
      await _nearby?.stopBrowsingForPeers();
    } catch (_) {}
    _isDiscovering = false;
    _discoveredMap.clear();
  }

  /// Initiates a BLE connection to [endpointId], sends [userInfo] once
  /// the connection is confirmed, then waits up to 15 s for the host to
  /// accept.  Returns true on success.
  Future<bool> connect({
    required String endpointId,
    required Map<String, dynamic> userInfo,
    String? myDeviceName,
  }) async {
    if (_isConnected) return true;

    // Ensure we're discovering so the underlying stack is running.
    if (!_isDiscovering) {
      await startDiscovery(myDeviceName: myDeviceName);
    }

    _pendingEndpointId = endpointId;
    _pendingUserInfo = userInfo;
    _connectCompleter = Completer<bool>();

    try {
      await _nearby!.invitePeer(
        deviceID: endpointId,
        deviceName: myDeviceName ?? '',
      );
    } catch (_) {
      _connectCompleter?.complete(false);
      _connectCompleter = null;
      return false;
    }

    return _connectCompleter!.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        _connectCompleter = null;
        return false;
      },
    );
  }

  void _onStateChanged(List<Device> devices) {
    bool discoveryChanged = false;

    for (final device in devices) {
      final id = device.deviceId;

      switch (device.state) {
        case SessionState.notConnected:
          // If this was our connected host, handle the drop.
          if (id == _hostEndpointId) {
            _hostEndpointId = null;
            _isConnected = false;
            _connCtrl.add(false);
          }
          // Track as a discovered session if it has a valid Sushare advertisement.
          final parsed = parseAdvertisement(id, device.deviceName);
          if (parsed != null && !_discoveredMap.containsKey(id)) {
            _discoveredMap[id] = parsed;
            discoveryChanged = true;
          }

        case SessionState.connected:
          if (id == _pendingEndpointId && !_isConnected) {
            _hostEndpointId = id;
            _isConnected = true;
            _connCtrl.add(true);
            // Send registration message to host.
            if (_pendingUserInfo != null) {
              _send(SyncMessage(
                  type: SyncMessageType.userInfo, data: _pendingUserInfo!));
              _pendingUserInfo = null;
            }
            _connectCompleter?.complete(true);
            _connectCompleter = null;
          }

        default:
          break;
      }
    }

    // Remove devices that disappeared from the scan entirely.
    final liveIds = devices.map((d) => d.deviceId).toSet();
    final gone = _discoveredMap.keys.where((k) => !liveIds.contains(k)).toList();
    if (gone.isNotEmpty) {
      gone.forEach(_discoveredMap.remove);
      discoveryChanged = true;
    }

    if (discoveryChanged) {
      _discoveredCtrl.add(List.unmodifiable(_discoveredMap.values.toList()));
    }
  }

  void _onDataReceived(dynamic data) {
    try {
      final msg = SyncMessage.fromJson(
          jsonDecode(data.message as String) as Map<String, dynamic>);
      if (msg.type == SyncMessageType.sessionClosed) {
        _isSessionClosed = true;
        _isConnected = false;
        _sessionClosedCtrl.add(null);
      } else {
        _msgCtrl.add(msg);
      }
    } catch (_) {}
  }

  void pushSubOrderUpdate(PersonalSubOrder subOrder) {
    if (!_isConnected) return;
    final stripped = subOrder.copyWith(checklist: []);
    _send(SyncMessage(
        type: SyncMessageType.subOrderUpdate, data: stripped.toJson()));
  }

  void _send(SyncMessage msg) {
    if (_hostEndpointId == null) return;
    try {
      _nearby?.sendMessage(_hostEndpointId!, jsonEncode(msg.toJson()));
    } catch (_) {}
  }

  void markSessionClosed() {
    _isSessionClosed = true;
  }

  Future<void> disconnect() async {
    _connectCompleter?.complete(false);
    _connectCompleter = null;
    if (_hostEndpointId != null) {
      try {
        await _nearby?.disconnectPeer(deviceID: _hostEndpointId!);
      } catch (_) {}
    }
    _hostEndpointId = null;
    _pendingEndpointId = null;
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    stopDiscovery();
    _stateSub?.cancel();
    _dataSub?.cancel();
    _msgCtrl.close();
    _connCtrl.close();
    _sessionClosedCtrl.close();
    _discoveredCtrl.close();
  }
}
