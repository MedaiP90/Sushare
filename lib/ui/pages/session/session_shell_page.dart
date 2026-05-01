import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers.dart';
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
  bool _hostServiceStarted = false;
  bool _guestSubscribed = false;
  SessionStatus? _lastKnownStatus;

  StreamSubscription<SyncMessage>? _hostMsgSub;
  StreamSubscription<SyncMessage>? _guestMsgSub;
  StreamSubscription<bool>? _guestConnSub;
  StreamSubscription<void>? _sessionClosedSub;

  @override
  void dispose() {
    _hostMsgSub?.cancel();
    _guestMsgSub?.cancel();
    _guestConnSub?.cancel();
    _sessionClosedSub?.cancel();
    // Keep the BLE connection alive so the guest can re-sync on re-entry.
    // Disconnection happens only when explicitly joining a different session.
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

        // Host: start BLE advertising once.
        if (isHost &&
            session.status != SessionStatus.closed &&
            !_hostServiceStarted) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _startHostService(session, user));
        }

        // Guest: subscribe to messages if the BLE connection is already up.
        final participantSvc = ref.read(participantBleServiceProvider);
        if (!isHost &&
            participantSvc.isConnected &&
            !_guestSubscribed &&
            session.status != SessionStatus.closed &&
            user != null) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _subscribeAsGuest(session, user));
        }

        final guestConnected =
            !isHost && participantSvc.isConnected;

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

        final safeIndex = _currentIndex.clamp(0, tabs.length - 1);

        return Scaffold(
          appBar: AppBar(
            title: Text(session.name),
            centerTitle: true,
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
                      final hostSvc = ref.read(hostBleServiceProvider);
                      hostSvc.sendSessionClosedToGuests();
                      await hostSvc.stop();
                      setState(() => _hostServiceStarted = false);
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
                      final hostSvc = ref.read(hostBleServiceProvider);
                      hostSvc.sendSessionClosedToGuests();
                      await hostSvc.stop();
                      await ref
                          .read(sessionsProvider.notifier)
                          .deleteSession(widget.sessionId);
                      if (context.mounted) context.go('/home/sessions');
                    }
                  }
                },
                itemBuilder: (context) => [
                  if (session.status != SessionStatus.closed)
                    PopupMenuItem(
                        value: 'close',
                        child: Text(l10n.sessionLeaveTableMenu)),
                  PopupMenuItem(
                      value: 'delete',
                      child: Text(l10n.sessionDeleteTableMenu)),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              if (session.status == SessionStatus.closed)
                _infoBanner(
                  context,
                  icon: Icons.lock_outline,
                  message: l10n.sessionClosedBanner,
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  onColor: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              if (!isHost &&
                  !guestConnected &&
                  session.status != SessionStatus.closed)
                _infoBanner(
                  context,
                  icon: Icons.bluetooth_disabled,
                  message: l10n.sessionUnreachableBanner,
                  color: Theme.of(context).colorScheme.errorContainer,
                  onColor: Theme.of(context).colorScheme.onErrorContainer,
                  trailing: TextButton(
                    onPressed: () => context.go('/sessions/join'),
                    child: Text(AppLocalizations.of(context)!.sessionReconnect),
                  ),
                ),
              Expanded(child: tabs[safeIndex]),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: safeIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
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
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
            child: Text(
                AppLocalizations.of(context)!.errorMessage(error.toString()))),
      ),
    );
  }

  // ── Host ─────────────────────────────────────────────────────────────────

  Future<void> _startHostService(Session session, LocalUser? user) async {
    if (_hostServiceStarted) return;

    final hostSvc = ref.read(hostBleServiceProvider);

    if (hostSvc.isRunning) {
      if (hostSvc.currentSessionId == session.id) {
        // Already advertising this session — just refresh in-memory refs.
        hostSvc.setSession(session);
        _lastKnownStatus = session.status;
        final restaurantRepo = ref.read(restaurantRepositoryProvider);
        final restaurant =
            await restaurantRepo.getRestaurantById(session.restaurantId);
        if (restaurant != null) hostSvc.setRestaurant(restaurant);
        if (mounted) setState(() => _hostServiceStarted = true);
        return;
      }
      // Different session — stop the old one before starting the new one.
      await hostSvc.stop();
    }

    try {
      await hostSvc.start(
        sessionId: session.id,
        sessionName: session.name,
        hostName: user?.username ?? 'Host',
      );
      hostSvc.setSession(session);
      _lastKnownStatus = session.status;

      final restaurantRepo = ref.read(restaurantRepositoryProvider);
      final restaurant =
          await restaurantRepo.getRestaurantById(session.restaurantId);
      if (restaurant != null) hostSvc.setRestaurant(restaurant);

      final subOrderRepo = ref.read(personalSubOrderRepositoryProvider);
      final existing = await subOrderRepo.getSubOrdersForSession(session.id);
      for (final so in existing) {
        hostSvc.upsertSubOrder(so);
      }

      _hostMsgSub = hostSvc.messages.listen(_handleHostMessage);

      if (mounted) setState(() => _hostServiceStarted = true);
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

        // Add guest's profile info on the host device.
        final subOrderRepo = ref.read(personalSubOrderRepositoryProvider);
        final existing =
            await subOrderRepo.getSubOrder(widget.sessionId, userId);
        await subOrderRepo.saveSubOrder(PersonalSubOrder(
          id: existing?.id ?? const Uuid().v4(),
          sessionId: widget.sessionId,
          userId: userId,
          userName: msg.data['userName'] as String?,
          userFullName: msg.data['userFullName'] as String?,
          userAvatarIconName: msg.data['userAvatarIconName'] as String? ?? existing?.userAvatarIconName,
          userAvatarColorValue: msg.data['userAvatarColorValue'] as int? ?? existing?.userAvatarColorValue,
          entries: existing?.entries ?? [],
          checklist: existing?.checklist ?? [],
          locked: existing?.locked ?? false,
          updatedAt: DateTime.now(),
        ));

        if (mounted) {
          ref.invalidate(sessionDetailProvider(widget.sessionId));
          ref.invalidate(subOrdersForSessionProvider(widget.sessionId));
          ref.invalidate(sessionsProvider);
        }

        // Keep host-side snapshot up to date so late joiners get fresh state.
        final updatedSession =
            await sessionRepo.getSessionById(widget.sessionId);
        if (updatedSession != null) {
          ref.read(hostBleServiceProvider).setSession(updatedSession);
        }

      case SyncMessageType.subOrderUpdate:
        final subOrder = PersonalSubOrder.fromJson(msg.data);
        final subOrderRepo = ref.read(personalSubOrderRepositoryProvider);
        final existing =
            await subOrderRepo.getSubOrder(subOrder.sessionId, subOrder.userId);
        if (existing != null) {
          await subOrderRepo.updateSubOrder(subOrder.copyWith(
            id: existing.id,
            checklist: existing.checklist,
            userAvatarIconName: existing.userAvatarIconName,
            userAvatarColorValue: existing.userAvatarColorValue,
          ));
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

  void _subscribeAsGuest(Session session, LocalUser user) {
    if (_guestSubscribed) return;
    _guestSubscribed = true;

    final participantSvc = ref.read(participantBleServiceProvider);

    _guestConnSub = participantSvc.connectionStatus.listen((connected) {
      if (!mounted) return;
      if (!connected) setState(() => _guestSubscribed = false);
    });

    _guestMsgSub =
        participantSvc.messages.listen((msg) => _handleGuestMessage(msg, session));

    _sessionClosedSub = participantSvc.sessionClosed.listen((_) {
      if (!mounted) return;
      participantSvc.markSessionClosed();
      final sessionRepo = ref.read(sessionRepositoryProvider);
      sessionRepo.saveSession(session.copyWith(status: SessionStatus.closed));
      ref.invalidate(sessionDetailProvider(session.id));
      ref.invalidate(sessionsProvider);
      if (mounted) setState(() => _guestSubscribed = false);
    });

    // Request fresh state from the host so any changes made while the guest was
    // away from this page are immediately reflected.
    participantSvc.requestSync();
  }

  Future<void> _handleGuestMessage(SyncMessage msg, Session currentSession) async {
    if (!mounted) return;

    final sessionRepo = ref.read(sessionRepositoryProvider);
    final restaurantRepo = ref.read(restaurantRepositoryProvider);
    final subOrderRepo = ref.read(personalSubOrderRepositoryProvider);
    final LocalUser? user = ref.read(profileViewModelProvider).value;

    switch (msg.type) {
      case SyncMessageType.initialSync:
        // Handles re-syncs after reconnection.
        if (msg.data['session'] != null) {
          final s = Session.fromJson(msg.data['session'] as Map<String, dynamic>);
          await sessionRepo.saveSession(s);
          _lastKnownStatus = s.status;
          if (mounted) {
            ref.invalidate(sessionDetailProvider(s.id));
            ref.invalidate(sessionsProvider);
          }
        }
        if (msg.data['restaurant'] != null) {
          final remote = Restaurant.fromJson(
              msg.data['restaurant'] as Map<String, dynamic>);
          final local = await restaurantRepo.getRestaurantById(remote.id);
          await restaurantRepo.saveRestaurant(_mergeRestaurant(remote, local));
          if (mounted) ref.invalidate(restaurantDetailProvider(remote.id));
        }
        final subOrdersJson =
            msg.data['subOrders'] as List<dynamic>? ?? [];
        for (final raw in subOrdersJson) {
          final so = PersonalSubOrder.fromJson(raw as Map<String, dynamic>);
          if (so.userId == user?.id) continue;
          final existing =
              await subOrderRepo.getSubOrder(so.sessionId, so.userId);
          if (existing != null) {
            await subOrderRepo.updateSubOrder(
                so.copyWith(checklist: existing.checklist));
          } else {
            await subOrderRepo.saveSubOrder(so);
          }
        }
        if (mounted) {
          ref.invalidate(subOrdersForSessionProvider(currentSession.id));
        }

      case SyncMessageType.sessionUpdate:
        final newSession = Session.fromJson(msg.data);
        await sessionRepo.saveSession(newSession);

        final prevStatus = _lastKnownStatus;
        _lastKnownStatus = newSession.status;

        if (user != null) {
          final needsClear =
              (newSession.status == SessionStatus.sent &&
                      prevStatus != SessionStatus.sent) ||
                  (newSession.status == SessionStatus.open &&
                      prevStatus == SessionStatus.sent);
          if (needsClear) {
            final mine =
                await subOrderRepo.getSubOrder(currentSession.id, user.id);
            if (mine != null) {
              await subOrderRepo.updateSubOrder(
                  mine.copyWith(entries: [], updatedAt: DateTime.now()));
              if (mounted) {
                ref.invalidate(
                    personalOrderProvider('${currentSession.id}:${user.id}'));
              }
            }
          }
        }
        if (mounted) {
          ref.invalidate(sessionDetailProvider(newSession.id));
          ref.invalidate(sessionsProvider);
        }

      case SyncMessageType.restaurantUpdate:
        final remote = Restaurant.fromJson(msg.data);
        final local = await restaurantRepo.getRestaurantById(remote.id);
        await restaurantRepo.saveRestaurant(_mergeRestaurant(remote, local));
        if (mounted) ref.invalidate(restaurantDetailProvider(remote.id));

      case SyncMessageType.sessionClosed:
        final participantSvc = ref.read(participantBleServiceProvider);
        participantSvc.markSessionClosed();
        await sessionRepo.saveSession(
            currentSession.copyWith(status: SessionStatus.closed));
        if (mounted) {
          ref.invalidate(sessionDetailProvider(currentSession.id));
          ref.invalidate(sessionsProvider);
        }

      case SyncMessageType.subOrderBroadcast:
        final so = PersonalSubOrder.fromJson(msg.data);
        if (so.userId == user?.id) return;
        final existing =
            await subOrderRepo.getSubOrder(so.sessionId, so.userId);
        if (existing != null) {
          await subOrderRepo
              .updateSubOrder(so.copyWith(checklist: existing.checklist));
        } else {
          await subOrderRepo.saveSubOrder(so);
        }
        if (mounted) {
          ref.invalidate(subOrdersForSessionProvider(so.sessionId));
        }

      default:
        break;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Restaurant _mergeRestaurant(Restaurant remote, Restaurant? local) {
    if (local == null) return remote;
    final localYummies = {
      for (final item in local.menu)
        if (item.isYummie) item.id: true,
    };
    return remote.copyWith(
      // coverImagePath is excluded from the sync payload (local path); keep
      // whatever the guest has stored locally.
      coverImagePath: local.coverImagePath,
      menu: remote.menu
          .map((item) =>
              item.copyWith(isYummie: localYummies[item.id] ?? item.isYummie))
          .toList(),
    );
  }

  Widget _infoBanner(
    BuildContext context, {
    required IconData icon,
    required String message,
    required Color color,
    required Color onColor,
    Widget? trailing,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: double.infinity),
      child: Material(
        color: color,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 16, color: onColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(message,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: onColor)),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
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
                    backgroundColor:
                        Theme.of(context).colorScheme.error)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  Future<void> _showShareSheet(
      BuildContext context, AppLocalizations l10n) async {
    final shortCode = widget.sessionId.substring(0, 8).toUpperCase();
    final qrData = 'sushare://join/$shortCode';

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                    shortCode,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.sessionShareBleHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
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
