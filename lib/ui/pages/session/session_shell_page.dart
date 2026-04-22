import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../domain/models/session.dart';
import '../../viewmodels/session_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import 'personal_order_content.dart';
import 'merged_order_content.dart';
import 'checklist_content.dart';

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
            body: const Center(child: Text('Table not found')),
          );
        }

        final isHost = user?.id == session.hostUserId;

        final tabs = [
          PersonalOrderContent(sessionId: widget.sessionId),
          MergedOrderContent(sessionId: widget.sessionId),
          ChecklistContent(sessionId: widget.sessionId),
        ];

        return Scaffold(
          appBar: AppBar(
            title: Text(session.name),
            centerTitle: true,
            automaticallyImplyLeading: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/home/sessions'),
            ),
            actions: [
              if (isHost && session.status == SessionStatus.open)
                IconButton(
                  onPressed: () => _showShareSheet(context),
                  icon: const Icon(Icons.share),
                  tooltip: 'Share table',
                ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'close') {
                    final confirm = await _showConfirmSheet(
                      context,
                      'Close Table',
                      'Are you sure? Participants won\'t be able to join or order.',
                      'Close',
                    );
                    if (confirm == true && context.mounted) {
                      await ref.read(sessionsProvider.notifier).closeSession(widget.sessionId);
                    }
                  } else if (value == 'delete') {
                    final confirm = await _showConfirmSheet(
                      context,
                      'Delete Table',
                      'Are you sure you want to delete this table?',
                      'Delete',
                      isDestructive: true,
                    );
                    if (confirm == true && context.mounted) {
                      await ref.read(sessionsProvider.notifier).deleteSession(widget.sessionId);
                      if (context.mounted) context.go('/home/sessions');
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'close', child: Text('Close for new participants')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete table')),
                ],
              ),
            ],
          ),
          body: tabs[_currentIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'My Order',
              ),
              NavigationDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups),
                label: 'Group',
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

  Future<bool?> _showConfirmSheet(
    BuildContext context,
    String title,
    String message,
    String confirmText, {
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: isDestructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  )
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  void _showShareSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Share Session',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
