import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/order.dart';
import '../../viewmodels/session_viewmodel.dart';

class MergedOrderPage extends ConsumerWidget {
  final String sessionId;

  const MergedOrderPage({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionDetailProvider(sessionId));

    return sessionAsync.when(
      data: (session) {
        if (session == null) {
          return const Scaffold(
            body: Center(child: Text('Session not found')),
          );
        }

        return Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Group Order',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (session.status.name == 'sent' && session.mainOrder != null) ...[
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
                              subtitle: Text('Ordered by: ${item.contributorIds.length} person(s)'),
                              trailing: Text(
                                'x${item.quantity}',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.hourglass_empty, size: 48),
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