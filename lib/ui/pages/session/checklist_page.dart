import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/session.dart';
import '../../viewmodels/session_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';

class ChecklistPage extends ConsumerStatefulWidget {
  final String sessionId;

  const ChecklistPage({super.key, required this.sessionId});

  @override
  ConsumerState<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends ConsumerState<ChecklistPage> {
  final _arrivedCounts = <String, int>{};

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

        final isHost = user?.id == session.hostUserId;

        if (session.mainOrder == null) {
          return Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Checklist',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No order to track',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'The main order hasn\'t been sent yet',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final allArrived = session.mainOrder!.items.every((item) {
          final arrived = _arrivedCounts[item.menuItemId] ?? 0;
          return arrived >= item.quantity;
        });

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
                'Track what has arrived from the order',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
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
                      ...session.mainOrder!.items.map((item) {
                        final arrived = _arrivedCounts[item.menuItemId] ?? 0;
                        final total = item.quantity;
                        final progress = arrived / total;

                        return Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(item.name),
                              subtitle: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isHost)
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
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      '$arrived / $total arrived',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: arrived == total
                                                ? Theme.of(context).colorScheme.primary
                                                : null,
                                          ),
                                    ),
                                  ),
                                  if (isHost)
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
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (session.additionalOrders.isNotEmpty) ...[
                Text(
                  'Additional Rounds',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...session.additionalOrders.asMap().entries.map((entry) {
                  final index = entry.key;
                  final order = entry.value;
                  return Card(
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
                          ...order.items.map((item) {
                            final arrived = _arrivedCounts[item.menuItemId] ?? 0;
                            final total = item.quantity;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(item.name),
                              trailing: Text(
                                '$arrived / $total',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 16),
              if (!isHost)
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Only the host can update arrival status',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
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
}
