import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/order.dart';
import '../../viewmodels/session_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';

class ChecklistContent extends ConsumerStatefulWidget {
  final String sessionId;

  const ChecklistContent({super.key, required this.sessionId});

  @override
  ConsumerState<ChecklistContent> createState() => _ChecklistContentState();
}

class _ChecklistContentState extends ConsumerState<ChecklistContent> {
  final _arrivedCounts = <String, int>{};

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionDetailProvider(widget.sessionId));
    final user = ref.watch(profileViewModelProvider).value;

    return sessionAsync.when(
      data: (session) {
        if (session == null) {
          return const Center(child: Text('Table not found'));
        }

        final isHost = user?.id == session.hostUserId;

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

        final allArrived = allOrders.every((o) =>
            o.order.items.every((item) {
              final arrived = _arrivedCounts[item.menuItemId] ?? 0;
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
                _buildOrderChecklist(context, isHost, allOrders[i]),
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

  Widget _buildOrderChecklist(BuildContext context, bool isHost, _OrderWithLabel orderWithLabel) {
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
              final arrived = _arrivedCounts[item.menuItemId] ?? 0;
              final total = item.quantity;
              final progress = arrived / total;

              return Column(
                children: [
                  ListTile(
                    title: Text(
                      item.name,
                      style: arrived >= total
                          ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: Theme.of(context).colorScheme.outline,
                              )
                          : null,
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
                    trailing: isHost
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: arrived > 0
                                    ? () {
                                        setState(() {
                                          _arrivedCounts[item.menuItemId] = arrived - 1;
                                        });
                                      }
                                    : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: arrived < total
                                    ? () {
                                        setState(() {
                                          _arrivedCounts[item.menuItemId] = arrived + 1;
                                        });
                                      }
                                    : null,
                              ),
                            ],
                          )
                        : null,
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