import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../models/restaurant.dart';
import '../../data/database/app_database.dart';

class RestaurantRepository {
  Future<List<Restaurant>> getAllRestaurants() async {
    final db = await AppDatabase.database;
    final results = await db.query('restaurants', orderBy: 'created_at DESC');
    return results.map((row) {
      final map = Map<String, dynamic>.from(row);
      map['menu'] = jsonDecode(row['menu_json'] as String);
      map.remove('menu_json');
      return Restaurant.fromJson(map);
    }).toList();
  }

  Future<Restaurant?> getRestaurantById(String id) async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'restaurants',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    final row = results.first;
    final map = Map<String, dynamic>.from(row);
    map['menu'] = jsonDecode(row['menu_json'] as String);
    map.remove('menu_json');
    return Restaurant.fromJson(map);
  }

  Future<void> saveRestaurant(Restaurant restaurant) async {
    final db = await AppDatabase.database;
    await db.insert(
      'restaurants',
      {
        'id': restaurant.id,
        'name': restaurant.name,
        'address': restaurant.address,
        'cover_image_path': restaurant.coverImagePath,
        'menu_json': jsonEncode(restaurant.menu.map((e) => e.toJson()).toList()),
        'created_at': restaurant.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateRestaurant(Restaurant restaurant) async {
    final db = await AppDatabase.database;
    await db.update(
      'restaurants',
      {
        'name': restaurant.name,
        'address': restaurant.address,
        'cover_image_path': restaurant.coverImagePath,
        'menu_json': jsonEncode(restaurant.menu.map((e) => e.toJson()).toList()),
      },
      where: 'id = ?',
      whereArgs: [restaurant.id],
    );
  }

  Future<void> deleteRestaurant(String id) async {
    final db = await AppDatabase.database;
    await db.delete('restaurants', where: 'id = ?', whereArgs: [id]);
  }
}
