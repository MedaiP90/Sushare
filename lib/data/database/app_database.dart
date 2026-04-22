import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class AppDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'sushare.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE personal_sub_orders ADD COLUMN user_name TEXT');
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE local_users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        profile_picture_path TEXT,
        avatar_color_value INTEGER NOT NULL,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE restaurants (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT,
        cover_image_path TEXT,
        menu_json TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        restaurant_id TEXT NOT NULL,
        host_user_id TEXT NOT NULL,
        participant_ids_json TEXT NOT NULL,
        status TEXT NOT NULL,
        main_order_json TEXT,
        additional_orders_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        sent_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE personal_sub_orders (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        user_name TEXT,
        entries_json TEXT NOT NULL,
        checklist_json TEXT NOT NULL,
        locked INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE saved_orders (
        id TEXT PRIMARY KEY,
        restaurant_id TEXT NOT NULL,
        label TEXT NOT NULL,
        entries_json TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
