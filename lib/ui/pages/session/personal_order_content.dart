import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/models/restaurant.dart';
import '../../../domain/models/personal_sub_order.dart';
import '../../../domain/repositories/restaurant_repository.dart';
import '../../viewmodels/session_viewmodel.dart';
import '../../viewmodels/restaurant_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/personal_order_viewmodel.dart';

class PersonalOrderContent extends ConsumerStatefulWidget {
  final String sessionId;

  const PersonalOrderContent({super.key, required this.sessionId});

  @override
  ConsumerState<PersonalOrderContent> createState() => _PersonalOrderContentState();
}

class _PersonalOrderContentState extends ConsumerState<PersonalOrderContent> {
  final _quantities = <String, int>{};
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionDetailProvider(widget.sessionId));
    final user = ref.watch(profileViewModelProvider).value;

    if (user == null) {
      return const Center(child: Text('Please log in first'));
    }

    return sessionAsync.when(
      data: (session) {
        if (session == null) {
          return const Center(child: Text('Session not found'));
        }

        final restaurantAsync = ref.watch(restaurantDetailProvider(session.restaurantId));
        final personalOrderKey = '${widget.sessionId}:${user.id}';
        final personalOrderAsync = ref.watch(personalOrderProvider(personalOrderKey));

        return restaurantAsync.when(
          data: (restaurant) {
            if (restaurant == null) {
              return const Center(child: Text('Restaurant not found'));
            }

            if (!_initialized) {
              _initialized = true;
              personalOrderAsync.whenData((order) {
                if (order != null) {
                  for (final entry in order.entries) {
                    _quantities[entry.menuItemId] = entry.quantity;
                  }
                }
              });
            }

            final orderedItems = _quantities.entries
                .where((e) => e.value > 0)
                .map((e) {
                  final menuItem = restaurant.menu.where((m) => m.id == e.key).firstOrNull;
                  final name = menuItem?.name ?? e.key;
                  return _OrderedItem(
                    id: e.key,
                    name: name,
                    quantity: e.value,
                    isCustom: menuItem == null,
                  );
                })
                .toList();

            final totalItems = _quantities.values.fold(0, (a, b) => a + b);

            return Scaffold(
              body: orderedItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_shopping_cart,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your order is empty',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the button below to add dishes',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (orderedItems.isNotEmpty) ...[
                          Text(
                            'Your Order ($totalItems items)',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          ...orderedItems.map((item) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: item.isCustom
                                      ? CircleAvatar(
                                          radius: 14,
                                          backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                                          child: const Icon(Icons.add, size: 14),
                                        )
                                      : CircleAvatar(
                                          radius: 14,
                                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                          child: Text('${_getItemNumber(restaurant, item.id)}'),
                                        ),
                                  title: Text(item.name),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove),
                                        onPressed: () {
                                          setState(() {
                                            final qty = _quantities[item.id] ?? 0;
                                            if (qty > 1) {
                                              _quantities[item.id] = qty - 1;
                                            } else {
                                              _quantities.remove(item.id);
                                            }
                                          });
                                        },
                                      ),
                                      SizedBox(
                                        width: 32,
                                        child: Text(
                                          '${item.quantity}',
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context).textTheme.titleMedium,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: () {
                                          setState(() {
                                            _quantities[item.id] = (_quantities[item.id] ?? 0) + 1;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                        ],
                      ],
                    ),
              floatingActionButton: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FloatingActionButton.extended(
                    heroTag: 'addFromMenu',
                    onPressed: () => _showAddFromMenuSheet(context, restaurant, user.id),
                    icon: const Icon(Icons.restaurant_menu),
                    label: const Text('Menu'),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton.extended(
                    heroTag: 'addCustom',
                    onPressed: () => _showAddCustomDishSheet(context, restaurant, user.id),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Dish'),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  int? _getItemNumber(Restaurant restaurant, String itemId) {
    final item = restaurant.menu.where((m) => m.id == itemId).firstOrNull;
    return item?.itemNumber;
  }

  void _showAddFromMenuSheet(BuildContext context, Restaurant restaurant, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          final currentRestaurant = ref.read(restaurantDetailProvider(restaurant.id)).valueOrNull ?? restaurant;
          final sortedMenu = List<MenuItem>.from(currentRestaurant.menu)
            ..sort((a, b) => (a.itemNumber ?? 0).compareTo(b.itemNumber ?? 0));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Add from Menu',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: sortedMenu.length,
                  itemBuilder: (context, index) {
                    final item = sortedMenu[index];
                    final quantity = _quantities[item.id] ?? 0;

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Text('${item.itemNumber ?? '-'}'),
                      ),
                      title: Text(item.name),
                      subtitle: item.description != null ? Text(item.description!) : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: quantity > 0
                                ? () {
                                    setState(() {
                                      if (quantity > 1) {
                                        _quantities[item.id] = quantity - 1;
                                      } else {
                                        _quantities.remove(item.id);
                                      }
                                    });
                                  }
                                : null,
                          ),
                          SizedBox(
                            width: 32,
                            child: Text(
                              '$quantity',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () {
                              setState(() {
                                _quantities[item.id] = quantity + 1;
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: _quantities.values.any((q) => q > 0)
                        ? () async {
                            final r = ref.read(restaurantDetailProvider(restaurant.id)).valueOrNull ?? restaurant;
                            await _saveOrder(context, userId, r.menu);
                          }
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Add ${_quantities.values.where((q) => q > 0).length} items'),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddCustomDishSheet(BuildContext context, Restaurant restaurant, String userId) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final numberController = TextEditingController();

    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Add Custom Dish',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Dish name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: numberController,
              decoration: const InputDecoration(
                labelText: 'Menu number (optional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                Navigator.pop(context, {
                  'name': nameController.text.trim(),
                  'description': descController.text.trim(),
                  'number': numberController.text.trim(),
                });
              },
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Add'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      final dishId = const Uuid().v4();
      final number = result['number']!.isEmpty ? null : int.tryParse(result['number']!);

      final newItem = MenuItem(
        id: dishId,
        name: result['name']!,
        description: result['description']!.isEmpty ? null : result['description'],
        itemNumber: number,
      );

      final updatedRestaurant = restaurant.copyWith(
        menu: [...restaurant.menu, newItem],
      );

      final repo = RestaurantRepository();
      await repo.saveRestaurant(updatedRestaurant);
      ref.invalidate(restaurantDetailProvider(restaurant.id));

      setState(() {
        _quantities[dishId] = 1;
      });

      final entries = _quantities.entries
          .where((e) => e.value > 0)
          .map((e) {
            final item = updatedRestaurant.menu.where((m) => m.id == e.key).firstOrNull;
            return SubOrderEntry(
              menuItemId: e.key,
              name: item?.name ?? e.key,
              quantity: e.value,
            );
          })
          .toList();

      await ref.read(personalOrderProvider('${widget.sessionId}:$userId').notifier).saveOrder(
            sessionId: widget.sessionId,
            userId: userId,
            entries: entries,
          );

      ref.invalidate(subOrdersForSessionProvider(widget.sessionId));
      ref.invalidate(sessionDetailProvider(widget.sessionId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added "${newItem.name}" to order')),
        );
      }
    }
  }

  Future<void> _saveOrder(BuildContext context, String userId, List<MenuItem> menuItems) async {
    final entries = _quantities.entries
        .where((e) => e.value > 0)
        .map((e) {
          final item = menuItems.where((m) => m.id == e.key).firstOrNull;
          return SubOrderEntry(
            menuItemId: e.key,
            name: item?.name ?? e.key,
            quantity: e.value,
          );
        })
        .toList();

    await ref.read(personalOrderProvider('${widget.sessionId}:$userId').notifier).saveOrder(
          sessionId: widget.sessionId,
          userId: userId,
          entries: entries,
        );

    ref.invalidate(subOrdersForSessionProvider(widget.sessionId));
    ref.invalidate(sessionDetailProvider(widget.sessionId));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order saved with ${entries.length} items')),
      );
    }
  }
}

class _OrderedItem {
  final String id;
  final String name;
  final int quantity;
  final bool isCustom;

  _OrderedItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.isCustom,
  });
}
