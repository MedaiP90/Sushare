import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../models/session.dart';
import '../models/order.dart';
import '../../data/database/app_database.dart';

class SessionRepository {
  Future<List<Session>> getAllSessions() async {
    final db = await AppDatabase.database;
    final results = await db.query('sessions', orderBy: 'created_at DESC');
    return results.map((row) => _sessionFromRow(row)).toList();
  }

  Future<List<Session>> getOpenSessions() async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'sessions',
      where: 'status = ?',
      whereArgs: ['open'],
      orderBy: 'created_at DESC',
    );
    return results.map((row) => _sessionFromRow(row)).toList();
  }

  Future<Session?> getSessionById(String id) async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return _sessionFromRow(results.first);
  }

  Future<void> saveSession(Session session) async {
    final db = await AppDatabase.database;
    await db.insert(
      'sessions',
      _sessionToRow(session),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateSession(Session session) async {
    final db = await AppDatabase.database;
    await db.update(
      'sessions',
      _sessionToRow(session),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<void> deleteSession(String id) async {
    final db = await AppDatabase.database;
    await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> addParticipant(String sessionId, String userId) async {
    final session = await getSessionById(sessionId);
    if (session == null) return;

    if (!session.participantIds.contains(userId)) {
      final updated = session.copyWith(
        participantIds: [...session.participantIds, userId],
      );
      await updateSession(updated);
    }
  }

  Future<void> removeParticipant(String sessionId, String userId) async {
    final session = await getSessionById(sessionId);
    if (session == null) return;

    final updated = session.copyWith(
      participantIds: session.participantIds.where((id) => id != userId).toList(),
    );
    await updateSession(updated);
  }

  Map<String, dynamic> _sessionToRow(Session session) {
    return {
      'id': session.id,
      'name': session.name,
      'restaurant_id': session.restaurantId,
      'host_user_id': session.hostUserId,
      'participant_ids_json': jsonEncode(session.participantIds),
      'status': session.status.name,
      'main_order_json': session.mainOrder != null ? jsonEncode(session.mainOrder!.toJson()) : null,
      'additional_orders_json': jsonEncode(session.additionalOrders.map((o) => o.toJson()).toList()),
      'created_at': session.createdAt.toIso8601String(),
      'sent_at': session.sentAt?.toIso8601String(),
    };
  }

  Session _sessionFromRow(Map<String, dynamic> row) {
    return Session(
      id: row['id'] as String,
      name: row['name'] as String,
      restaurantId: row['restaurant_id'] as String,
      hostUserId: row['host_user_id'] as String,
      participantIds: (jsonDecode(row['participant_ids_json'] as String) as List).cast<String>(),
      status: SessionStatus.values.firstWhere(
        (s) => s.name == row['status'],
        orElse: () => SessionStatus.open,
      ),
      mainOrder: row['main_order_json'] != null
          ? Order.fromJson(jsonDecode(row['main_order_json'] as String))
          : null,
      additionalOrders: (jsonDecode(row['additional_orders_json'] as String) as List)
          .map((o) => Order.fromJson(o))
          .toList(),
      createdAt: DateTime.parse(row['created_at'] as String),
      sentAt: row['sent_at'] != null
          ? DateTime.parse(row['sent_at'] as String)
          : null,
    );
  }
}