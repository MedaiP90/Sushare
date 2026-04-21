import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../domain/models/session.dart';
import '../../viewmodels/session_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';

class SessionShellPage extends ConsumerStatefulWidget {
  final String sessionId;

  const SessionShellPage({super.key, required this.sessionId});

  @override
  ConsumerState<SessionShellPage> createState() => _SessionShellPageState();
}

class _SessionShellPageState extends ConsumerState<SessionShellPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionDetailProvider(widget.sessionId));
    final user = ref.watch(profileViewModelProvider).value;

    return sessionAsync.when(
      data: (session) {
        if (session == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Session not found')),
          );
        }

        final isHost = user?.id == session.hostUserId;
        final isOpen = session.status == SessionStatus.open;

        return Scaffold(
          appBar: AppBar(
            title: Text(session.name),
            centerTitle: true,
            actions: [
              if (isHost && isOpen)
                IconButton(
                  onPressed: () => _showShareDialog(context),
                  icon: const Icon(Icons.share),
                  tooltip: 'Share session',
                ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'close') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Close Session'),
                        content: const Text('Are you sure? Participants won\'t be able to join or order.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      await ref.read(sessionsProvider.notifier).closeSession(widget.sessionId);
                    }
                  } else if (value == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Session'),
                        content: const Text('Are you sure you want to delete this session?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.error,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      await ref.read(sessionsProvider.notifier).deleteSession(widget.sessionId);
                      if (context.mounted) context.go('/home/sessions');
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'close', child: Text('Close for new participants')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete session')),
                ],
              ),
            ],
          ),
          body: GoRouterState.of(context).uri.path.endsWith('/order')
              ? const SizedBox.shrink()
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
              switch (index) {
                case 0:
                  context.go('/sessions/${widget.sessionId}/order');
                  break;
                case 1:
                  context.go('/sessions/${widget.sessionId}/merged');
                  break;
                case 2:
                  context.go('/sessions/${widget.sessionId}/checklist');
                  break;
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.edit_note_outlined),
                selectedIcon: Icon(Icons.edit_note),
                label: 'My Order',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Group Order',
              ),
              NavigationDestination(
                icon: Icon(Icons.checklist_outlined),
                selectedIcon: Icon(Icons.checklist),
                label: 'Checklist',
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  void _showShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Let others join by scanning this QR code:'),
            const SizedBox(height: 16),
            QrImageView(
              data: 'sushare://join/${widget.sessionId}',
              size: 200,
            ),
            const SizedBox(height: 16),
            Text(
              'Or enter this code:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            SelectableText(
              widget.sessionId.substring(0, 8).toUpperCase(),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}