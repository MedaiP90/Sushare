import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/saved_order.dart';
import '../../domain/models/personal_sub_order.dart';
import '../../domain/repositories/saved_order_repository.dart';

final savedOrderRepositoryProvider = Provider<SavedOrderRepository>(
  (ref) => SavedOrderRepository(),
);

final savedOrdersForRestaurantProvider =
    FutureProvider.family<List<SavedOrder>, String>((ref, restaurantId) async {
  final repo = ref.read(savedOrderRepositoryProvider);
  return repo.getSavedOrdersForRestaurant(restaurantId);
});

final savedOrderActionsProvider = Provider<SavedOrderActions>(
  (ref) => SavedOrderActions(ref),
);

class SavedOrderActions {
  final Ref _ref;
  SavedOrderActions(this._ref);

  Future<void> saveTemplate({
    required String restaurantId,
    required String label,
    required List<SubOrderEntry> entries,
  }) async {
    final repo = _ref.read(savedOrderRepositoryProvider);
    final order = SavedOrder(
      id: const Uuid().v4(),
      restaurantId: restaurantId,
      label: label,
      entries: entries,
      createdAt: DateTime.now(),
    );
    await repo.saveSavedOrder(order);
    _ref.invalidate(savedOrdersForRestaurantProvider(restaurantId));
  }

  Future<void> deleteTemplate(String id, String restaurantId) async {
    final repo = _ref.read(savedOrderRepositoryProvider);
    await repo.deleteSavedOrder(id);
    _ref.invalidate(savedOrdersForRestaurantProvider(restaurantId));
  }
}
