import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../domain/models/session.dart';
import '../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;

    return sessionAsync.when(
      data: (session) {
        if (session == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(l10n.sessionTableNotFound)),
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
              if (isHost && session.status != SessionStatus.closed)
                IconButton(
                  onPressed: () => _showShareSheet(context, l10n),
                  icon: const Icon(Icons.share),
                  tooltip: l10n.sessionShareTooltip,
                ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'close') {
                    final confirm = await _showConfirmSheet(
                      context,
                      l10n.sessionCloseTitle,
                      l10n.sessionCloseMessage,
                      l10n.sessionCloseButton,
                    );
                    if (confirm == true && context.mounted) {
                      await ref
                          .read(sessionsProvider.notifier)
                          .closeSession(widget.sessionId);
                    }
                  } else if (value == 'delete') {
                    final confirm = await _showConfirmSheet(
                      context,
                      l10n.sessionDeleteTitle,
                      l10n.sessionDeleteMessage2,
                      l10n.delete,
                      isDestructive: true,
                    );
                    if (confirm == true && context.mounted) {
                      await ref
                          .read(sessionsProvider.notifier)
                          .deleteSession(widget.sessionId);
                      if (context.mounted) context.go('/home/sessions');
                    }
                  }
                },
                itemBuilder: (context) => [
                  if (session.status != SessionStatus.closed)
                    PopupMenuItem(value: 'close', child: Text(l10n.sessionLeaveTableMenu)),
                  PopupMenuItem(value: 'delete', child: Text(l10n.sessionDeleteTableMenu)),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              if (session.status == SessionStatus.closed)
                Material(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.sessionClosedBanner,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSecondaryContainer,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(child: tabs[_currentIndex]),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) => setState(() => _currentIndex = index),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: l10n.sessionTabMyOrder,
              ),
              NavigationDestination(
                icon: const Icon(Icons.groups_outlined),
                selectedIcon: const Icon(Icons.groups),
                label: l10n.sessionTabGroup,
              ),
              NavigationDestination(
                icon: const Icon(Icons.checklist_outlined),
                selectedIcon: const Icon(Icons.checklist),
                label: l10n.sessionTabChecklist,
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(AppLocalizations.of(context)!.errorMessage(error.toString()))),
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
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
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

  void _showShareSheet(BuildContext context, AppLocalizations l10n) {
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
                Text(l10n.shareTableTitle, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Text(l10n.shareTableQrHint),
                const SizedBox(height: 16),
                QrImageView(data: 'sushare://join/${widget.sessionId}', size: 200),
                const SizedBox(height: 16),
                Text(l10n.shareTableCodeHint, style: Theme.of(context).textTheme.bodySmall),
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
      ),
    );
  }
}
