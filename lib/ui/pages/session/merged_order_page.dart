import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/session.dart';
import '../../../domain/models/personal_sub_order.dart';
import '../../viewmodels/session_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/personal_order_viewmodel.dart';
import '../../../core/utils/order_aggregator.dart';

class MergedOrderPage extends ConsumerWidget {
  final String sessionId;

  const MergedOrderPage({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionDetailProvider(sessionId));
    final user = ref.watch(profileViewModelProvider).value;

    return sessionAsync.when(
      data: (session) {
        if (session == null) {
          return const Scaffold(
            body: Center(child: Text('Session not found')),
          );
        }

        final isHost = user?.id == session.hostUserId;
        final subOrdersAsync = ref.watch(subOrdersForSessionProvider(sessionId));

        return subOrdersAsync.when(
          data: (subOrders) {
            final activeOrders = subOrders.where((o) => o.entries.isNotEmpty).toList();
            
            return Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Group Order',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (session.status.name == 'sent')
                        Chip(
                          label: const Text('Sent'),
                          avatar: const Icon(Icons.check, size: 16),
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (activeOrders.isEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(
                              Icons.hourglass_empty,
                              size: 48,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Waiting for orders',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Participants haven\'t sent their orders yet',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Participants (${activeOrders.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...activeOrders.map((order) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Color(order.userId.hashCode.abs() % 0xFFFFFFFF),
                              child: Text(
                                order.userId.substring(0, 1).toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text('User ${order.userId.substring(0, 6)}'),
                            subtitle: Text('${order.entries.length} items'),
                            trailing: order.locked
                                ? const Icon(Icons.lock, size: 16)
                                : const Icon(Icons.edit, size: 16),
                          ),
                        )),
                    const SizedBox(height: 16),
                    if (session.status.name == 'open') ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Aggregated Order',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
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
                                    'Some participants haven\'t locked their orders yet',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (activeOrders.every((o) => o.locked))
                        _buildAggregatedOrder(context, activeOrders),
                    ],
                    if (session.status.name == 'sent' && session.mainOrder != null) ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.receipt,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Main Order',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                              const Divider(),
                              ...session.mainOrder!.items.map((item) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(item.name),
                                    subtitle: Text('By: ${item.contributorIds.length} person(s)'),
                                    trailing: Text(
                                      'x${item.quantity}',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),
                  if (session.additionalOrders.isNotEmpty) ...[
                    Text(
                      'Additional Rounds',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...session.additionalOrders.map((order) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.label,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const Divider(),
                                ...order.items.map((item) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(item.name),
                                      trailing: Text('x${item.quantity}'),
                                    )),
                              ],
                            ),
                          ),
                        )),
                  ],
                ],
              ),
              floatingActionButton: Builder(
                builder: (context) {
                  if (!isHost) return const SizedBox.shrink();
                  
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (session.status.name == 'sent')
                        FloatingActionButton.extended(
                          onPressed: () => _showAddRoundDialog(context, ref, session, activeOrders),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Round'),
                        ),
                      const SizedBox(height: 8),
                      if (session.status.name == 'open' && activeOrders.isNotEmpty)
                        FloatingActionButton.extended(
                          onPressed: activeOrders.every((o) => o.locked)
                              ? () => _sendOrder(context, ref, session, activeOrders)
                              : null,
                          icon: const Icon(Icons.send),
                          label: const Text('Send Order'),
                        ),
                    ],
                  );
                },
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

  Widget _buildAggregatedOrder(BuildContext context, List<PersonalSubOrder> subOrders) {
    final aggregated = aggregateSubOrders(subOrders, 'Main Order');
    
    return Card(
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
                  'Main Order',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            if (aggregated.items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
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
                    subtitle: Text('By: ${item.contributorIds.length} person(s)'),
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

  Future<void> _sendOrder(
    BuildContext context,
    WidgetRef ref,
    Session session,
    List<PersonalSubOrder> subOrders,
  ) async {
    final aggregated = aggregateSubOrders(subOrders, 'Main Order');
    
    final updated = session.copyWith(
      mainOrder: aggregated,
      status: SessionStatus.sent,
      sentAt: DateTime.now(),
    );
    
    await ref.read(sessionsProvider.notifier).updateSession(updated);
    
if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order sent!')),
      );
    }
  }

  void _showAddRoundDialog(
    BuildContext context,
    WidgetRef ref,
    Session session,
    List<PersonalSubOrder> subOrders,
  ) {
    int roundNumber = session.additionalOrders.length + 2;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Round $roundNumber'),
        content: Text(
          'This will allow participants to add more items to a new round. '
          'Only participants who have locked their orders can participate in the new round.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _createRound(context, ref, session, roundNumber);
            },
            child: const Text('Create Round'),
          ),
        ],
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
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Round $roundNumber created! Participants can now add items.')),
      );
    }
  }
}