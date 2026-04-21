import 'package:flutter_test/flutter_test.dart';
import 'package:sushare/domain/models/order.dart';
import 'package:sushare/domain/models/session.dart';

void main() {
  group('Order', () {
    test('should create Order with items', () {
      final order = Order(
        id: 'order-1',
        label: 'Main Order',
        items: [
          OrderItem(
            menuItemId: 'item-1',
            name: 'Pizza',
            quantity: 2,
            contributorIds: ['user-1'],
          ),
        ],
      );

      expect(order.id, 'order-1');
      expect(order.label, 'Main Order');
      expect(order.items.length, 1);
      expect(order.items[0].name, 'Pizza');
    });

    test('should convert Order to JSON', () {
      final order = Order(
        id: 'order-1',
        label: 'Main Order',
        items: [
          OrderItem(
            menuItemId: 'item-1',
            name: 'Pizza',
            quantity: 2,
            contributorIds: ['user-1'],
          ),
        ],
        createdAt: DateTime(2024, 1, 1),
      );

      final json = order.toJson();

      expect(json['id'], 'order-1');
      expect(json['label'], 'Main Order');
      expect(json['items'], isA<List>());
    });

    test('should create Order from JSON', () {
      final json = {
        'id': 'order-1',
        'label': 'Main Order',
        'items': [
          {
            'menuItemId': 'item-1',
            'name': 'Pizza',
            'quantity': 2,
            'contributorIds': ['user-1'],
          },
        ],
        'createdAt': '2024-01-01T00:00:00.000',
      };

      final order = Order.fromJson(json);

      expect(order.id, 'order-1');
      expect(order.label, 'Main Order');
      expect(order.items.length, 1);
      expect(order.items[0].name, 'Pizza');
    });

    test('should copy Order with updated fields', () {
      final original = Order(
        id: 'order-1',
        label: 'Main Order',
        items: [],
      );

      final updated = original.copyWith(
        label: 'Round 2',
      );

      expect(updated.id, original.id);
      expect(updated.label, 'Round 2');
    });
  });

  group('Session', () {
    test('should create Session with participants', () {
      final session = Session(
        id: 'session-1',
        name: 'Dinner',
        restaurantId: 'restaurant-1',
        hostUserId: 'user-1',
        participantIds: ['user-1', 'user-2'],
        status: SessionStatus.open,
        additionalOrders: [],
        createdAt: DateTime.now(),
      );

      expect(session.id, 'session-1');
      expect(session.name, 'Dinner');
      expect(session.status, SessionStatus.open);
      expect(session.participantIds.length, 2);
    });

    test('should copy Session with sent status', () {
      final original = Session(
        id: 'session-1',
        name: 'Dinner',
        restaurantId: 'restaurant-1',
        hostUserId: 'user-1',
        participantIds: ['user-1'],
        status: SessionStatus.open,
        additionalOrders: [],
        createdAt: DateTime.now(),
      );

      final sent = original.copyWith(
        status: SessionStatus.sent,
        sentAt: DateTime.now(),
      );

      expect(sent.status, SessionStatus.sent);
      expect(sent.sentAt, isNotNull);
    });

    test('should serialize Session to JSON', () {
      final session = Session(
        id: 'session-1',
        name: 'Dinner',
        restaurantId: 'restaurant-1',
        hostUserId: 'user-1',
        participantIds: ['user-1', 'user-2'],
        status: SessionStatus.open,
        additionalOrders: [],
        createdAt: DateTime(2024, 1, 1),
      );

      final json = session.toJson();

      expect(json['id'], 'session-1');
      expect(json['status'], 'open');
      expect(json['participantIds'], ['user-1', 'user-2']);
    });
  });
}