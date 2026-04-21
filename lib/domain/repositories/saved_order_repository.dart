import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../models/saved_order.dart';
import '../models/personal_sub_order.dart';
import '../../data/database/app_database.dart';

class SavedOrderRepository {
  Future<List<SavedOrder>> getAllSavedOrders() async {
    final db = await AppDatabase.database;
    final results = await db.query('saved_orders', orderBy: 'created_at DESC');
    return results.map((row) => _savedOrderFromRow(row)).toList();
  }

  Future<List<SavedOrder>> getSavedOrdersForRestaurant(String restaurantId) async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'saved_orders',
      where: 'restaurant_id = ?',
      whereArgs: [restaurantId],
      orderBy: 'created_at DESC',
    );
    return results.map((row) => _savedOrderFromRow(row)).toList();
  }

  Future<SavedOrder?> getSavedOrderById(String id) async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'saved_orders',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return _savedOrderFromRow(results.first);
  }

  SavedOrder _savedOrderFromRow(Map<String, dynamic> row) {
    final entriesJson = row['entries_json'] as String;
    final entriesList = jsonDecode(entriesJson) as List<dynamic>;
    final entries = entriesList
        .map((e) => SubOrderEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    return SavedOrder(
      id: row['id'] as String,
      restaurantId: row['restaurant_id'] as String,
      label: row['label'] as String,
      entries: entries,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  Future<void> saveSavedOrder(SavedOrder order) async {
    final db = await AppDatabase.database;
    await db.insert(
      'saved_orders',
      {
        'id': order.id,
        'restaurant_id': order.restaurantId,
        'label': order.label,
        'entries_json': jsonEncode(order.entries.map((e) => e.toJson()).toList()),
        'created_at': order.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteSavedOrder(String id) async {
    final db = await AppDatabase.database;
    await db.delete('saved_orders', where: 'id = ?', whereArgs: [id]);
  }
}