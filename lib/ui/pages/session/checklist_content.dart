import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/order.dart';
import '../../../domain/models/restaurant.dart';
import '../../../domain/models/session.dart';
import '../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;

    return sessionAsync.when(
      data: (session) {
        if (session == null) {
          return Center(child: Text(l10n.sessionTableNotFound));
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
                  l10n.checklistNoOrder,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.checklistNoOrderHint,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          );
        }

        // Guests only see items they personally ordered (contributorIds contains their userId)
        final userId = user?.id;
        Order _filterForUser(Order order) {
          if (isHost || userId == null) return order;
          final filtered = order.items
              .where((item) => item.contributorIds.contains(userId))
              .toList();
          return order.copyWith(items: filtered);
        }

        final allOrders = <_OrderWithLabel>[];
        if (session.mainOrder != null) {
          allOrders.add(_OrderWithLabel(_filterForUser(session.mainOrder!), 'Order 1'));
        }
        for (int i = 0; i < session.additionalOrders.length; i++) {
          allOrders.add(_OrderWithLabel(_filterForUser(session.additionalOrders[i]), 'Order ${i + 2}'));
        }

        final arrivedCounts = session.arrivedCounts;

        final anyItems = allOrders.any((o) => o.order.items.isNotEmpty);
        final allArrived = anyItems &&
            allOrders.every((o) => o.order.items.every((item) {
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
                      l10n.checklistTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (allArrived)
                    Chip(
                      label: Text(l10n.checklistComplete),
                      avatar: const Icon(Icons.check_circle, size: 16),
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isHost ? l10n.checklistHostSubtitle : l10n.checklistGuestSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              for (int i = 0; i < allOrders.length; i++) ...[
                if (i > 0) const SizedBox(height: 24),
                _buildOrderChecklist(context, ref, isHost && isEditable, allOrders[i], session, arrivedCounts, restaurant),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(AppLocalizations.of(context)!.errorMessage(error.toString()))),
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
    final l10n = AppLocalizations.of(context)!;

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
              label: Text(l10n.checklistItemsCount(orderWithLabel.order.items.length)),
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
                    leading: menuItem?.itemNumber != null
                        ? CircleAvatar(
                            radius: 14,
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Text(
                              '${menuItem!.itemNumber}',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          )
                        : null,
                    title: Row(
                      children: [
                        if (isYummie) ...[
                          const Icon(Icons.restaurant, size: 14),
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
                          l10n.checklistArrivedOf(arrived, total),
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
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outlineVariant,
                          ),
                          tooltip: isYummie ? l10n.restaurantMenuRemoveYummie : l10n.restaurantMenuMarkYummie,
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
