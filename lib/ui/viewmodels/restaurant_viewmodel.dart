import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/restaurant.dart';
import '../../domain/repositories/restaurant_repository.dart';

final restaurantRepositoryProvider = Provider<RestaurantRepository>((ref) => RestaurantRepository());

final restaurantsProvider = AsyncNotifierProvider<RestaurantsNotifier, List<Restaurant>>(
  () => RestaurantsNotifier(),
);

class RestaurantsNotifier extends AsyncNotifier<List<Restaurant>> {
  @override
  Future<List<Restaurant>> build() async {
    final repo = ref.read(restaurantRepositoryProvider);
    return repo.getAllRestaurants();
  }

  Future<String> addRestaurant({
    required String name,
    String? address,
    String? phoneNumber,
    String? coverImagePath,
    required List<MenuItem> menu,
  }) async {
    final repo = ref.read(restaurantRepositoryProvider);
    final restaurant = Restaurant(
      id: const Uuid().v4(),
      name: name,
      address: address,
      phoneNumber: phoneNumber,
      coverImagePath: coverImagePath,
      menu: menu,
      createdAt: DateTime.now(),
    );
    await repo.saveRestaurant(restaurant);
    state = AsyncValue.data([restaurant, ...state.value ?? []]);
    return restaurant.id;
  }

  Future<void> updateRestaurant(Restaurant restaurant) async {
    final repo = ref.read(restaurantRepositoryProvider);
    await repo.updateRestaurant(restaurant);
    final current = state.value ?? [];
    final index = current.indexWhere((r) => r.id == restaurant.id);
    if (index != -1) {
      final updated = [...current];
      updated[index] = restaurant;
      state = AsyncValue.data(updated);
    }
    ref.invalidate(restaurantDetailProvider(restaurant.id));
  }

  Future<void> deleteRestaurant(String id) async {
    final repo = ref.read(restaurantRepositoryProvider);
    await repo.deleteRestaurant(id);
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((r) => r.id != id).toList());
  }

  Future<void> addMenuItem(String restaurantId, MenuItem item) async {
    final repo = ref.read(restaurantRepositoryProvider);
    final current = state.value ?? [];
    final restaurant = current.firstWhere((r) => r.id == restaurantId);
    final updated = restaurant.copyWith(
      menu: [...restaurant.menu, item],
    );
    await repo.updateRestaurant(updated);
    final index = current.indexWhere((r) => r.id == restaurantId);
    if (index != -1) {
      final newList = [...current];
      newList[index] = updated;
      state = AsyncValue.data(newList);
    }
  }

  Future<void> removeMenuItem(String restaurantId, String menuItemId) async {
    final repo = ref.read(restaurantRepositoryProvider);
    final current = state.value ?? [];
    final restaurant = current.firstWhere((r) => r.id == restaurantId);
    final updated = restaurant.copyWith(
      menu: restaurant.menu.where((m) => m.id != menuItemId).toList(),
    );
    await repo.updateRestaurant(updated);
    final index = current.indexWhere((r) => r.id == restaurantId);
    if (index != -1) {
      final newList = [...current];
      newList[index] = updated;
      state = AsyncValue.data(newList);
    }
  }
}

final restaurantDetailProvider = FutureProvider.family<Restaurant?, String>((ref, id) async {
  final repo = ref.read(restaurantRepositoryProvider);
  return repo.getRestaurantById(id);
});
