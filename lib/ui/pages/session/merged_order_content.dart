import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/session.dart';
import '../../../domain/models/personal_sub_order.dart';
import '../../../domain/models/order.dart';
import '../../../domain/models/restaurant.dart';
import '../../../core/utils/order_aggregator.dart';
import '../../../l10n/app_localizations.dart';
import '../../viewmodels/session_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/restaurant_viewmodel.dart';
import '../../viewmodels/personal_order_viewmodel.dart';

class MergedOrderContent extends ConsumerWidget {
  final String sessionId;

  const MergedOrderContent({super.key, required this.sessionId});

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
        final subOrdersAsync = ref.watch(subOrdersForSessionProvider(sessionId));
        final restaurantAsync = ref.watch(restaurantDetailProvider(session.restaurantId));

        return subOrdersAsync.when(
          data: (subOrders) {
            final activeOrders = subOrders.where((o) => o.entries.isNotEmpty).toList();
            final isHostOnly = session.participantIds.length == 1;
            final allReady = isHostOnly || activeOrders.every((o) => o.locked);
            final restaurant = restaurantAsync.valueOrNull;

            final allOrders = <_OrderWithLabel>[];
            if (session.mainOrder != null) {
              allOrders.add(_OrderWithLabel(session.mainOrder!, 'Order 1'));
            }
            for (int i = 0; i < session.additionalOrders.length; i++) {
              allOrders.add(_OrderWithLabel(session.additionalOrders[i], 'Order ${i + 2}'));
            }

            return Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildParticipantsSection(context, subOrders, session),
                  const SizedBox(height: 24),
                  if (session.status == SessionStatus.open) ...[
                    if (!isHostOnly && activeOrders.isNotEmpty && activeOrders.any((o) => !o.locked))
                      Card(
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber,
                                color: Theme.of(context).colorScheme.onErrorContainer,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.mergedOrderWaiting,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    _buildCurrentRound(context, activeOrders, allReady, restaurant),
                  ],
                  if (allOrders.isNotEmpty) ...[
                    if (session.status == SessionStatus.open) const SizedBox(height: 24),
                    for (int i = 0; i < allOrders.length; i++) ...[
                      if (i > 0) const SizedBox(height: 24),
                      _buildOrderSection(context, allOrders[i].label, allOrders[i].order, restaurant),
                    ],
                  ],
                  const SizedBox(height: 100),
                ],
              ),
              floatingActionButton: !isHost
                  ? null
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (session.status == SessionStatus.sent)
                          FloatingActionButton.extended(
                            heroTag: 'openRound',
                            onPressed: () => _showOpenRoundSheet(context, ref, session, activeOrders),
                            icon: const Icon(Icons.add),
                            label: Text(l10n.mergedOrderOpenRound),
                          ),
                        if (session.status == SessionStatus.sent) const SizedBox(height: 12),
                        if (session.status == SessionStatus.open && activeOrders.isNotEmpty)
                          FloatingActionButton.extended(
                            heroTag: 'sendOrder',
                            onPressed: () {
                              if (allReady) {
                                _sendOrder(context, ref, session, activeOrders);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(l10n.mergedOrderSendLocked)),
                                );
                              }
                            },
                            icon: const Icon(Icons.send),
                            label: Text(l10n.mergedOrderSend),
                          ),
                      ],
                    ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(l10n.errorMessage(error.toString()))),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(AppLocalizations.of(context)!.errorMessage(error.toString()))),
    );
  }

  Widget _buildParticipantsSection(BuildContext context, List<PersonalSubOrder> subOrders, Session session) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.mergedOrderParticipants,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            Chip(
              label: Text('${session.participantIds.length}'),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: session.participantIds.map((participantId) {
            final subOrder = subOrders.where((s) => s.userId == participantId).firstOrNull;
            final hasOrdered = subOrder != null && subOrder.entries.isNotEmpty;
            final displayName = subOrder?.userName ?? participantId.substring(0, 6);
            final picturePath = subOrder?.userProfilePicturePath;

            return ActionChip(
              avatar: CircleAvatar(
                backgroundImage: picturePath != null ? FileImage(File(picturePath)) : null,
                backgroundColor: hasOrdered
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                foregroundColor: hasOrdered
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                child: picturePath == null
                    ? Text(displayName.substring(0, 1).toUpperCase())
                    : null,
              ),
              label: Text(displayName),
              backgroundColor: hasOrdered
                  ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              onPressed: () => _showParticipantInfo(context, subOrder, displayName, subOrder?.userFullName, picturePath, hasOrdered),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showParticipantInfo(
    BuildContext context,
    PersonalSubOrder? subOrder,
    String displayName,
    String? fullName,
    String? picturePath,
    bool hasOrdered,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext)!;
        return SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: picturePath != null ? FileImage(File(picturePath)) : null,
                    backgroundColor: Theme.of(sheetContext).colorScheme.primaryContainer,
                    child: picturePath == null
                        ? Text(
                            displayName.substring(0, 1).toUpperCase(),
                            style: Theme.of(sheetContext).textTheme.headlineMedium,
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  if (fullName != null && fullName.isNotEmpty)
                    Text(
                      fullName,
                      style: Theme.of(sheetContext).textTheme.titleLarge,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '@$displayName',
                    style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                          color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(hasOrdered ? l10n.mergedParticipantOrderAdded : l10n.mergedParticipantNoOrder),
                    avatar: Icon(
                      hasOrdered ? Icons.check_circle : Icons.hourglass_empty,
                      size: 16,
                    ),
                    backgroundColor: hasOrdered
                        ? Theme.of(sheetContext).colorScheme.primaryContainer
                        : Theme.of(sheetContext).colorScheme.surfaceContainerHighest,
                  ),
                  if (subOrder != null && subOrder.entries.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.mergedParticipantItemsOrdered,
                        style: Theme.of(sheetContext).textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...subOrder.entries.map((e) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(e.name),
                          trailing: Text('x${e.quantity}'),
                        )),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentRound(BuildContext context, List<PersonalSubOrder> activeOrders, bool allReady, Restaurant? restaurant) {
    final l10n = AppLocalizations.of(context)!;

    if (activeOrders.isEmpty) {
      return Card(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.receipt_long, color: Theme.of(context).colorScheme.outline),
              const SizedBox(width: 8),
              Text(
                l10n.mergedOrderCurrentEmpty,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
      );
    }
    if (!allReady) return const SizedBox.shrink();
    return _buildAggregatedOrder(context, activeOrders, l10n.mergedOrderCurrentOrder, restaurant);
  }

  Widget _buildAggregatedOrder(BuildContext context, List<PersonalSubOrder> subOrders, String label, Restaurant? restaurant) {
    final aggregated = aggregateSubOrders(subOrders, label);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(label, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            if (aggregated.items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(l10n.mergedOrderNoItems, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline)),
              )
            else
              ...aggregated.items.map((item) {
                final menuItem = restaurant?.menu.where((m) => m.id == item.menuItemId).firstOrNull;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: menuItem?.itemNumber != null
                      ? CircleAvatar(radius: 14, backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: Text('${menuItem!.itemNumber}', style: Theme.of(context).textTheme.labelSmall))
                      : null,
                  title: Text(item.name),
                  subtitle: Text(l10n.mergedOrderBy(item.contributorIds.length)),
                  trailing: Text('x${item.quantity}', style: Theme.of(context).textTheme.titleLarge),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSection(BuildContext context, String label, Order order, Restaurant? restaurant) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
            ),
            Chip(
              label: Text(l10n.mergedOrderItemsCount(order.items.length)),
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Column(
            children: order.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final menuItem = restaurant?.menu.where((m) => m.id == item.menuItemId).firstOrNull;
              return Column(
                children: [
                  ListTile(
                    leading: menuItem?.itemNumber != null
                        ? CircleAvatar(radius: 14, backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: Text('${menuItem!.itemNumber}', style: Theme.of(context).textTheme.labelSmall))
                        : null,
                    title: Row(
                      children: [
                        if (menuItem?.isYummie ?? false) ...[const Icon(Icons.restaurant, size: 14), const SizedBox(width: 4)],
                        Expanded(child: Text(item.name)),
                      ],
                    ),
                    subtitle: Text(l10n.mergedOrderBy(item.contributorIds.length)),
                    trailing: Text('x${item.quantity}', style: Theme.of(context).textTheme.titleMedium),
                  ),
                  if (index < order.items.length - 1) const Divider(height: 1),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _sendOrder(
    BuildContext context,
    WidgetRef ref,
    Session session,
    List<PersonalSubOrder> subOrders,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final label = session.mainOrder == null ? 'Order 1' : 'Order ${session.additionalOrders.length + 2}';
    final aggregated = aggregateSubOrders(subOrders, label);

    Session updated;
    if (session.mainOrder == null) {
      updated = session.copyWith(
        mainOrder: aggregated,
        status: SessionStatus.sent,
        sentAt: DateTime.now(),
      );
    } else {
      updated = session.copyWith(
        additionalOrders: [...session.additionalOrders, aggregated],
        status: SessionStatus.sent,
        sentAt: DateTime.now(),
      );
    }

    await ref.read(sessionsProvider.notifier).updateSession(updated);

    for (final subOrder in subOrders) {
      final clearedSubOrder = subOrder.copyWith(locked: true, entries: [], updatedAt: DateTime.now());
      await ref.read(personalSubOrderRepositoryProvider).updateSubOrder(clearedSubOrder);
      ref.invalidate(personalOrderProvider('${session.id}:${subOrder.userId}'));
    }
    ref.invalidate(subOrdersForSessionProvider(session.id));
    ref.invalidate(sessionDetailProvider(session.id));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.mergedOrderSent(label))),
      );
    }
  }

  void _showOpenRoundSheet(
    BuildContext context,
    WidgetRef ref,
    Session session,
    List<PersonalSubOrder> subOrders,
  ) {
    final roundNumber = session.additionalOrders.length + 2;

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext)!;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.mergedOrderOpenRoundTitle(roundNumber),
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(l10n.mergedOrderOpenRoundDescription),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: Text(l10n.cancel),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        await _createRound(context, ref, session, roundNumber);
                      },
                      child: Text(l10n.mergedOrderOpenRoundButton),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _createRound(
    BuildContext context,
    WidgetRef ref,
    Session session,
    int roundNumber,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final updated = session.copyWith(
      status: SessionStatus.open,
    );

    await ref.read(sessionsProvider.notifier).updateSession(updated);

    final subOrders = await ref.read(personalSubOrderRepositoryProvider).getSubOrdersForSession(session.id);
    for (final subOrder in subOrders) {
      final unlockedSubOrder = subOrder.copyWith(
        locked: false,
        entries: [],
        updatedAt: DateTime.now(),
      );
      await ref.read(personalSubOrderRepositoryProvider).updateSubOrder(unlockedSubOrder);
    }

    ref.invalidate(subOrdersForSessionProvider(session.id));
    ref.invalidate(sessionDetailProvider(session.id));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.mergedOrderRoundOpened(roundNumber))),
      );
    }
  }
}

class _OrderWithLabel {
  final Order order;
  final String label;

  _OrderWithLabel(this.order, this.label);
}
