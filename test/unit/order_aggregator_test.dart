import 'package:flutter_test/flutter_test.dart';
import 'package:sushare/domain/models/order.dart';
import 'package:sushare/domain/models/personal_sub_order.dart';
import 'package:sushare/core/utils/order_aggregator.dart';

void main() {
  group('Order Aggregator', () {
    test('should aggregate empty orders', () {
      final result = aggregateSubOrders([], 'Main Order');
      
      expect(result.label, 'Main Order');
      expect(result.items, isEmpty);
    });

    test('should aggregate single order', () {
      final subOrders = [
        PersonalSubOrder(
          id: 'order-1',
          sessionId: 'session-1',
          userId: 'user-1',
          entries: [
            SubOrderEntry(menuItemId: 'item-1', name: 'Pizza', quantity: 2),
            SubOrderEntry(menuItemId: 'item-2', name: 'Pasta', quantity: 1),
          ],
          checklist: [],
          locked: true,
          updatedAt: DateTime.now(),
        ),
      ];

      final result = aggregateSubOrders(subOrders, 'Main Order');

      expect(result.label, 'Main Order');
      expect(result.items.length, 2);
      expect(result.items[0].menuItemId, 'item-1');
      expect(result.items[0].quantity, 2);
      expect(result.items[0].contributorIds, ['user-1']);
    });

    test('should merge orders with same items', () {
      final subOrders = [
        PersonalSubOrder(
          id: 'order-1',
          sessionId: 'session-1',
          userId: 'user-1',
          entries: [
            SubOrderEntry(menuItemId: 'item-1', name: 'Pizza', quantity: 2),
          ],
          checklist: [],
          locked: true,
          updatedAt: DateTime.now(),
        ),
        PersonalSubOrder(
          id: 'order-2',
          sessionId: 'session-1',
          userId: 'user-2',
          entries: [
            SubOrderEntry(menuItemId: 'item-1', name: 'Pizza', quantity: 3),
          ],
          checklist: [],
          locked: true,
          updatedAt: DateTime.now(),
        ),
      ];

      final result = aggregateSubOrders(subOrders, 'Main Order');

      expect(result.items.length, 1);
      expect(result.items[0].menuItemId, 'item-1');
      expect(result.items[0].quantity, 5);
      expect(result.items[0].contributorIds, ['user-1', 'user-2']);
    });

    test('should handle mixed items from different orders', () {
      final subOrders = [
        PersonalSubOrder(
          id: 'order-1',
          sessionId: 'session-1',
          userId: 'user-1',
          entries: [
            SubOrderEntry(menuItemId: 'item-1', name: 'Pizza', quantity: 1),
            SubOrderEntry(menuItemId: 'item-2', name: 'Pasta', quantity: 1),
          ],
          checklist: [],
          locked: true,
          updatedAt: DateTime.now(),
        ),
        PersonalSubOrder(
          id: 'order-2',
          sessionId: 'session-1',
          userId: 'user-2',
          entries: [
            SubOrderEntry(menuItemId: 'item-2', name: 'Pasta', quantity: 2),
            SubOrderEntry(menuItemId: 'item-3', name: 'Salad', quantity: 1),
          ],
          checklist: [],
          locked: true,
          updatedAt: DateTime.now(),
        ),
      ];

      final result = aggregateSubOrders(subOrders, 'Main Order');

      expect(result.items.length, 3);
      
      final pizza = result.items.firstWhere((i) => i.menuItemId == 'item-1');
      expect(pizza.quantity, 1);
      expect(pizza.contributorIds, ['user-1']);
      
      final pasta = result.items.firstWhere((i) => i.menuItemId == 'item-2');
      expect(pasta.quantity, 3);
      expect(pasta.contributorIds, ['user-1', 'user-2']);
      
      final salad = result.items.firstWhere((i) => i.menuItemId == 'item-3');
      expect(salad.quantity, 1);
      expect(salad.contributorIds, ['user-2']);
    });
  });
}