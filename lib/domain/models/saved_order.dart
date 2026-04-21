import 'personal_sub_order.dart';

class SavedOrder {
  final String id;
  final String restaurantId;
  final String label;
  final List<SubOrderEntry> entries;
  final DateTime createdAt;

  SavedOrder({
    required this.id,
    required this.restaurantId,
    required this.label,
    required this.entries,
    required this.createdAt,
  });

  factory SavedOrder.fromJson(Map<String, dynamic> json) {
    return SavedOrder(
      id: json['id'] as String,
      restaurantId: json['restaurantId'] as String,
      label: json['label'] as String,
      entries: (json['entries'] as List<dynamic>)
          .map((e) => SubOrderEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'label': label,
      'entries': entries.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
