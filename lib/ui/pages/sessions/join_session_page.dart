import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../domain/models/restaurant.dart';
import '../../../domain/models/session.dart';
import '../../../domain/repositories/session_repository.dart';
import '../../../l10n/app_localizations.dart';
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
  final _hostController = TextEditingController();
  bool _isScanning = false;
  bool _isConnecting = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    _hostController.dispose();
    super.dispose();
  }

  /// Returns the canonical session ID (as stored in DB) on success.
  Future<String> _resolveAndJoin(String rawId, String host, String userId) async {
    final sessionRepo = ref.read(sessionRepositoryProvider);
    if (host.isNotEmpty) {
      return _joinViaNetwork(rawId, host, sessionRepo, userId);
    } else {
      return _joinViaLocalDb(rawId, sessionRepo);
    }
  }

  Future<void> _joinSession(String sessionId, {String? hostAddress}) async {
    if (sessionId.isEmpty) return;

    setState(() {
      _isConnecting = true;
      _error = null;
    });

    try {
      final user = ref.read(profileViewModelProvider).value;
      if (user == null) throw Exception('Please log in first');

      final rawId = sessionId.trim();
      final host = hostAddress ?? _hostController.text.trim();

      // canonicalId is the exact ID as stored in the DB (may differ in case from rawId)
      final canonicalId = await _resolveAndJoin(rawId, host, user.id);

      final sessionRepo = ref.read(sessionRepositoryProvider);
      await sessionRepo.addParticipant(canonicalId, user.id);

      if (mounted) context.go('/sessions/$canonicalId');
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isConnecting = false;
      });
    }
  }

  /// Fetches session + restaurant from the host device over HTTP.
  /// Returns the canonical session ID from the server.
  Future<String> _joinViaNetwork(
    String sessionId,
    String host,
    SessionRepository sessionRepo,
    String userId,
  ) async {
    final baseUrl = 'http://$host';

    final sessionRes = await http
        .get(Uri.parse('$baseUrl/api/session'))
        .timeout(const Duration(seconds: 10));
    if (sessionRes.statusCode != 200) {
      throw Exception('Could not reach host — check the address and try again');
    }

    final sessionJson = jsonDecode(sessionRes.body) as Map<String, dynamic>;
    final session = Session.fromJson(sessionJson);

    // Accept both full UUID and 8-char short code (case-insensitive prefix match)
    if (!session.id.toUpperCase().startsWith(sessionId.toUpperCase())) {
      throw Exception('Session ID mismatch');
    }
    if (session.status == SessionStatus.closed) {
      throw Exception('This table is closed');
    }

    // Save session with host address so it can auto-reconnect later
    await sessionRepo.saveSession(session.copyWith(hostAddress: host));

    final restaurantRes = await http
        .get(Uri.parse('$baseUrl/api/restaurant'))
        .timeout(const Duration(seconds: 10));
    if (restaurantRes.statusCode == 200) {
      final restaurantJson = jsonDecode(restaurantRes.body) as Map<String, dynamic>;
      final restaurant = Restaurant.fromJson(restaurantJson);
      final restaurantRepo = ref.read(restaurantRepositoryProvider);
      await restaurantRepo.saveRestaurant(restaurant);
    }

    return session.id;
  }

  /// Falls back to local DB — works when both devices already have the session
  /// (e.g. re-joining a session created on this device).
  Future<String> _joinViaLocalDb(
    String sessionId,
    SessionRepository sessionRepo,
  ) async {
    // Try exact match first, then short-code prefix match
    Session? session = await sessionRepo.getSessionById(sessionId);
    session ??= await sessionRepo.getSessionByShortCode(sessionId);

    if (session == null) {
      throw Exception('Table not found — scan the QR code or enter the host address');
    }
    if (session.status == SessionStatus.closed) {
      throw Exception('This table is closed');
    }
    return session.id;
  }

  void _handleQrDetected(String value) {
    _stopScanning();
    final uri = Uri.tryParse(value);
    if (uri != null && uri.scheme == 'sushare' && uri.host == 'join') {
      final sessionId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      final host = uri.queryParameters['host'];
      _joinSession(sessionId, hostAddress: host);
    } else if (value.startsWith('sushare://join/')) {
      _joinSession(value.substring('sushare://join/'.length));
    } else {
      _joinSession(value);
    }
  }

  void _startScanning() => setState(() => _isScanning = true);
  void _stopScanning() => setState(() => _isScanning = false);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    if (_isScanning) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.joinTableScanQr),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _stopScanning,
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.joinTableTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.joinTableHeading, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              l10n.joinTableSubtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.qr_code_scanner, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(l10n.joinTableScanQr, style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonalIcon(
                      onPressed: _startScanning,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: Text(l10n.joinTableOpenScanner),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
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
                        Text(l10n.joinTableEnterCode, style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _hostController,
                      decoration: InputDecoration(
                        labelText: l10n.joinTableHostLabel,
                        hintText: l10n.joinTableHostHint,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.router_outlined),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!, style: TextStyle(color: colorScheme.error)),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _isConnecting
                          ? null
                          : () => _joinSession(_codeController.text),
                      child: _isConnecting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.joinTableJoin),
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
}
