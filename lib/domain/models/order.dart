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
  // userId → quantity that user personally ordered
  final Map<String, int> contributions;

  // Backward-compatible helper used in display ("contributed by N people")
  List<String> get contributorIds => contributions.keys.toList();

  OrderItem({
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.contributions,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    Map<String, int> contributions;
    if (json['contributions'] is Map) {
      final raw = json['contributions'] as Map<String, dynamic>;
      contributions = raw.map((k, v) => MapEntry(k, (v as num).toInt()));
    } else {
      // Legacy format: contributorIds list without per-user quantities
      final ids = (json['contributorIds'] as List<dynamic>).map((e) => e as String).toList();
      final perUser = ids.isEmpty ? 0 : (json['quantity'] as int) ~/ ids.length;
      contributions = {for (final id in ids) id: perUser};
    }
    return OrderItem(
      menuItemId: json['menuItemId'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      contributions: contributions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'quantity': quantity,
      'contributions': contributions,
    };
  }

  OrderItem copyWith({
    String? menuItemId,
    String? name,
    int? quantity,
    Map<String, int>? contributions,
  }) {
    return OrderItem(
      menuItemId: menuItemId ?? this.menuItemId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      contributions: contributions ?? this.contributions,
    );
  }
}
