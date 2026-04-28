import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
  String _filterCode = '';

  StreamSubscription<List<DiscoveredSession>>? _discoverySub;
  List<DiscoveredSession> _discovered = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startDiscovery());
  }

  @override
  void dispose() {
    _codeController.dispose();
    _discoverySub?.cancel();
    // Stop discovery only if we didn't just connect.
    final svc = ref.read(participantBleServiceProvider);
    if (!svc.isConnected) svc.stopDiscovery();
    super.dispose();
  }

  Future<void> _startDiscovery() async {
    if (!mounted) return;
    final granted = await PermissionService.requestBluetooth(context);
    if (!granted || !mounted) return;

    final svc = ref.read(participantBleServiceProvider);
    await svc.startDiscovery(
      myDeviceName: ref.read(profileViewModelProvider).value?.username,
    );

    _discoverySub = svc.discoveredSessions.listen((list) {
      if (mounted) setState(() => _discovered = list);
    });
  }

  // ── Connection ──────────────────────────────────────────────────────────────

  Future<void> _connectTo(DiscoveredSession session) async {
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

    try {
      final svc = ref.read(participantBleServiceProvider);

      // Build user-info payload (profile picture is optional, adds latency).
      final userInfo = <String, dynamic>{
        'userId': user.id,
        'userName': user.username,
        'userFullName': '${user.firstName} ${user.lastName}'.trim(),
      };
      if (user.profilePicturePath != null) {
        final f = File(user.profilePicturePath!);
        if (await f.exists()) {
          userInfo['userProfilePictureBase64'] =
              base64Encode(await f.readAsBytes());
        }
      }

      final connected = await svc.connect(
        endpointId: session.endpointId,
        userInfo: userInfo,
        myDeviceName: user.username,
      );
      if (!connected) {
        _setError(l10n.joinTableErrorConnectFailed);
        return;
      }

      // Wait for initialSync from the host (contains session + restaurant data).
      final initialSync = await svc.messages
          .where((m) => m.type == SyncMessageType.initialSync)
          .first
          .timeout(const Duration(seconds: 15));

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
    } on TimeoutException {
      _setError(AppLocalizations.of(context)!.joinTableErrorSyncTimeout);
    } catch (_) {
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
      // Use the first 8 chars as the short code to match against discovered sessions.
      final shortCode = code.substring(0, code.length.clamp(0, 8)).toUpperCase();
      _codeController.text = shortCode;
      setState(() => _filterCode = shortCode);
      _tryConnectByCode(shortCode);
    }
  }

  void _tryConnectByCode(String code) {
    final match = _discovered.where(
      (s) => s.shortId.toUpperCase().startsWith(code.toUpperCase()),
    ).firstOrNull;
    if (match != null) {
      _connectTo(match);
    } else {
      _setError(AppLocalizations.of(context)!.joinTableErrorNotFound(code));
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

    final filtered = _filterCode.isEmpty
        ? _discovered
        : _discovered
            .where((s) =>
                s.shortId.toUpperCase().startsWith(_filterCode.toUpperCase()))
            .toList();

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
                  Text(l10n.joinTableHeading,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    l10n.joinTableSubtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),

                  // ── Nearby sessions ──────────────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.bluetooth_searching,
                                  color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(l10n.joinTableNearbySessions,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium),
                              const Spacer(),
                              if (_discovered.isEmpty)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (filtered.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                l10n.joinTableScanning,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: colorScheme.onSurfaceVariant),
                              ),
                            )
                          else
                            ...filtered.map((s) => _SessionTile(
                                  session: s,
                                  onTap: () => _connectTo(s),
                                )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

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
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
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
                              Icon(Icons.keyboard, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(l10n.joinTableEnterCode,
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
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
                                setState(() => _filterCode = v.trim()),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 8),
                            Text(_error!,
                                style:
                                    TextStyle(color: colorScheme.error)),
                          ],
                          const SizedBox(height: 8),
                          FilledButton(
                            onPressed: _filterCode.isEmpty
                                ? null
                                : () => _tryConnectByCode(_filterCode),
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

class _SessionTile extends StatelessWidget {
  final DiscoveredSession session;
  final VoidCallback onTap;

  const _SessionTile({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorScheme.primaryContainer,
        child: Icon(Icons.restaurant, color: colorScheme.onPrimaryContainer),
      ),
      title: Text(session.sessionName),
      subtitle: Text(AppLocalizations.of(context)!.joinTableSessionTileSubtitle(session.hostName, session.shortId)),
      trailing: Icon(Icons.bluetooth, color: colorScheme.primary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }
}
