enum SyncMessageType {
  // guest → host
  userInfo,
  subOrderUpdate,
  requestSync,   // guest asks host to re-send initialSync (e.g. on re-entry)
  // host → guests
  initialSync,
  sessionUpdate,
  restaurantUpdate,
  subOrderBroadcast,
  sessionClosed,
}

class SyncMessage {
  final SyncMessageType type;
  final Map<String, dynamic> data;

  const SyncMessage({required this.type, required this.data});

  factory SyncMessage.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    final type = SyncMessageType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => throw FormatException('Unknown sync message type: $typeStr'),
    );
    return SyncMessage(
      type: type,
      data: (json['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toJson() => {'type': type.name, 'data': data};
}
