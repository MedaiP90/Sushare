import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../models/personal_sub_order.dart';
import '../../data/database/app_database.dart';

class PersonalSubOrderRepository {
  Future<PersonalSubOrder?> getSubOrder(String sessionId, String userId) async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'personal_sub_orders',
      where: 'session_id = ? AND user_id = ?',
      whereArgs: [sessionId, userId],
    );
    if (results.isEmpty) return null;
    return _subOrderFromRow(results.first);
  }

  Future<void> saveSubOrder(PersonalSubOrder subOrder) async {
    final db = await AppDatabase.database;
    await db.insert(
      'personal_sub_orders',
      _subOrderToRow(subOrder),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateSubOrder(PersonalSubOrder subOrder) async {
    final db = await AppDatabase.database;
    await db.update(
      'personal_sub_orders',
      _subOrderToRow(subOrder),
      where: 'id = ?',
      whereArgs: [subOrder.id],
    );
  }

  Future<List<PersonalSubOrder>> getSubOrdersForSession(String sessionId) async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'personal_sub_orders',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
    return results.map((row) => _subOrderFromRow(row)).toList();
  }

  Future<void> deleteSubOrder(String id) async {
    final db = await AppDatabase.database;
    await db.delete('personal_sub_orders', where: 'id = ?', whereArgs: [id]);
  }

  Map<String, dynamic> _subOrderToRow(PersonalSubOrder subOrder) {
    return {
      'id': subOrder.id,
      'session_id': subOrder.sessionId,
      'user_id': subOrder.userId,
      'user_name': subOrder.userName,
      'user_full_name': subOrder.userFullName,
      'user_profile_picture_path': subOrder.userProfilePicturePath,
      'entries_json': jsonEncode(subOrder.entries.map((e) => e.toJson()).toList()),
      'checklist_json': jsonEncode(subOrder.checklist.map((e) => e.toJson()).toList()),
      'locked': subOrder.locked ? 1 : 0,
      'updated_at': subOrder.updatedAt.toIso8601String(),
    };
  }

  PersonalSubOrder _subOrderFromRow(Map<String, dynamic> row) {
    return PersonalSubOrder(
      id: row['id'] as String,
      sessionId: row['session_id'] as String,
      userId: row['user_id'] as String,
      userName: row['user_name'] as String?,
      userFullName: row['user_full_name'] as String?,
      userProfilePicturePath: row['user_profile_picture_path'] as String?,
      entries: (jsonDecode(row['entries_json'] as String) as List)
          .map((e) => SubOrderEntry.fromJson(e))
          .toList(),
      checklist: (jsonDecode(row['checklist_json'] as String) as List)
          .map((e) => ChecklistEntry.fromJson(e))
          .toList(),
      locked: (row['locked'] as int) == 1,
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}