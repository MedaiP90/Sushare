import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/order.dart';
import '../../../domain/models/restaurant.dart';
import '../../../domain/models/session.dart';
import '../../viewmodels/session_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/restaurant_viewmodel.dart';

class ChecklistContent extends ConsumerWidget {
  final String sessionId;

  const ChecklistContent({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionDetailProvider(sessionId));
    final user = ref.watch(profileViewModelProvider).value;

    return sessionAsync.when(
      data: (session) {
        if (session == null) {
          return const Center(child: Text('Table not found'));
        }

        final isHost = user?.id == session.hostUserId;
        final isEditable = session.status != SessionStatus.closed;
        final restaurant = ref.watch(restaurantDetailProvider(session.restaurantId)).valueOrNull;

        if (session.mainOrder == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No order to track',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'The order hasn\'t been sent yet',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          );
        }

        final allOrders = <_OrderWithLabel>[];
        if (session.mainOrder != null) {
          allOrders.add(_OrderWithLabel(session.mainOrder!, 'Order 1'));
        }
        for (int i = 0; i < session.additionalOrders.length; i++) {
          allOrders.add(_OrderWithLabel(session.additionalOrders[i], 'Order ${i + 2}'));
        }

        final arrivedCounts = session.arrivedCounts;

        final allArrived = allOrders.every((o) =>
            o.order.items.every((item) {
              final arrived = arrivedCounts['${o.label}:${item.menuItemId}'] ?? 0;
              return arrived >= item.quantity;
            }));

        return Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Checklist',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (allArrived)
                    Chip(
                      label: const Text('Complete'),
                      avatar: const Icon(Icons.check_circle, size: 16),
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isHost
                    ? 'Track what has arrived from all orders'
                    : 'Track what has arrived from your dishes',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              for (int i = 0; i < allOrders.length; i++) ...[
                if (i > 0) const SizedBox(height: 24),
                _buildOrderChecklist(context, ref, isHost && isEditable, allOrders[i], session, arrivedCounts, restaurant),
              ],
              if (!isHost)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Card(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Only the host can update arrival status',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Future<void> _toggleYummie(WidgetRef ref, Restaurant restaurant, MenuItem item) async {
    final updatedItem = item.copyWith(isYummie: !item.isYummie);
    final updatedMenu =
        restaurant.menu.map((m) => m.id == item.id ? updatedItem : m).toList();
    await ref.read(restaurantsProvider.notifier).updateRestaurant(
          restaurant.copyWith(menu: updatedMenu),
        );
  }

  Future<void> _updateCount(WidgetRef ref, Session session, String key, int newCount) async {
    final updated = Map<String, int>.from(session.arrivedCounts);
    if (newCount <= 0) {
      updated.remove(key);
    } else {
      updated[key] = newCount;
    }
    await ref.read(sessionsProvider.notifier).updateArrivedCounts(session.id, updated);
  }

  Widget _buildOrderChecklist(
    BuildContext context,
    WidgetRef ref,
    bool isHost,
    _OrderWithLabel orderWithLabel,
    Session session,
    Map<String, int> arrivedCounts,
    Restaurant? restaurant,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                orderWithLabel.label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            Chip(
              label: Text('${orderWithLabel.order.items.length} items'),
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Column(
            children: orderWithLabel.order.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final countKey = '${orderWithLabel.label}:${item.menuItemId}';
              final arrived = arrivedCounts[countKey] ?? 0;
              final total = item.quantity;
              final menuItem = restaurant?.menu
                  .where((m) => m.id == item.menuItemId)
                  .firstOrNull;
              final isYummie = menuItem?.isYummie ?? false;
              final progress = arrived / total;

              return Column(
                children: [
                  ListTile(
                    title: Row(
                      children: [
                        if (isYummie) ...[
                          Icon(Icons.restaurant, size: 14, color: Colors.amber[700]),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            item.name,
                            style: arrived >= total
                                ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      decoration: TextDecoration.lineThrough,
                                      color: Theme.of(context).colorScheme.outline,
                                    )
                                : null,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$arrived of $total arrived',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.restaurant,
                            size: 20,
                            color: isYummie
                                ? Colors.amber[700]
                                : Theme.of(context).colorScheme.outlineVariant,
                          ),
                          tooltip: isYummie ? 'Remove Yummie' : 'Mark as Yummie',
                          onPressed: menuItem != null && restaurant != null
                              ? () => _toggleYummie(ref, restaurant, menuItem)
                              : null,
                        ),
                        if (isHost) ...[
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: arrived > 0
                                ? () => _updateCount(ref, session, countKey, arrived - 1)
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: arrived < total
                                ? () => _updateCount(ref, session, countKey, arrived + 1)
                                : null,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (index < orderWithLabel.order.items.length - 1)
                    Divider(
                      height: 1,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _OrderWithLabel {
  final Order order;
  final String label;

  _OrderWithLabel(this.order, this.label);
}
