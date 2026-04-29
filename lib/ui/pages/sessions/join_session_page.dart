import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/providers.dart';
import '../../../domain/models/restaurant.dart';
import '../../../domain/models/session.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/participant_ble_service.dart';
import '../../../services/permission_service.dart';
import '../../../services/sync_message.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/restaurant_viewmodel.dart';
import '../../viewmodels/session_viewmodel.dart';

class JoinSessionPage extends ConsumerStatefulWidget {
  const JoinSessionPage({super.key});

  @override
  ConsumerState<JoinSessionPage> createState() => _JoinSessionPageState();
}

class _JoinSessionPageState extends ConsumerState<JoinSessionPage> {
  final _codeController = TextEditingController();
  bool _isQrScanning = false;
  bool _isConnecting = false;
  String? _error;
  String _enteredCode = '';

  @override
  void dispose() {
    _codeController.dispose();
    final svc = ref.read(participantBleServiceProvider);
    if (!svc.isConnected) svc.stopDiscovery();
    super.dispose();
  }

  // ── Connection ──────────────────────────────────────────────────────────────

  Future<void> _tryConnectByCode(String code) async {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.read(profileViewModelProvider).value;
    if (user == null) {
      _setError(l10n.joinTableErrorNoProfile);
      return;
    }

    setState(() {
      _isConnecting = true;
      _error = null;
    });

    final granted = await PermissionService.requestBluetooth(context);
    if (!granted || !mounted) {
      if (mounted) setState(() => _isConnecting = false);
      return;
    }

    final svc = ref.read(participantBleServiceProvider);
    await svc.startDiscovery(myDeviceName: user.username);

    // Check already-discovered sessions first, then wait for a new match.
    final existingMatch = svc.currentDiscoveredSessions
        .where((s) => s.shortId.toUpperCase().startsWith(code.toUpperCase()))
        .firstOrNull;

    DiscoveredSession? target = existingMatch;

    if (target == null) {
      final foundCompleter = Completer<DiscoveredSession?>();
      StreamSubscription<List<DiscoveredSession>>? scanSub;
      scanSub = svc.discoveredSessions.listen((list) {
        final match = list
            .where((s) =>
                s.shortId.toUpperCase().startsWith(code.toUpperCase()))
            .firstOrNull;
        if (match != null && !foundCompleter.isCompleted) {
          foundCompleter.complete(match);
          scanSub?.cancel();
        }
      });

      target = await foundCompleter.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          scanSub?.cancel();
          return null;
        },
      );
    }

    if (target == null) {
      if (!svc.isConnected) await svc.stopDiscovery();
      _setError(l10n.joinTableErrorNotFound(code));
      return;
    }

    await _connectTo(target);
  }

  Future<void> _connectTo(DiscoveredSession session) async {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.read(profileViewModelProvider).value;
    if (user == null) {
      _setError(l10n.joinTableErrorNoProfile);
      return;
    }

    try {
      final svc = ref.read(participantBleServiceProvider);

      if (svc.isConnected) await svc.disconnect();

      final userInfo = <String, dynamic>{
        'userId': user.id,
        'userName': user.username,
        'userFullName': '${user.firstName} ${user.lastName}'.trim(),
        'userAvatarIconName': user.avatarIconName,
        'userAvatarColorValue': user.avatarColorValue,
      };

      final connected = await svc.connect(
        endpointId: session.endpointId,
        userInfo: userInfo,
        myDeviceName: user.username,
      );
      if (!connected) {
        _setError(l10n.joinTableErrorConnectFailed);
        return;
      }

      // Race initialSync against sessionClosed so we can show the right error.
      bool sessionWasClosed = false;
      final syncCompleter = Completer<SyncMessage?>();
      StreamSubscription<SyncMessage>? syncSub;
      StreamSubscription<void>? closedSub;
      syncSub = svc.messages
          .where((m) => m.type == SyncMessageType.initialSync)
          .listen((msg) {
        if (!syncCompleter.isCompleted) {
          syncCompleter.complete(msg);
          syncSub?.cancel();
          closedSub?.cancel();
        }
      });
      closedSub = svc.sessionClosed.listen((_) {
        if (!syncCompleter.isCompleted) {
          sessionWasClosed = true;
          syncCompleter.complete(null);
          syncSub?.cancel();
          closedSub?.cancel();
        }
      });
      final syncResult = await syncCompleter.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          syncSub?.cancel();
          closedSub?.cancel();
          return null;
        },
      );
      if (syncResult == null) {
        await svc.disconnect();
        _setError(sessionWasClosed
            ? l10n.joinTableClosedError
            : l10n.joinTableErrorSyncTimeout);
        return;
      }
      final initialSync = syncResult;

      final sessionRepo = ref.read(sessionRepositoryProvider);
      final restaurantRepo = ref.read(restaurantRepositoryProvider);

      final sessionData =
          initialSync.data['session'] as Map<String, dynamic>?;
      if (sessionData == null) {
        _setError(l10n.joinTableErrorInvalidData);
        return;
      }

      final remoteSession = Session.fromJson(sessionData);
      await sessionRepo.saveSession(remoteSession);
      await sessionRepo.addParticipant(remoteSession.id, user.id);

      final restaurantData =
          initialSync.data['restaurant'] as Map<String, dynamic>?;
      if (restaurantData != null) {
        await restaurantRepo.saveRestaurant(Restaurant.fromJson(restaurantData));
      }

      if (mounted) context.go('/sessions/${remoteSession.id}');
    } catch (_) {
      ref.read(participantBleServiceProvider).disconnect();
      _setError(AppLocalizations.of(context)!.joinTableErrorConnectionTimeout);
    }
  }

  void _setError(String msg) {
    if (mounted) setState(() { _error = msg; _isConnecting = false; });
  }

  // ── QR scanning ─────────────────────────────────────────────────────────────

  void _handleQrDetected(String value) {
    _stopQrScanning();
    String? code;
    final uri = Uri.tryParse(value);
    if (uri != null && uri.scheme == 'sushare' && uri.host == 'join') {
      code = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    } else if (value.startsWith('sushare://join/')) {
      code = value.substring('sushare://join/'.length);
    } else if (value.length >= 8) {
      code = value.substring(0, 8);
    }
    if (code != null) {
      final shortCode =
          code.substring(0, code.length.clamp(0, 8)).toUpperCase();
      _codeController.text = shortCode;
      setState(() => _enteredCode = shortCode);
      _tryConnectByCode(shortCode);
    }
  }

  void _startQrScanning() => setState(() => _isQrScanning = true);
  void _stopQrScanning() => setState(() => _isQrScanning = false);

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    if (_isQrScanning) return _buildQrScanner(colorScheme, l10n);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.joinTableTitle),
        centerTitle: true,
      ),
      body: _isConnecting
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n.joinTableConnecting),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.joinTableSubtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  // ── QR scan ──────────────────────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.qr_code_scanner,
                                  color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(l10n.joinTableScanQr,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium),
                            ],
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonalIcon(
                            onPressed: _startQrScanning,
                            icon: const Icon(Icons.qr_code_scanner),
                            label: Text(l10n.joinTableOpenScanner),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Manual code ──────────────────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.keyboard,
                                  color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(l10n.joinTableEnterCode,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _codeController,
                            decoration: InputDecoration(
                              labelText: l10n.joinTableCodeLabel,
                              hintText: l10n.joinTableCodeHint,
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.tag),
                            ),
                            textCapitalization: TextCapitalization.characters,
                            maxLength: 8,
                            onChanged: (v) =>
                                setState(() => _enteredCode = v.trim()),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 8),
                            Text(_error!,
                                style:
                                    TextStyle(color: colorScheme.error)),
                          ],
                          const SizedBox(height: 8),
                          FilledButton(
                            onPressed: _enteredCode.isEmpty
                                ? null
                                : () => _tryConnectByCode(_enteredCode),
                            child: Text(l10n.joinTableJoin),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Cross-platform note ──────────────────────────────────
                  const SizedBox(height: 16),
                  Card(
                    color: colorScheme.surfaceContainerHigh,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline,
                              size: 16,
                              color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.joinTableCrossPlatformNote,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/sessions/new'),
                      child: Text(l10n.joinTableStartNew),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildQrScanner(ColorScheme colorScheme, AppLocalizations l10n) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.joinTableScanQr),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _stopQrScanning,
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final barcode = capture.barcodes.firstOrNull;
              if (barcode?.rawValue != null) {
                _handleQrDetected(barcode!.rawValue!);
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.primary, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 300),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.joinTableScanHint,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
