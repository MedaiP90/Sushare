import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/session_viewmodel.dart';

class ChecklistPage extends ConsumerWidget {
  final String sessionId;

  const ChecklistPage({super.key, required this.sessionId});

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
                'Checklist',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Track what has arrived',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              if (session.mainOrder == null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 48),
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
                )
              else
                ...session.mainOrder!.items.map((item) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(item.name),
                        subtitle: Text('Ordered: ${item.quantity}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {},
                            ),
                            Text(
                              '0/${item.quantity}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    )),
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