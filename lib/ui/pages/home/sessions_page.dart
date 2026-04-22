import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../domain/models/session.dart';
import '../../viewmodels/session_viewmodel.dart';
import '../../viewmodels/restaurant_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';

class SessionsPage extends ConsumerWidget {
  const SessionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tables'),
        centerTitle: true,
      ),
      body: sessionsAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return _EmptyState(
              onNew: () async {
                await context.push('/sessions/new');
                ref.invalidate(sessionsProvider);
              },
              onJoin: () async {
                await context.push('/sessions/join');
                ref.invalidate(sessionsProvider);
              },
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: sessions.length,
            itemBuilder: (context, index) => _SessionCard(
              session: sessions[index],
              onTap: () =>
                  context.push('/sessions/${sessions[index].id}'),
              onLongPress: () =>
                  _showSessionActions(context, ref, sessions[index]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('Error: $e'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(sessionsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'join',
            onPressed: () async {
              await context.push('/sessions/join');
              ref.invalidate(sessionsProvider);
            },
            tooltip: 'Join table',
            child: const Icon(Icons.qr_code_scanner),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'new',
            onPressed: () async {
              await context.push('/sessions/new');
              ref.invalidate(sessionsProvider);
            },
            icon: const Icon(Icons.add),
            label: const Text('New Table'),
          ),
        ],
      ),
    );
  }

  void _showSessionActions(
      BuildContext context, WidgetRef ref, Session session) {
    final currentUser = ref.read(profileViewModelProvider).value;
    final isHost = currentUser?.id == session.hostUserId;

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  session.name,
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (isHost && session.status != SessionStatus.closed)
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share table'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showShareSheet(context, session.id);
                },
              ),
            if (session.status != SessionStatus.closed)
              ListTile(
                leading: const Icon(Icons.exit_to_app),
                title: const Text('Leave the table'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Leave the table'),
                      content: const Text(
                          'The table will be frozen. No one will be able to join or make changes.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Leave'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await ref
                        .read(sessionsProvider.notifier)
                        .closeSession(session.id);
                  }
                },
              ),
            ListTile(
              leading: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error),
              title: Text('Delete',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error)),
              onTap: () async {
                Navigator.pop(sheetContext);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Table'),
                    content: Text(
                        'Are you sure you want to delete "${session.name}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.error,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await ref
                      .read(sessionsProvider.notifier)
                      .deleteSession(session.id);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
        ),
      ),
    );
  }

  void _showShareSheet(BuildContext context, String sessionId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Share Table',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                const Text('Let others join by scanning this QR code:'),
                const SizedBox(height: 16),
                QrImageView(
                  data: 'sushare://join/$sessionId',
                  size: 200,
                ),
                const SizedBox(height: 16),
                Text(
                  'Or enter this code:',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                SelectableText(
                  sessionId.substring(0, 8).toUpperCase(),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends ConsumerWidget {
  final Session session;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _SessionCard(
      {required this.session,
      required this.onTap,
      required this.onLongPress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantsAsync = ref.watch(restaurantsProvider);
    final userAsync = ref.watch(profileViewModelProvider);
    final scheme = Theme.of(context).colorScheme;

    final restaurantName = restaurantsAsync.maybeWhen(
      data: (list) =>
          list
              .where((r) => r.id == session.restaurantId)
              .firstOrNull
              ?.name ??
          'Unknown restaurant',
      orElse: () => '…',
    );

    final isHost = userAsync.value?.id == session.hostUserId;

    final (statusColor, statusLabel) = switch (session.status) {
      SessionStatus.open => (scheme.primary, 'Open'),
      SessionStatus.sent => (scheme.tertiary, 'Order sent'),
      SessionStatus.closed => (scheme.outline, 'Closed'),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      session.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.restaurant,
                      size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    restaurantName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.people_outline,
                      size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${session.participantIds.length}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  if (isHost) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.star, size: 14, color: scheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Host',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.primary),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(session.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.outline,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onNew;
  final Future<void> Function() onJoin;

  const _EmptyState({required this.onNew, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, size: 80, color: scheme.outline),
            const SizedBox(height: 16),
            Text(
              'No tables yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Start a new table to order together, or join one from a friend.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.outline),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onNew,
              icon: const Icon(Icons.add),
label: const Text('New Table'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onJoin,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Join a Table'),
            ),
          ],
        ),
      ),
    );
  }
}
