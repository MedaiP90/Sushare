import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../domain/repositories/session_repository.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/session_viewmodel.dart';

class JoinSessionPage extends ConsumerStatefulWidget {
  const JoinSessionPage({super.key});

  @override
  ConsumerState<JoinSessionPage> createState() => _JoinSessionPageState();
}

class _JoinSessionPageState extends ConsumerState<JoinSessionPage> {
  final _codeController = TextEditingController();
  bool _isScanning = false;
  bool _isConnecting = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinByCode(String code) async {
    if (code.isEmpty) return;

    setState(() {
      _isConnecting = true;
      _error = null;
    });

    try {
      final user = ref.read(profileViewModelProvider).value;
      if (user == null) {
        throw Exception('Please log in first');
      }

      final cleanCode = code.trim().toUpperCase();
      
      final sessionRepo = ref.read(sessionRepositoryProvider);
      final session = await sessionRepo.getSessionById(cleanCode);

      if (session == null) {
        throw Exception('Session not found');
      }

      if (session.status.name == 'closed') {
        throw Exception('This session is closed');
      }

      await sessionRepo.addParticipant(cleanCode, user.id);

      if (mounted) {
        context.go('/sessions/$cleanCode');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isConnecting = false;
      });
    }
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
    });
  }

  void _stopScanning() {
    setState(() {
      _isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isScanning) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Scan QR Code'),
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
                  final value = barcode!.rawValue!;
                  _stopScanning();
                  if (value.startsWith('sushare://join/')) {
                    final code = value.substring('sushare://join/'.length);
                    _joinByCode(code);
                  } else {
                    _joinByCode(value);
                  }
                }
              },
            ),
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: colorScheme.primary,
                    width: 2,
                  ),
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
                      'Point camera at QR code',
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
        title: const Text('Join Session'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Join a session',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the session code or scan the QR code',
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
                        Icon(
                          Icons.qr_code_scanner,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Scan QR Code',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonalIcon(
                      onPressed: _startScanning,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Open Scanner'),
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
                        Icon(
                          Icons.keyboard,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Enter Code Manually',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Session Code',
                        hintText: 'e.g., ABC12345',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.tag),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 8,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _isConnecting
                          ? null
                          : () => _joinByCode(_codeController.text),
                      child: _isConnecting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Join Session'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: TextButton(
                onPressed: () => context.go('/sessions/new'),
                child: const Text('Or start a new session'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}