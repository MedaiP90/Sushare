import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../domain/models/personal_sub_order.dart';
import '../domain/models/restaurant.dart';
import '../domain/models/session.dart';
import 'sync_message.dart';

class _Client {
  final WebSocketChannel channel;
  String userId;
  _Client({required this.channel, required this.userId});
}

class HostServerService {
  HttpServer? _server;
  final _clients = <_Client>[];
  final _messageController = StreamController<SyncMessage>.broadcast();

  Session? _session;
  Restaurant? _restaurant;
  final _subOrders = <String, PersonalSubOrder>{};

  int get port => _server?.port ?? 0;
  bool get isRunning => _server != null;
  Stream<SyncMessage> get messages => _messageController.stream;

  void setSession(Session session) => _session = session;
  void setRestaurant(Restaurant restaurant) => _restaurant = restaurant;

  void upsertSubOrder(PersonalSubOrder subOrder) =>
      _subOrders[subOrder.userId] = subOrder;

  void clearSubOrders() => _subOrders.clear();

  Future<int> start({int preferredPort = 8080}) async {
    if (_server != null) return port;
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, preferredPort);
    } catch (_) {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    }
    final handler = const Pipeline()
        .addMiddleware(_corsMiddleware())
        .addHandler(_router);
    shelf_io.serveRequests(_server!, handler);
    return port;
  }

  Handler get _router => (Request request) {
        final path = request.url.path;
        if (path == 'ws') return _wsHandler(request);
        if (path == 'api/session') return _sessionApiHandler(request);
        if (path == 'api/restaurant') return _restaurantApiHandler(request);
        return Response.ok('Sushare Host');
      };

  FutureOr<Response> _wsHandler(Request request) {
    return webSocketHandler((WebSocketChannel channel, String? _) {
      final client = _Client(channel: channel, userId: '');
      _clients.add(client);

      channel.stream.listen(
        (raw) {
          try {
            final json = jsonDecode(raw as String) as Map<String, dynamic>;
            final msg = SyncMessage.fromJson(json);
            _handleClientMessage(client, msg);
          } catch (_) {}
        },
        onDone: () => _clients.remove(client),
        onError: (_) => _clients.remove(client),
      );
    })(request);
  }

  void _handleClientMessage(_Client client, SyncMessage msg) {
    switch (msg.type) {
      case SyncMessageType.userInfo:
        final userId = msg.data['userId'] as String? ?? '';
        client.userId = userId;
        _sendTo(client.channel, SyncMessage(
          type: SyncMessageType.initialSync,
          data: {
            if (_session != null) 'session': _session!.toJson(),
            if (_restaurant != null) 'restaurant': _restaurant!.toJson(),
            'subOrders': _subOrders.values.map((o) => o.toJson()).toList(),
          },
        ));
        // Notify host app so it can add the participant to the session
        _messageController.add(msg);
      case SyncMessageType.subOrderUpdate:
        final subOrder = PersonalSubOrder.fromJson(msg.data);
        _subOrders[subOrder.userId] = subOrder;
        // Forward to all other connected guests
        _broadcastExcept(
          SyncMessage(type: SyncMessageType.subOrderBroadcast, data: msg.data),
          exclude: client.channel,
        );
        // Notify host app so it can persist to DB
        _messageController.add(msg);
      default:
        break;
    }
  }

  void _sendTo(WebSocketChannel channel, SyncMessage msg) {
    try {
      channel.sink.add(jsonEncode(msg.toJson()));
    } catch (_) {}
  }

  void _broadcastExcept(SyncMessage msg, {WebSocketChannel? exclude}) {
    final json = jsonEncode(msg.toJson());
    for (final c in List.of(_clients)) {
      if (c.channel != exclude) {
        try {
          c.channel.sink.add(json);
        } catch (_) {}
      }
    }
  }

  void broadcast(SyncMessage msg) => _broadcastExcept(msg);

  void broadcastSessionUpdate(Session session) {
    _session = session;
    broadcast(SyncMessage(type: SyncMessageType.sessionUpdate, data: session.toJson()));
  }

  void broadcastRestaurantUpdate(Restaurant restaurant) {
    _restaurant = restaurant;
    broadcast(SyncMessage(type: SyncMessageType.restaurantUpdate, data: restaurant.toJson()));
  }

  Future<Response> _sessionApiHandler(Request request) async {
    if (request.method != 'GET') return Response.badRequest(body: 'Method not allowed');
    if (_session == null) return Response.internalServerError(body: 'Not ready');
    return Response.ok(
      jsonEncode(_session!.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _restaurantApiHandler(Request request) async {
    if (request.method != 'GET') return Response.badRequest(body: 'Method not allowed');
    if (_restaurant == null) return Response.notFound('Not available');
    return Response.ok(
      jsonEncode(_restaurant!.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Middleware _corsMiddleware() {
    return (Handler inner) => (Request req) async {
          if (req.method == 'OPTIONS') {
            return Response.ok('', headers: _corsHeaders);
          }
          final res = await inner(req);
          return res.change(headers: _corsHeaders);
        };
  }

  static const _corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  };

  Future<void> stop() async {
    for (final c in List.of(_clients)) {
      await c.channel.sink.close();
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
