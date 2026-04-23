import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class HostServerService {
  HttpServer? _server;
  final _clients = <WebSocketChannel>[];
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Map<String, dynamic>? _sessionData;
  Map<String, dynamic>? _restaurantData;

  int get port => _server?.port ?? 0;
  bool get isRunning => _server != null;
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  void setSessionData(Map<String, dynamic> data) => _sessionData = data;
  void setRestaurantData(Map<String, dynamic> data) => _restaurantData = data;

  Future<int> start({int preferredPort = 8080}) async {
    if (_server != null) {
      return port;
    }

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, preferredPort);
    } catch (e) {
      try {
        _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
      } catch (e) {
        throw Exception('Could not start server: $e');
      }
    }

    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(_corsMiddleware())
        .addHandler(_router);

    shelf_io.serveRequests(_server!, handler);
    return port;
  }

  Handler get _router {
    return (Request request) {
      if (request.url.path == 'ws') {
        return _handleWebSocket(request);
      }
      if (request.url.path == 'api/session') {
        return _handleSessionApi(request);
      }
      if (request.url.path == 'api/restaurant') {
        return _handleRestaurantApi(request);
      }
      if (request.url.path == 'api/orders') {
        return _handleOrdersApi(request);
      }
      if (request.url.path == 'api/participants') {
        return _handleParticipantsApi(request);
      }
      if (request.url.path.startsWith('api/')) {
        return Response.notFound('Not found');
      }
      return Response.ok('Sushare Host Server Running');
    };
  }

  Middleware _corsMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders);
        }
        final response = await innerHandler(request);
        return response.change(headers: _corsHeaders);
      };
    };
  }

  Map<String, String> get _corsHeaders => {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      };

  Future<Response> _handleWebSocket(Request request) async {
    final socket = webSocketHandler((channel, protocol) {
      _clients.add(channel);
      channel.stream.listen((message) {
        try {
          final data = jsonDecode(message as String) as Map<String, dynamic>;
          _messageController.add(data);
        } catch (e) {
          // Invalid JSON
        }
      }, onDone: () {
        _clients.remove(channel);
      }, onError: (e) {
        _clients.remove(channel);
      });
    })(request);

    return socket;
  }

  Future<Response> _handleSessionApi(Request request) async {
    if (request.method == 'GET') {
      if (_sessionData == null) {
        return Response.internalServerError(body: 'Session data not ready');
      }
      return Response.ok(
        jsonEncode(_sessionData),
        headers: {'Content-Type': 'application/json'},
      );
    }
    return Response.badRequest(body: 'Method not allowed');
  }

  Future<Response> _handleRestaurantApi(Request request) async {
    if (request.method == 'GET') {
      if (_restaurantData == null) {
        return Response.notFound('Restaurant data not available');
      }
      return Response.ok(
        jsonEncode(_restaurantData),
        headers: {'Content-Type': 'application/json'},
      );
    }
    return Response.badRequest(body: 'Method not allowed');
  }

  Future<Response> _handleOrdersApi(Request request) async {
    if (request.method == 'GET') {
      return Response.ok(
        jsonEncode({'orders': []}),
        headers: {'Content-Type': 'application/json'},
      );
    }
    if (request.method == 'POST') {
      final body = await request.readAsString();
      try {
        final data = jsonDecode(body);
        _broadcast({'type': 'order_update', 'data': data});
        return Response.ok(
          jsonEncode({'success': true}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.badRequest(body: 'Invalid JSON');
      }
    }
    return Response.badRequest(body: 'Method not allowed');
  }

  Future<Response> _handleParticipantsApi(Request request) async {
    if (request.method == 'POST') {
      final body = await request.readAsString();
      try {
        final data = jsonDecode(body) as Map<String, dynamic>;
        final userId = data['userId'] as String?;
        if (userId == null) return Response.badRequest(body: 'Missing userId');

        // Update cached session data so subsequent GET /api/session includes the new participant
        if (_sessionData != null) {
          final participants = List<String>.from(_sessionData!['participantIds'] as List);
          if (!participants.contains(userId)) {
            participants.add(userId);
            _sessionData!['participantIds'] = participants;
          }
        }

        _messageController.add({'type': 'participant_joined', 'userId': userId});
        return Response.ok(
          jsonEncode({'success': true}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (_) {
        return Response.badRequest(body: 'Invalid JSON');
      }
    }
    return Response.badRequest(body: 'Method not allowed');
  }

  void _broadcast(Map<String, dynamic> message) {
    final json = jsonEncode(message);
    for (final client in _clients) {
      client.sink.add(json);
    }
  }

  void broadcastSessionUpdate(Map<String, dynamic> data) {
    _broadcast({'type': 'session_update', 'data': data});
  }

  void broadcastOrderUpdate(Map<String, dynamic> data) {
    _broadcast({'type': 'order_update', 'data': data});
  }

  Future<void> stop() async {
    for (final client in _clients) {
      await client.sink.close();
    }
    _clients.clear();
    await _server?.close(force: true);
    _server = null;
  }

  void dispose() {
    stop();
    _messageController.close();
  }
}
