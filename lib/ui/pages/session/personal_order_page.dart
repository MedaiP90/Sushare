import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/models/restaurant.dart';
import '../../../domain/models/personal_sub_order.dart';
import '../../../domain/models/personal_sub_order.dart';
import '../../viewmodels/session_viewmodel.dart';
import '../../viewmodels/restaurant_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';

class PersonalOrderPage extends ConsumerStatefulWidget {
  final String sessionId;

  const PersonalOrderPage({super.key, required this.sessionId});

  @override
  ConsumerState<PersonalOrderPage> createState() => _PersonalOrderPageState();
}

class _PersonalOrderPageState extends ConsumerState<PersonalOrderPage> {
  final _quantities = <String, int>{};

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionDetailProvider(widget.sessionId));
    final user = ref.watch(profileViewModelProvider).value;

    return sessionAsync.when(
      data: (session) {
        if (session == null) {
          return const Scaffold(
            body: Center(child: Text('Session not found')),
          );
        }

        final restaurantAsync = ref.watch(restaurantDetailProvider(session.restaurantId));

        return restaurantAsync.when(
          data: (restaurant) {
            if (restaurant == null) {
              return const Scaffold(
                body: Center(child: Text('Restaurant not found')),
              );
            }

            final groupedMenu = <String, List<MenuItem>>{};
            for (final item in restaurant.menu) {
              groupedMenu.putIfAbsent(item.category, () => []).add(item);
            }

            return Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Select your items',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add items to your order',
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
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: quantity > 0
                                        ? () => setState(() {
                                              _quantities[item.id] = quantity - 1;
                                            })
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
                                    onPressed: () => setState(() {
                                      _quantities[item.id] = quantity + 1;
                                    }),
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
                  child: FilledButton(
                    onPressed: _quantities.values.any((q) => q > 0)
                        ? () => _saveOrder(context, user?.id ?? '', restaurant.menu)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Save Order (${_quantities.values.where((q) => q > 0).length} items)'),
                    ),
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

  void _saveOrder(BuildContext context, String userId, List<MenuItem> menuItems) {
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order saved with ${entries.length} items')),
    );

    context.go('/sessions/${widget.sessionId}/merged');
  }
}