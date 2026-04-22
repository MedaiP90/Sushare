import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/session.dart';
import '../../../domain/models/personal_sub_order.dart';
import '../../../domain/models/order.dart';
import '../../../core/utils/order_aggregator.dart';
import '../../viewmodels/session_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/personal_order_viewmodel.dart';

class MergedOrderContent extends ConsumerWidget {
  final String sessionId;

  const MergedOrderContent({super.key, required this.sessionId});

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
        final subOrdersAsync = ref.watch(subOrdersForSessionProvider(sessionId));

        return subOrdersAsync.when(
          data: (subOrders) {
            final activeOrders = subOrders.where((o) => o.entries.isNotEmpty).toList();

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
                  if (session.status == SessionStatus.open && activeOrders.isNotEmpty) ...[
                    if (activeOrders.any((o) => !o.locked))
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
                                  'Waiting for all participants to lock their orders',
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
                    if (activeOrders.every((o) => o.locked))
                      _buildAggregatedOrder(context, activeOrders, 'Current Order'),
                  ],
                  if (allOrders.isEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 48),
                          Icon(
                            Icons.hourglass_empty,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No orders yet',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Participants will appear here when they add items',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    for (int i = 0; i < allOrders.length; i++) ...[
                      if (i > 0) const SizedBox(height: 24),
                      _buildOrderSection(context, allOrders[i].label, allOrders[i].order),
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
                            label: const Text('Open New Round'),
                          ),
                        if (session.status == SessionStatus.sent) const SizedBox(height: 12),
                        if (session.status == SessionStatus.open && activeOrders.isNotEmpty)
                          FloatingActionButton.extended(
                            heroTag: 'sendOrder',
                            onPressed: () {
                              if (activeOrders.every((o) => o.locked)) {
                                _sendOrder(context, ref, session, activeOrders);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('All participants must lock their orders first'),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.send),
                            label: const Text('Send Order'),
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

  Widget _buildParticipantsSection(BuildContext context, List<PersonalSubOrder> subOrders, Session session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Participants',
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
            
            return Chip(
              avatar: CircleAvatar(
                backgroundColor: hasOrdered
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                foregroundColor: hasOrdered
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                child: Text(participantId.substring(0, 1).toUpperCase()),
              ),
              label: Text('User ${participantId.substring(0, 6)}'),
              backgroundColor: hasOrdered
                  ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAggregatedOrder(BuildContext context, List<PersonalSubOrder> subOrders, String label) {
    final aggregated = aggregateSubOrders(subOrders, label);

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            if (aggregated.items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'No items yet',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              )
            else
              ...aggregated.items.map((item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.name),
                    subtitle: Text('By ${item.contributorIds.length} participant(s)'),
                    trailing: Text(
                      'x${item.quantity}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSection(BuildContext context, String label, Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            Chip(
              label: Text('${order.items.length} items'),
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
              return Column(
                children: [
                  ListTile(
                    title: Text(item.name),
                    subtitle: Text('By ${item.contributorIds.length} participant(s)'),
                    trailing: Text(
                      'x${item.quantity}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
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
      final lockedSubOrder = subOrder.copyWith(locked: true);
      await ref.read(personalSubOrderRepositoryProvider).updateSubOrder(lockedSubOrder);
    }
    ref.invalidate(subOrdersForSessionProvider(session.id));
    ref.invalidate(sessionDetailProvider(session.id));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label sent! Participants can no longer edit.')),
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
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Open Round $roundNumber',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const Text(
                'This will allow participants to add items to a new order. '
                'Current orders will be locked.',
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _createRound(context, ref, session, roundNumber);
                    },
                    child: const Text('Open Round'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createRound(
    BuildContext context,
    WidgetRef ref,
    Session session,
    int roundNumber,
  ) async {
    final updated = session.copyWith(
      status: SessionStatus.open,
    );

    await ref.read(sessionsProvider.notifier).updateSession(updated);

    final subOrders = await ref.read(personalSubOrderRepositoryProvider).getSubOrdersForSession(session.id);
    for (final subOrder in subOrders) {
      final unlockedSubOrder = subOrder.copyWith(
        locked: false,
        entries: [],
        checklist: [],
        updatedAt: DateTime.now(),
      );
      await ref.read(personalSubOrderRepositoryProvider).updateSubOrder(unlockedSubOrder);
    }

    ref.invalidate(subOrdersForSessionProvider(session.id));
    ref.invalidate(sessionDetailProvider(session.id));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Round $roundNumber opened! Participants can add new items.')),
      );
    }
  }
}

class _OrderWithLabel {
  final Order order;
  final String label;

  _OrderWithLabel(this.order, this.label);
}
