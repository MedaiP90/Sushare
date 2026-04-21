import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/models/restaurant.dart';
import '../../../domain/models/personal_sub_order.dart';
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

            final groupedMenu = <String, List<MenuItem>>{};
            for (final item in restaurant.menu) {
              groupedMenu.putIfAbsent(item.category, () => []).add(item);
            }

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
                  ...groupedMenu.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            entry.key,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                        ...entry.value.map((item) {
                          final quantity = _quantities[item.id] ?? 0;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
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
                      if (!isLocked)
                        FilledButton(
                          onPressed: itemCount > 0
                              ? () => _saveOrder(context, user.id, restaurant.menu)
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('Save Order ($itemCount items)'),
                          ),
                        ),
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
}