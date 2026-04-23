import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../domain/models/personal_sub_order.dart';
import 'sync_message.dart';

class SessionClientService {
  WebSocketChannel? _wsChannel;
  final _messageController = StreamController<SyncMessage>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  bool _isConnected = false;
  String? _hostAddress;
  Map<String, dynamic>? _pendingUserInfo;

  bool get isConnected => _isConnected;
  Stream<SyncMessage> get messages => _messageController.stream;
  Stream<bool> get connectionStatus => _connectionController.stream;

  Future<bool> connect({
    required String hostAddress,
    required String userId,
    required String userName,
    String? userFullName,
    String? userProfilePicturePath,
  }) async {
    _hostAddress = hostAddress;
    _pendingUserInfo = {
      'userId': userId,
      'userName': userName,
      'userFullName': userFullName,
      'userProfilePicturePath': userProfilePicturePath,
    };
    return _doConnect();
  }

  Future<bool> reconnect() async => _doConnect();

  Future<bool> _doConnect() async {
    if (_hostAddress == null) return false;
    _wsChannel?.sink.close();

    try {
      final wsUrl = 'ws://$_hostAddress/ws';
      _wsChannel = WebSocketChannel.connect(Uri.parse(wsUrl));
      await _wsChannel!.ready;

      _wsChannel!.stream.listen(
        (raw) {
          try {
            final json = jsonDecode(raw as String) as Map<String, dynamic>;
            final msg = SyncMessage.fromJson(json);
            _messageController.add(msg);
          } catch (_) {}
        },
        onDone: () {
          _isConnected = false;
          _connectionController.add(false);
        },
        onError: (_) {
          _isConnected = false;
          _connectionController.add(false);
        },
      );

      if (_pendingUserInfo != null) {
        _send(SyncMessage(type: SyncMessageType.userInfo, data: _pendingUserInfo!));
      }

      _isConnected = true;
      _connectionController.add(true);
      return true;
    } catch (_) {
      _isConnected = false;
      _connectionController.add(false);
      return false;
    }
  }

  void pushSubOrderUpdate(PersonalSubOrder subOrder) {
    if (!_isConnected) return;
    _send(SyncMessage(type: SyncMessageType.subOrderUpdate, data: subOrder.toJson()));
  }

  void _send(SyncMessage message) {
    try {
      _wsChannel?.sink.add(jsonEncode(message.toJson()));
    } catch (_) {}
  }

  void disconnect() {
    _wsChannel?.sink.close();
    _wsChannel = null;
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
  }
}
