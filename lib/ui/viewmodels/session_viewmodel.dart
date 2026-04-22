import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/session.dart';
import '../../domain/models/personal_sub_order.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/repositories/personal_sub_order_repository.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) => SessionRepository());
final personalSubOrderRepositoryProvider = Provider<PersonalSubOrderRepository>((ref) => PersonalSubOrderRepository());

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
    String? hostUserName,
    String? hostFullName,
    String? hostProfilePicturePath,
  }) async {
    final sessionRepo = ref.read(sessionRepositoryProvider);
    final subOrderRepo = ref.read(personalSubOrderRepositoryProvider);

    final sessionId = const Uuid().v4();
    final session = Session(
      id: sessionId,
      name: name,
      restaurantId: restaurantId,
      hostUserId: hostUserId,
      participantIds: [hostUserId],
      status: SessionStatus.open,
      additionalOrders: [],
      createdAt: DateTime.now(),
    );
    await sessionRepo.saveSession(session);

    final personalOrder = PersonalSubOrder(
      id: const Uuid().v4(),
      sessionId: sessionId,
      userId: hostUserId,
      userName: hostUserName,
      userFullName: hostFullName,
      userProfilePicturePath: hostProfilePicturePath,
      entries: [],
      checklist: [],
      locked: false,
      updatedAt: DateTime.now(),
    );
    await subOrderRepo.saveSubOrder(personalOrder);
    
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
    ref.invalidate(sessionDetailProvider(session.id));
  }

  Future<void> updateArrivedCounts(String sessionId, Map<String, int> counts) async {
    final repo = ref.read(sessionRepositoryProvider);
    final session = await repo.getSessionById(sessionId);
    if (session == null) return;
    final updated = session.copyWith(arrivedCounts: counts);
    await repo.updateSession(updated);
    ref.invalidate(sessionDetailProvider(sessionId));
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
    final current = state.value ?? [];
    final index = current.indexWhere((s) => s.id == id);
    if (index != -1) {
      final newList = [...current];
      newList[index] = updated;
      state = AsyncValue.data(newList);
    }
    ref.invalidate(sessionDetailProvider(id));
  }

  Future<void> openNewRound(String id) async {
    final repo = ref.read(sessionRepositoryProvider);
    final session = await repo.getSessionById(id);
    if (session == null) return;

    final updated = session.copyWith(status: SessionStatus.open);
    await repo.updateSession(updated);
    ref.invalidate(sessionDetailProvider(id));
  }
}

final sessionDetailProvider = FutureProvider.family<Session?, String>((ref, id) async {
  final repo = ref.read(sessionRepositoryProvider);
  return repo.getSessionById(id);
});