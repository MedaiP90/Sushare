import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/providers.dart';
import '../../../core/utils/network_utils.dart';
import '../../../domain/models/local_user.dart';
import '../../../domain/models/session.dart';
import '../../../domain/models/personal_sub_order.dart';
import '../../../domain/models/restaurant.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/sync_message.dart';
import '../../viewmodels/session_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/restaurant_viewmodel.dart';
import '../../viewmodels/personal_order_viewmodel.dart';
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
  bool _serverStarted = false;
  bool _isGuest = false;
  bool _guestConnected = false;
  SessionStatus? _lastKnownStatus;

  StreamSubscription<SyncMessage>? _hostMsgSub;
  StreamSubscription<SyncMessage>? _clientMsgSub;
  StreamSubscription<bool>? _clientConnSub;
  StreamSubscription<void>? _sessionClosedSub;
  Timer? _reconnectTimer;

  @override
  void dispose() {
    _hostMsgSub?.cancel();
    _clientMsgSub?.cancel();
    _clientConnSub?.cancel();
    _sessionClosedSub?.cancel();
    _reconnectTimer?.cancel();
    ref.read(sessionClientServiceProvider).disconnect();
    if (_isGuest) {
      final repo = ref.read(sessionRepositoryProvider);
      final sessionId = widget.sessionId;
      () async {
        try {
          final s = await repo.getSessionById(sessionId);
          if (s?.hostAddress != null) {
            await repo.saveSession(s!.copyWith(hostAddress: null));
          }
        } catch (_) {}
      }();
    }
    super.dispose();
  }

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

        if (isHost && session.status != SessionStatus.closed && !_serverStarted) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _startHostServer(session));
        }

        if (!isHost && session.hostAddress != null && !_guestConnected && session.status != SessionStatus.closed && user != null) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _connectAsGuest(session, user));
        }

        // Host: 3 tabs. Guest: 2 tabs (no Group view).
        final tabs = isHost
            ? [
                PersonalOrderContent(sessionId: widget.sessionId),
                MergedOrderContent(sessionId: widget.sessionId),
                ChecklistContent(sessionId: widget.sessionId),
              ]
            : [
                PersonalOrderContent(sessionId: widget.sessionId),
                ChecklistContent(sessionId: widget.sessionId),
              ];

        // Clamp index when switching between host/guest roles
        final safeIndex = _currentIndex.clamp(0, tabs.length - 1);

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
                  onPressed: () async => _showShareSheet(context, l10n),
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
                      final hostServer = ref.read(hostServerServiceProvider);
                      hostServer.sendSessionClosedToGuests();
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
                      final hostServer = ref.read(hostServerServiceProvider);
                      hostServer.sendSessionClosedToGuests();
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
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: double.infinity),
                  child: Material(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.lock_outline, size: 16,
                              color: Theme.of(context).colorScheme.onSecondaryContainer),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.sessionClosedBanner,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (!isHost && !_guestConnected && session.status != SessionStatus.closed)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: double.infinity),
                  child: Material(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.wifi_off, size: 16,
                              color: Theme.of(context).colorScheme.onErrorContainer),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.sessionUnreachableBanner,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onErrorContainer,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(child: tabs[safeIndex]),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: safeIndex,
            onDestinationSelected: (index) => setState(() => _currentIndex = index),
            destinations: isHost
                ? [
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
                  ]
                : [
                    NavigationDestination(
                      icon: const Icon(Icons.person_outline),
                      selectedIcon: const Icon(Icons.person),
                      label: l10n.sessionTabMyOrder,
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
      loading: () => Scaffold(
          appBar: AppBar(), body: const Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
            child: Text(AppLocalizations.of(context)!.errorMessage(error.toString()))),
      ),
    );
  }

  // ── Host ─────────────────────────────────────────────────────────────────

  Future<void> _startHostServer(Session session) async {
    if (_serverStarted) return;
    final server = ref.read(hostServerServiceProvider);
    try {
      await server.start();
      server.setSession(session);
      _lastKnownStatus = session.status;

      final restaurantRepo = ref.read(restaurantRepositoryProvider);
      final restaurant = await restaurantRepo.getRestaurantById(session.restaurantId);
      if (restaurant != null) server.setRestaurant(restaurant);

      // Seed server memory with existing sub orders
      final subOrderRepo = ref.read(personalSubOrderRepositoryProvider);
      final existingSubOrders = await subOrderRepo.getSubOrdersForSession(session.id);
      for (final so in existingSubOrders) {
        server.upsertSubOrder(so);
      }

      _hostMsgSub = server.messages.listen(_handleHostMessage);

      if (mounted) setState(() => _serverStarted = true);
    } catch (_) {}
  }

  Future<void> _handleHostMessage(SyncMessage msg) async {
    if (!mounted) return;

    switch (msg.type) {
      case SyncMessageType.userInfo:
        final userId = msg.data['userId'] as String?;
        if (userId == null) return;
        final sessionRepo = ref.read(sessionRepositoryProvider);
        await sessionRepo.addParticipant(widget.sessionId, userId);
        if (mounted) ref.invalidate(sessionDetailProvider(widget.sessionId));

        // Broadcast updated session to all guests
        final updatedSession =
            await sessionRepo.getSessionById(widget.sessionId);
        if (updatedSession != null) {
          ref.read(hostServerServiceProvider).setSession(updatedSession);
        }

      case SyncMessageType.subOrderUpdate:
        final subOrder = PersonalSubOrder.fromJson(msg.data);
        final subOrderRepo = ref.read(personalSubOrderRepositoryProvider);
        final existing =
            await subOrderRepo.getSubOrder(subOrder.sessionId, subOrder.userId);
        if (existing != null) {
          // Preserve local checklist data; remote strips checklist before sending
          await subOrderRepo.updateSubOrder(subOrder.copyWith(checklist: existing.checklist));
        } else {
          await subOrderRepo.saveSubOrder(subOrder);
        }
        if (mounted) {
          ref.invalidate(subOrdersForSessionProvider(subOrder.sessionId));
        }

      default:
        break;
    }
  }

  // ── Guest ─────────────────────────────────────────────────────────────────

  Future<void> _connectAsGuest(Session session, LocalUser user) async {
    if (_guestConnected) return;
    _isGuest = true;
    final client = ref.read(sessionClientServiceProvider);

    _clientConnSub?.cancel();
    _clientConnSub = client.connectionStatus.listen((connected) {
      if (!mounted) return;
      if (!connected) _scheduleReconnect(session, user);
    });

    _clientMsgSub?.cancel();
    _clientMsgSub = client.messages.listen((msg) => _handleGuestMessage(msg, session));

    _sessionClosedSub?.cancel();
    _sessionClosedSub = client.sessionClosed.listen((_) {
      if (!mounted) return;
      client.markSessionClosed();
      final sessionRepo = ref.read(sessionRepositoryProvider);
      final closedSession = session.copyWith(status: SessionStatus.closed);
      sessionRepo.saveSession(closedSession);
      ref.invalidate(sessionDetailProvider(session.id));
      ref.invalidate(sessionsProvider);
      setState(() {
        _guestConnected = false;
      });
    });

    final connected = await client.connect(
      hostAddress: session.hostAddress!,
      userId: user.id,
      userName: user.username,
      userFullName: '${user.firstName} ${user.lastName}'.trim(),
      userProfilePicturePath: user.profilePicturePath,
    );

    if (mounted) {
      setState(() {
        _guestConnected = connected;
      });
    }
  }

  void _scheduleReconnect(Session session, LocalUser user) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () async {
      if (!mounted) return;
      final client = ref.read(sessionClientServiceProvider);
      if (client.isSessionClosed) return;
      if (!client.isConnected) {
        await client.connect(
          hostAddress: session.hostAddress!,
          userId: user.id,
          userName: user.username,
          userFullName: '${user.firstName} ${user.lastName}'.trim(),
          userProfilePicturePath: user.profilePicturePath,
        );
      }
    });
  }

  Future<void> _handleGuestMessage(SyncMessage msg, Session currentSession) async {
    if (!mounted) return;

    final sessionRepo = ref.read(sessionRepositoryProvider);
    final restaurantRepo = ref.read(restaurantRepositoryProvider);
    final subOrderRepo = ref.read(personalSubOrderRepositoryProvider);
    final LocalUser? user = ref.read(profileViewModelProvider).value;

    switch (msg.type) {
      case SyncMessageType.initialSync:
        if (msg.data['session'] != null) {
          final session = Session.fromJson(msg.data['session'] as Map<String, dynamic>);
          final withAddr = session.copyWith(hostAddress: currentSession.hostAddress);
          await sessionRepo.saveSession(withAddr);
          _lastKnownStatus = withAddr.status;
          if (mounted) {
            ref.invalidate(sessionDetailProvider(withAddr.id));
            ref.invalidate(sessionsProvider); // update table list immediately
          }
        }
        if (msg.data['restaurant'] != null) {
          final remote =
              Restaurant.fromJson(msg.data['restaurant'] as Map<String, dynamic>);
          final local = await restaurantRepo.getRestaurantById(remote.id);
          await restaurantRepo.saveRestaurant(_mergeRestaurant(remote, local));
          if (mounted) ref.invalidate(restaurantDetailProvider(remote.id));
        }
        final subOrdersJson = msg.data['subOrders'] as List<dynamic>? ?? [];
        for (final raw in subOrdersJson) {
          final so = PersonalSubOrder.fromJson(raw as Map<String, dynamic>);
          if (so.userId == user?.id) continue;
          final existing = await subOrderRepo.getSubOrder(so.sessionId, so.userId);
          if (existing != null) {
            // Preserve local checklist; remote has no checklist data
            await subOrderRepo.updateSubOrder(so.copyWith(checklist: existing.checklist));
          } else {
            await subOrderRepo.saveSubOrder(so);
          }
        }
        if (mounted) ref.invalidate(subOrdersForSessionProvider(currentSession.id));

      case SyncMessageType.sessionUpdate:
        final newSession = Session.fromJson(msg.data);
        final withAddr = newSession.copyWith(hostAddress: currentSession.hostAddress);
        await sessionRepo.saveSession(withAddr);

        final prevStatus = _lastKnownStatus;
        _lastKnownStatus = withAddr.status;

        if (user != null) {
          final needsClear = (withAddr.status == SessionStatus.sent &&
                  prevStatus != SessionStatus.sent) ||
              (withAddr.status == SessionStatus.open &&
                  prevStatus == SessionStatus.sent);
          if (needsClear) {
            final mine = await subOrderRepo.getSubOrder(currentSession.id, user.id);
            if (mine != null) {
              await subOrderRepo.updateSubOrder(
                  mine.copyWith(entries: [], updatedAt: DateTime.now()));
              if (mounted) {
                ref.invalidate(personalOrderProvider('${currentSession.id}:${user.id}'));
              }
            }
          }
        }

        if (mounted) {
          ref.invalidate(sessionDetailProvider(withAddr.id));
          ref.invalidate(sessionsProvider);
        }

      case SyncMessageType.restaurantUpdate:
        final remote = Restaurant.fromJson(msg.data);
        final local = await restaurantRepo.getRestaurantById(remote.id);
        await restaurantRepo.saveRestaurant(_mergeRestaurant(remote, local));
        if (mounted) ref.invalidate(restaurantDetailProvider(remote.id));

      case SyncMessageType.sessionClosed:
        final client = ref.read(sessionClientServiceProvider);
        client.markSessionClosed();
        final closedSession = currentSession.copyWith(status: SessionStatus.closed);
        await sessionRepo.saveSession(closedSession);
        if (mounted) {
          ref.invalidate(sessionDetailProvider(currentSession.id));
          ref.invalidate(sessionsProvider);
        }

      case SyncMessageType.subOrderBroadcast:
        final so = PersonalSubOrder.fromJson(msg.data);
        if (so.userId == user?.id) return;
        final existing = await subOrderRepo.getSubOrder(so.sessionId, so.userId);
        if (existing != null) {
          await subOrderRepo.updateSubOrder(so.copyWith(checklist: existing.checklist));
        } else {
          await subOrderRepo.saveSubOrder(so);
        }
        if (mounted) ref.invalidate(subOrdersForSessionProvider(so.sessionId));

      default:
        break;
    }
  }

  /// Merges a remote restaurant into local, preserving the user's isYummie flags.
  Restaurant _mergeRestaurant(Restaurant remote, Restaurant? local) {
    if (local == null) return remote;
    final localYummies = {
      for (final item in local.menu)
        if (item.isYummie) item.id: true,
    };
    final merged = remote.menu
        .map((item) => item.copyWith(isYummie: localYummies[item.id] ?? item.isYummie))
        .toList();
    return remote.copyWith(menu: merged);
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

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
                    backgroundColor: Theme.of(context).colorScheme.error)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  Future<void> _showShareSheet(BuildContext context, AppLocalizations l10n) async {
    final serverService = ref.read(hostServerServiceProvider);
    String? hostAddress;
    if (serverService.isRunning) {
      final ip = await getLocalIpAddress();
      if (ip != null) hostAddress = '$ip:${serverService.port}';
    }
    final qrData = hostAddress != null
        ? 'sushare://join/${widget.sessionId}?host=$hostAddress'
        : 'sushare://join/${widget.sessionId}';

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.shareTableTitle,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Text(l10n.shareTableQrHint),
                  const SizedBox(height: 16),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(12),
                    child: QrImageView(data: qrData, size: 200),
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.shareTableCodeHint,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  SelectableText(
                    widget.sessionId.substring(0, 8).toUpperCase(),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (hostAddress != null) ...[
                    const SizedBox(height: 8),
                    Text(l10n.joinTableHostLabel,
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    SelectableText(hostAddress,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
