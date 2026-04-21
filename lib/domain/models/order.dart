class Order {
  final String id;
  final String label;
  final List<OrderItem> items;
  final DateTime? createdAt;

  Order({
    required this.id,
    required this.label,
    required this.items,
    this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      label: json['label'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'items': items.map((e) => e.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  Order copyWith({
    String? id,
    String? label,
    List<OrderItem>? items,
    DateTime? createdAt,
  }) {
    return Order(
      id: id ?? this.id,
      label: label ?? this.label,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class OrderItem {
  final String menuItemId;
  final String name;
  final int quantity;
  final List<String> contributorIds;

  OrderItem({
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.contributorIds,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      menuItemId: json['menuItemId'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      contributorIds: (json['contributorIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'quantity': quantity,
      'contributorIds': contributorIds,
    };
  }

  OrderItem copyWith({
    String? menuItemId,
    String? name,
    int? quantity,
    List<String>? contributorIds,
  }) {
    return OrderItem(
      menuItemId: menuItemId ?? this.menuItemId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      contributorIds: contributorIds ?? this.contributorIds,
    );
  }
}
