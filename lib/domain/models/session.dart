import 'order.dart';

enum SessionStatus { open, sent, closed }

class Session {
  final String id;
  final String name;
  final String restaurantId;
  final String hostUserId;
  final List<String> participantIds;
  final SessionStatus status;
  final Order? mainOrder;
  final List<Order> additionalOrders;
  final Map<String, int> arrivedCounts;
  final DateTime createdAt;
  final DateTime? sentAt;

  Session({
    required this.id,
    required this.name,
    required this.restaurantId,
    required this.hostUserId,
    required this.participantIds,
    required this.status,
    this.mainOrder,
    required this.additionalOrders,
    this.arrivedCounts = const {},
    required this.createdAt,
    this.sentAt,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      name: json['name'] as String,
      restaurantId: json['restaurantId'] as String,
      hostUserId: json['hostUserId'] as String,
      participantIds: (json['participantIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      status: SessionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SessionStatus.open,
      ),
      mainOrder: json['mainOrder'] != null
          ? Order.fromJson(json['mainOrder'] as Map<String, dynamic>)
          : null,
      additionalOrders: (json['additionalOrders'] as List<dynamic>)
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList(),
      arrivedCounts: (json['arrivedCounts'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      sentAt: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'restaurantId': restaurantId,
      'hostUserId': hostUserId,
      'participantIds': participantIds,
      'status': status.name,
      'mainOrder': mainOrder?.toJson(),
      'additionalOrders': additionalOrders.map((e) => e.toJson()).toList(),
      'arrivedCounts': arrivedCounts,
      'createdAt': createdAt.toIso8601String(),
      'sentAt': sentAt?.toIso8601String(),
    };
  }

  Session copyWith({
    String? id,
    String? name,
    String? restaurantId,
    String? hostUserId,
    List<String>? participantIds,
    SessionStatus? status,
    Order? mainOrder,
    List<Order>? additionalOrders,
    Map<String, int>? arrivedCounts,
    DateTime? createdAt,
    DateTime? sentAt,
  }) {
    return Session(
      id: id ?? this.id,
      name: name ?? this.name,
      restaurantId: restaurantId ?? this.restaurantId,
      hostUserId: hostUserId ?? this.hostUserId,
      participantIds: participantIds ?? this.participantIds,
      status: status ?? this.status,
      mainOrder: mainOrder ?? this.mainOrder,
      additionalOrders: additionalOrders ?? this.additionalOrders,
      arrivedCounts: arrivedCounts ?? this.arrivedCounts,
      createdAt: createdAt ?? this.createdAt,
      sentAt: sentAt ?? this.sentAt,
    );
  }
}
