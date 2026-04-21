import 'package:sqflite/sqflite.dart';
import '../models/local_user.dart';
import '../../data/database/app_database.dart';

class UserRepository {
  Future<LocalUser?> getLocalUser() async {
    final db = await AppDatabase.database;
    final results = await db.query('local_users', limit: 1);
    if (results.isEmpty) return null;
    
    final row = results.first;
    return LocalUser(
      id: row['id'] as String,
      username: row['username'] as String,
      firstName: row['first_name'] as String,
      lastName: row['last_name'] as String,
      profilePicturePath: row['profile_picture_path'] as String?,
      avatarColorValue: row['avatar_color_value'] as int,
      createdAt: row['created_at'] != null 
          ? DateTime.parse(row['created_at'] as String)
          : null,
    );
  }

  Future<void> saveLocalUser(LocalUser user) async {
    final db = await AppDatabase.database;
    await db.insert(
      'local_users',
      {
        'id': user.id,
        'username': user.username,
        'first_name': user.firstName,
        'last_name': user.lastName,
        'profile_picture_path': user.profilePicturePath,
        'avatar_color_value': user.avatarColorValue,
        'created_at': user.createdAt?.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateLocalUser(LocalUser user) async {
    final db = await AppDatabase.database;
    await db.update(
      'local_users',
      {
        'username': user.username,
        'first_name': user.firstName,
        'last_name': user.lastName,
        'profile_picture_path': user.profilePicturePath,
        'avatar_color_value': user.avatarColorValue,
      },
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> deleteLocalUser(String id) async {
    final db = await AppDatabase.database;
    await db.delete('local_users', where: 'id = ?', whereArgs: [id]);
  }
}
