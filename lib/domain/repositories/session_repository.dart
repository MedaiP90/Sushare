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

  Future<Session?> getSessionByShortCode(String shortCode) async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'sessions',
      where: 'UPPER(id) LIKE ?',
      whereArgs: ['${shortCode.toUpperCase()}%'],
    );
    if (results.isEmpty) return null;
    return _sessionFromRow(results.first);
  }

  Session _sessionFromRow(Map<String, dynamic> row) {
    final participantIdsJson = row['participant_ids_json'] as String;
    final participantIdsList = jsonDecode(participantIdsJson) as List<dynamic>;
    final participantIds = participantIdsList.map((e) => e as String).toList();

    Order? mainOrder;
    final mainOrderJson = row['main_order_json'];
    if (mainOrderJson != null) {
      mainOrder = Order.fromJson(jsonDecode(mainOrderJson as String));
    }

    final additionalOrdersJson = row['additional_orders_json'] as String;
    final additionalOrdersList = jsonDecode(additionalOrdersJson) as List<dynamic>;
    final additionalOrders = additionalOrdersList
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();

    final statusStr = row['status'] as String;
    final status = SessionStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => SessionStatus.open,
    );

    final arrivedCountsJson = row['arrived_counts_json'] as String?;
    final arrivedCounts = arrivedCountsJson != null
        ? (jsonDecode(arrivedCountsJson) as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int))
        : <String, int>{};

    return Session(
      id: row['id'] as String,
      name: row['name'] as String,
      restaurantId: row['restaurant_id'] as String,
      hostUserId: row['host_user_id'] as String,
      participantIds: participantIds,
      status: status,
      mainOrder: mainOrder,
      additionalOrders: additionalOrders,
      arrivedCounts: arrivedCounts,
      createdAt: DateTime.parse(row['created_at'] as String),
      sentAt: row['sent_at'] != null
          ? DateTime.parse(row['sent_at'] as String)
          : null,
      hostAddress: row['host_address'] as String?,
    );
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
      'arrived_counts_json': jsonEncode(session.arrivedCounts),
      'created_at': session.createdAt.toIso8601String(),
      'sent_at': session.sentAt?.toIso8601String(),
      'host_address': session.hostAddress,
    };
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
}