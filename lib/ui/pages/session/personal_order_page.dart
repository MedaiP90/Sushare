import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/models/restaurant.dart';
import '../../../domain/models/personal_sub_order.dart';
import '../../../domain/models/saved_order.dart';
import '../../../domain/repositories/saved_order_repository.dart';
import '../../viewmodels/session_viewmodel.dart';
import '../../viewmodels/restaurant_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/personal_order_viewmodel.dart';

class PersonalOrderPage extends ConsumerStatefulWidget {
  final String sessionId;

  const PersonalOrderPage({super.key, required this.sessionId});

  @override
  ConsumerState<PersonalOrderPage> createState() => _PersonalOrderPageState();
}

class _PersonalOrderPageState extends ConsumerState<PersonalOrderPage> {
  final _quantities = <String, int>{};
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionDetailProvider(widget.sessionId));
    final user = ref.watch(profileViewModelProvider).value;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in first')),
      );
    }

    return sessionAsync.when(
      data: (session) {
        if (session == null) {
          return const Scaffold(
            body: Center(child: Text('Session not found')),
          );
        }

        final restaurantAsync = ref.watch(restaurantDetailProvider(session.restaurantId));
        final personalOrderKey = '${widget.sessionId}:${user.id}';
        final personalOrderAsync = ref.watch(personalOrderProvider(personalOrderKey));

        return restaurantAsync.when(
          data: (restaurant) {
            if (restaurant == null) {
              return const Scaffold(
                body: Center(child: Text('Restaurant not found')),
              );
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

            final sortedMenu = List<MenuItem>.from(restaurant.menu)
              ..sort((a, b) => (a.itemNumber ?? 0).compareTo(b.itemNumber ?? 0));

            final isLocked = personalOrderAsync.value?.locked ?? false;
            final itemCount = _quantities.values.where((q) => q > 0).length;

            return Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Select your items',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (isLocked)
                        const Chip(
                          label: Text('Locked'),
                          avatar: Icon(Icons.lock, size: 16),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLocked
                        ? 'Your order is locked and cannot be changed'
                        : 'Tap + to add items to your order',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ...sortedMenu.map((item) {
                          final quantity = _quantities[item.id] ?? 0;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: item.itemNumber != null
                                  ? CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                      child: Text('${item.itemNumber}'),
                                    )
                                  : null,
                              title: Text(item.name),
                              subtitle: item.description != null
                                  ? Text(item.description!)
                                  : null,
                              trailing: isLocked
                                  ? SizedBox(
                                      width: 50,
                                      child: Text(
                                        '$quantity',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove),
                                          onPressed: quantity > 0
                                              ? () {
                                                  setState(() {
                                                    _quantities[item.id] = quantity - 1;
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
                                          icon: const Icon(Icons.add),
                                          onPressed: () {
                                            setState(() {
                                              _quantities[item.id] = quantity + 1;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                            ),
                          );
                        }),
                ],
              ),
              bottomNavigationBar: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isLocked) ...[
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: itemCount > 0
                                    ? () => _saveOrder(context, user.id, restaurant.menu)
                                    : null,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text('Save Order ($itemCount items)'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: () => _showSavedOrdersDialog(context, user.id, restaurant.menu, restaurant.id),
                              icon: const Icon(Icons.bookmark_border),
                              tooltip: 'Saved orders',
                            ),
                          ],
                        ),
                      ],
                      if (isLocked)
                        OutlinedButton(
                          onPressed: () => _showUnlockDialog(context),
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Unlock to edit'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Scaffold(
            body: Center(child: Text('Error: $error')),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Future<void> _saveOrder(BuildContext context, String userId, List<MenuItem> menuItems) async {
    final entries = _quantities.entries
        .where((e) => e.value > 0)
        .map((e) {
          final item = menuItems.firstWhere((m) => m.id == e.key);
          return SubOrderEntry(
            menuItemId: e.key,
            name: item.name,
            quantity: e.value,
          );
        })
        .toList();

    await ref.read(personalOrderProvider('${widget.sessionId}:$userId').notifier).saveOrder(
          sessionId: widget.sessionId,
          userId: userId,
          entries: entries,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order saved with ${entries.length} items')),
      );
    }
  }

  void _showUnlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlock Order'),
        content: const Text('Are you sure you want to unlock your order? You will need to save again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final user = ref.read(profileViewModelProvider).value;
              if (user != null) {
                await ref.read(personalOrderProvider('${widget.sessionId}:${user.id}').notifier).clearOrder();
              }
              if (mounted) {
                Navigator.pop(context);
                setState(() {
                  _initialized = false;
                });
              }
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }

  void _showSavedOrdersDialog(BuildContext context, String userId, List<MenuItem> menuItems, String restaurantId) {
    final labelController = TextEditingController();
    final repo = SavedOrderRepository();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => FutureBuilder<List<SavedOrder>>(
          future: repo.getSavedOrdersForRestaurant(restaurantId),
          builder: (context, snapshot) {
            final orders = snapshot.data ?? [];
            
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        'Saved Orders',
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
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: labelController,
                          decoration: const InputDecoration(
                            labelText: 'Save current order as',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: () async {
                          if (labelController.text.trim().isEmpty) return;
                          if (_quantities.values.every((q) => q == 0)) return;
                          
                          final entries = _quantities.entries
                              .where((e) => e.value > 0)
                              .map((e) {
                            final item = menuItems.firstWhere((m) => m.id == e.key);
                            return SubOrderEntry(
                              menuItemId: e.key,
                              name: item.name,
                              quantity: e.value,
                            );
                          }).toList();
                          
                          final savedOrder = SavedOrder(
                            id: const Uuid().v4(),
                            restaurantId: restaurantId,
                            label: labelController.text.trim(),
                            entries: entries,
                            createdAt: DateTime.now(),
                          );
                          
                          await repo.saveSavedOrder(savedOrder);
                          labelController.clear();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Order saved!')),
                          );
                        },
                        icon: const Icon(Icons.save),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: orders.isEmpty
                        ? Center(
                            child: Text(
                              'No saved orders for this restaurant',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              return Card(
                                child: ListTile(
                                  title: Text(order.label),
                                  subtitle: Text('${order.entries.length} items'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () async {
                                          await repo.deleteSavedOrder(order.id);
                                          Navigator.pop(context);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle),
                                        onPressed: () {
                                          setState(() {
                                            for (final entry in order.entries) {
                                              _quantities[entry.menuItemId] = 
                                                  (_quantities[entry.menuItemId] ?? 0) + entry.quantity;
                                            }
                                          });
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Loaded "${order.label}"')),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}