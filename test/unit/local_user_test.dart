import 'package:flutter_test/flutter_test.dart';
import 'package:sushare/domain/models/local_user.dart';

void main() {
  group('LocalUser', () {
    test('should create LocalUser with required fields', () {
      final user = LocalUser(
        id: 'test-id',
        username: 'testuser',
        firstName: 'Test',
        lastName: 'User',
        avatarIconCodePoint: 0xe25c,
        avatarColorValue: 0xFFE57373,
      );

      expect(user.id, 'test-id');
      expect(user.username, 'testuser');
      expect(user.firstName, 'Test');
      expect(user.lastName, 'User');
      expect(user.avatarIconCodePoint, 0xe25c);
      expect(user.avatarColorValue, 0xFFE57373);
      expect(user.createdAt, isNull);
    });

    test('should create LocalUser from JSON', () {
      final json = {
        'id': 'test-id',
        'username': 'testuser',
        'firstName': 'Test',
        'lastName': 'User',
        'avatarIconCodePoint': 0xe25c,
        'avatarColorValue': 0xFFE57373,
        'createdAt': '2024-01-01T00:00:00.000',
      };

      final user = LocalUser.fromJson(json);

      expect(user.id, 'test-id');
      expect(user.username, 'testuser');
      expect(user.firstName, 'Test');
      expect(user.lastName, 'User');
      expect(user.avatarIconCodePoint, 0xe25c);
      expect(user.avatarColorValue, 0xFFE57373);
      expect(user.createdAt, isNotNull);
    });

    test('should convert LocalUser to JSON', () {
      final user = LocalUser(
        id: 'test-id',
        username: 'testuser',
        firstName: 'Test',
        lastName: 'User',
        avatarIconCodePoint: 0xe25c,
        avatarColorValue: 0xFFE57373,
      );

      final json = user.toJson();

      expect(json['id'], 'test-id');
      expect(json['username'], 'testuser');
      expect(json['firstName'], 'Test');
      expect(json['lastName'], 'User');
      expect(json['avatarIconCodePoint'], 0xe25c);
      expect(json['avatarColorValue'], 0xFFE57373);
    });

    test('should copy LocalUser with updated fields', () {
      final original = LocalUser(
        id: 'test-id',
        username: 'testuser',
        firstName: 'Test',
        lastName: 'User',
        avatarIconCodePoint: 0xe25c,
        avatarColorValue: 0xFFE57373,
      );

      final updated = original.copyWith(
        firstName: 'Updated',
        username: 'updateduser',
      );

      expect(updated.id, original.id);
      expect(updated.firstName, 'Updated');
      expect(updated.username, 'updateduser');
      expect(updated.lastName, original.lastName);
    });
  });
}