import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/session.dart';
import '../../domain/repositories/session_repository.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) => SessionRepository());

final sessionsProvider = AsyncNotifierProvider<SessionsNotifier, List<Session>>(() => SessionsNotifier());

class SessionsNotifier extends AsyncNotifier<List<Session>> {
  @override
  Future<List<Session>> build() async {
    final repo = ref.read(sessionRepositoryProvider);
    return repo.getAllSessions();
  }

  Future<String> createSession({
    required String name,
    required String restaurantId,
    required String hostUserId,
  }) async {
    final repo = ref.read(sessionRepositoryProvider);
    final session = Session(
      id: const Uuid().v4(),
      name: name,
      restaurantId: restaurantId,
      hostUserId: hostUserId,
      participantIds: [hostUserId],
      status: SessionStatus.open,
      additionalOrders: [],
      createdAt: DateTime.now(),
    );
    await repo.saveSession(session);
    state = AsyncValue.data([session, ...state.value ?? []]);
    return session.id;
  }

  Future<void> updateSession(Session session) async {
    final repo = ref.read(sessionRepositoryProvider);
    await repo.updateSession(session);
    final current = state.value ?? [];
    final index = current.indexWhere((s) => s.id == session.id);
    if (index != -1) {
      final updated = [...current];
      updated[index] = session;
      state = AsyncValue.data(updated);
    }
  }

  Future<void> deleteSession(String id) async {
    final repo = ref.read(sessionRepositoryProvider);
    await repo.deleteSession(id);
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((s) => s.id != id).toList());
  }

  Future<void> closeSession(String id) async {
    final repo = ref.read(sessionRepositoryProvider);
    final session = await repo.getSessionById(id);
    if (session == null) return;

    final updated = session.copyWith(status: SessionStatus.closed);
    await repo.updateSession(updated);
    ref.invalidate(sessionDetailProvider(id));
  }

  Future<void> sendMainOrder(String id) async {
    final repo = ref.read(sessionRepositoryProvider);
    final session = await repo.getSessionById(id);
    if (session == null) return;

    final updated = session.copyWith(
      status: SessionStatus.sent,
      sentAt: DateTime.now(),
    );
    await repo.updateSession(updated);
    ref.invalidate(sessionDetailProvider(id));
  }
}

final sessionDetailProvider = FutureProvider.family<Session?, String>((ref, id) async {
  final repo = ref.read(sessionRepositoryProvider);
  return repo.getSessionById(id);
});