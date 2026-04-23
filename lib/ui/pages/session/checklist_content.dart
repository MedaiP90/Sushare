import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/order.dart';
import '../../../domain/models/personal_sub_order.dart';
import '../../../domain/models/restaurant.dart';
import '../../../domain/models/session.dart';
import '../../../l10n/app_localizations.dart';
import '../../viewmodels/session_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/restaurant_viewmodel.dart';
import '../../viewmodels/personal_order_viewmodel.dart';

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
        if (session == null || user == null) {
          return Center(child: Text(l10n.sessionTableNotFound));
        }

        if (session.mainOrder == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 64,
                    color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                Text(l10n.checklistNoOrder,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(l10n.checklistNoOrderHint,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )),
              ],
            ),
          );
        }

        // Each user sees only the items they personally ordered
        final allOrders = <_OrderWithLabel>[];
        void addIfNonEmpty(Order order, String label) {
          final items = order.items
              .where((item) => item.contributorIds.contains(user.id))
              .toList();
          if (items.isNotEmpty) {
            allOrders.add(_OrderWithLabel(order.copyWith(items: items), label));
          }
        }

        addIfNonEmpty(session.mainOrder!, 'Order 1');
        for (int i = 0; i < session.additionalOrders.length; i++) {
          addIfNonEmpty(session.additionalOrders[i], 'Order ${i + 2}');
        }

        if (allOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 64,
                    color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                Text(l10n.checklistNoOrder,
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          );
        }

        // Watch personal sub order for reactive checklist data
        final personalOrderAsync =
            ref.watch(personalOrderProvider('$sessionId:${user.id}'));
        final personalOrder = personalOrderAsync.valueOrNull;

        // arrivedCounts keyed by "${orderLabel}:${menuItemId}"
        final arrivedCounts = <String, int>{
          for (final entry in personalOrder?.checklist ?? [])
            entry.menuItemId: entry.arrivedCount,
        };

        final isEditable = session.status != SessionStatus.closed;
        final restaurant =
            ref.watch(restaurantDetailProvider(session.restaurantId)).valueOrNull;

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
                    child: Text(l10n.checklistTitle,
                        style: Theme.of(context).textTheme.titleLarge),
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
                l10n.checklistGuestSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              for (int i = 0; i < allOrders.length; i++) ...[
                if (i > 0) const SizedBox(height: 24),
                _buildOrderChecklist(
                  context, ref, isEditable, allOrders[i],
                  arrivedCounts, personalOrder, user.id, restaurant,
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text(AppLocalizations.of(context)!.errorMessage(error.toString()))),
    );
  }

  Future<void> _updateCount(
    WidgetRef ref,
    String sessionId,
    String userId,
    PersonalSubOrder? personalOrder,
    String countKey,
    String itemName,
    int orderedQty,
    int newCount,
  ) async {
    final repo = ref.read(personalSubOrderRepositoryProvider);
    final existing = personalOrder ?? await repo.getSubOrder(sessionId, userId);
    if (existing == null) return;

    final updated = List<ChecklistEntry>.from(existing.checklist);
    final idx = updated.indexWhere((e) => e.menuItemId == countKey);
    if (newCount <= 0) {
      updated.removeWhere((e) => e.menuItemId == countKey);
    } else if (idx != -1) {
      updated[idx] = updated[idx].copyWith(arrivedCount: newCount);
    } else {
      updated.add(ChecklistEntry(
        menuItemId: countKey,
        name: itemName,
        orderedQuantity: orderedQty,
        arrivedCount: newCount,
      ));
    }

    await repo.updateSubOrder(existing.copyWith(checklist: updated, updatedAt: DateTime.now()));
    ref.invalidate(personalOrderProvider('$sessionId:$userId'));
  }

  Future<void> _toggleYummie(WidgetRef ref, Restaurant restaurant, MenuItem item) async {
    final updatedMenu = restaurant.menu
        .map((m) => m.id == item.id ? m.copyWith(isYummie: !m.isYummie) : m)
        .toList();
    await ref.read(restaurantsProvider.notifier).updateRestaurant(
          restaurant.copyWith(menu: updatedMenu),
        );
  }

  Widget _buildOrderChecklist(
    BuildContext context,
    WidgetRef ref,
    bool isEditable,
    _OrderWithLabel orderWithLabel,
    Map<String, int> arrivedCounts,
    PersonalSubOrder? personalOrder,
    String userId,
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
              final menuItem =
                  restaurant?.menu.where((m) => m.id == item.menuItemId).firstOrNull;
              final isYummie = menuItem?.isYummie ?? false;
              final progress = total > 0 ? arrived / total : 0.0;

              return Column(
                children: [
                  ListTile(
                    leading: menuItem?.itemNumber != null
                        ? CircleAvatar(
                            radius: 14,
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            child: Text('${menuItem!.itemNumber}',
                                style: Theme.of(context).textTheme.labelSmall),
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
                          backgroundColor:
                              Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 4),
                        Text(l10n.checklistArrivedOf(arrived, total),
                            style: Theme.of(context).textTheme.bodySmall),
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
                          tooltip: isYummie
                              ? l10n.restaurantMenuRemoveYummie
                              : l10n.restaurantMenuMarkYummie,
                          onPressed: menuItem != null && restaurant != null
                              ? () => _toggleYummie(ref, restaurant, menuItem)
                              : null,
                        ),
                        if (isEditable) ...[
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: arrived > 0
                                ? () => _updateCount(ref, sessionId, userId,
                                    personalOrder, countKey, item.name, total, arrived - 1)
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: arrived < total
                                ? () => _updateCount(ref, sessionId, userId,
                                    personalOrder, countKey, item.name, total, arrived + 1)
                                : null,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (index < orderWithLabel.order.items.length - 1)
                    Divider(
                        height: 1,
                        color: Theme.of(context).colorScheme.outlineVariant),
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
