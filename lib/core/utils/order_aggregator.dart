import 'package:uuid/uuid.dart';
import '../../domain/models/order.dart';
import '../../domain/models/personal_sub_order.dart';

Order aggregateSubOrders(List<PersonalSubOrder> subOrders, String label) {
  final itemMap = <String, OrderItem>{};

  for (final subOrder in subOrders) {
    for (final entry in subOrder.entries) {
      final existing = itemMap[entry.menuItemId];

      itemMap[entry.menuItemId] = existing == null
          ? OrderItem(
              menuItemId: entry.menuItemId,
              name: entry.name,
              quantity: entry.quantity,
              contributions: {subOrder.userId: entry.quantity},
            )
          : existing.copyWith(
              quantity: existing.quantity + entry.quantity,
              contributions: {
                ...existing.contributions,
                subOrder.userId: entry.quantity,
              },
            );
    }
  }

  return Order(
    id: const Uuid().v4(),
    label: label,
    items: itemMap.values.toList(),
    createdAt: DateTime.now(),
  );
}
