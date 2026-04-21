import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/personal_sub_order.dart';
import '../../domain/repositories/personal_sub_order_repository.dart';

final personalSubOrderRepositoryProvider = Provider<PersonalSubOrderRepository>((ref) => PersonalSubOrderRepository());

final personalOrderProvider = AsyncNotifierProvider.family<PersonalOrderNotifier, PersonalSubOrder?, String>(
  () => PersonalOrderNotifier(),
);

class PersonalOrderNotifier extends FamilyAsyncNotifier<PersonalSubOrder?, String> {
  @override
  Future<PersonalSubOrder?> build(String arg) async {
    final parts = arg.split(':');
    final sessionId = parts[0];
    final userId = parts.length > 1 ? parts[1] : '';
    
    if (userId.isEmpty) return null;
    
    final repo = ref.read(personalSubOrderRepositoryProvider);
    return repo.getSubOrder(sessionId, userId);
  }

  Future<void> saveOrder({
    required String sessionId,
    required String userId,
    required List<SubOrderEntry> entries,
  }) async {
    final repo = ref.read(personalSubOrderRepositoryProvider);
    final existing = await repo.getSubOrder(sessionId, userId);
    
    final subOrder = PersonalSubOrder(
      id: existing?.id ?? const Uuid().v4(),
      sessionId: sessionId,
      userId: userId,
      entries: entries,
      checklist: [],
      locked: false,
      updatedAt: DateTime.now(),
    );
    
    if (existing != null) {
      await repo.updateSubOrder(subOrder);
    } else {
      await repo.saveSubOrder(subOrder);
    }
    
    state = AsyncValue.data(subOrder);
  }

  Future<void> lockOrder() async {
    final current = state.value;
    if (current == null) return;

    final locked = current.copyWith(locked: true);
    final repo = ref.read(personalSubOrderRepositoryProvider);
    await repo.updateSubOrder(locked);
    
    state = AsyncValue.data(locked);
  }

  Future<void> clearOrder() async {
    final current = state.value;
    if (current == null) return;

    final repo = ref.read(personalSubOrderRepositoryProvider);
    await repo.deleteSubOrder(current.id);
    
    state = const AsyncValue.data(null);
  }
}

final subOrdersForSessionProvider = FutureProvider.family<List<PersonalSubOrder>, String>((ref, sessionId) async {
  final repo = ref.read(personalSubOrderRepositoryProvider);
  return repo.getSubOrdersForSession(sessionId);
});