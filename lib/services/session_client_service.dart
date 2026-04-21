import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SessionClientService {
  final Dio _httpClient;
  WebSocketChannel? _wsChannel;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  
  String? _hostAddress;
  String? _sessionId;
  bool _isConnected = false;

  SessionClientService() : _httpClient = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  bool get isConnected => _isConnected;
  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  Stream<bool> get connectionStatus => _connectionController.stream;
  String? get hostAddress => _hostAddress;
  String? get sessionId => _sessionId;

  Future<bool> connect(String hostAddress, String sessionId) async {
    _hostAddress = hostAddress;
    _sessionId = sessionId;

    try {
      final baseUrl = hostAddress.startsWith('http') ? hostAddress : 'http://$hostAddress';
      
      final response = await _httpClient.get('$baseUrl/api/session');
      if (response.statusCode != 200) {
        return false;
      }

      final wsUrl = hostAddress.startsWith('ws') 
          ? hostAddress 
          : 'ws://$hostAddress/ws';
      
      _wsChannel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      await _wsChannel!.ready;
      
      _wsChannel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message as String) as Map<String, dynamic>;
            _messageController.add(data);
          } catch (e) {
            // Invalid JSON
          }
        },
        onDone: () {
          _isConnected = false;
          _connectionController.add(false);
        },
        onError: (e) {
          _isConnected = false;
          _connectionController.add(false);
        },
      );

      _isConnected = true;
      _connectionController.add(true);
      return true;
    } catch (e) {
      _isConnected = false;
      _connectionController.add(false);
      return false;
    }
  }

  Future<void> sendOrder(Map<String, dynamic> orderData) async {
    if (!_isConnected || _hostAddress == null || _sessionId == null) {
      throw Exception('Not connected');
    }

    final baseUrl = _hostAddress!.startsWith('http') 
        ? _hostAddress! 
        : 'http://$_hostAddress!';

    await _httpClient.post(
      '$baseUrl/api/orders',
      data: jsonEncode({
        'sessionId': _sessionId,
        ...orderData,
      }),
    );
  }

  Future<Map<String, dynamic>?> getSessionInfo() async {
    if (_hostAddress == null) return null;

    final baseUrl = _hostAddress!.startsWith('http') 
        ? _hostAddress! 
        : 'http://$_hostAddress!';

    try {
      final response = await _httpClient.get('$baseUrl/api/session');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      // Error
    }
    return null;
  }

  void disconnect() {
    _wsChannel?.sink.close();
    _wsChannel = null;
    _isConnected = false;
    _connectionController.add(false);
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
    _httpClient.close();
  }
}
