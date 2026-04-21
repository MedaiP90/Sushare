import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../models/restaurant.dart';
import '../../data/database/app_database.dart';

class RestaurantRepository {
  Future<List<Restaurant>> getAllRestaurants() async {
    final db = await AppDatabase.database;
    final results = await db.query('restaurants', orderBy: 'created_at DESC');
    return results.map((row) => _restaurantFromRow(row)).toList();
  }

  Future<Restaurant?> getRestaurantById(String id) async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'restaurants',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return _restaurantFromRow(results.first);
  }

  Restaurant _restaurantFromRow(Map<String, dynamic> row) {
    final menuJson = row['menu_json'] as String;
    final menuList = jsonDecode(menuJson) as List<dynamic>;
    final menu = menuList.map((e) => MenuItem.fromJson(e as Map<String, dynamic>)).toList();
    
    return Restaurant(
      id: row['id'] as String,
      name: row['name'] as String,
      address: row['address'] as String?,
      coverImagePath: row['cover_image_path'] as String?,
      menu: menu,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
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