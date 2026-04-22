import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/restaurant.dart';
import '../../../services/camera_service.dart';
import '../../../services/menu_ai_service.dart';
import '../../../services/permission_service.dart';
import '../../viewmodels/restaurant_viewmodel.dart';

final cameraServiceProvider = Provider<CameraService>((ref) => CameraService());
final menuAiServiceProvider = Provider<MenuAiService>((ref) => MenuAiService());

class ScanMenuPage extends ConsumerStatefulWidget {
  final String restaurantId;

  const ScanMenuPage({super.key, required this.restaurantId});

  @override
  ConsumerState<ScanMenuPage> createState() => _ScanMenuPageState();
}

class _ScanMenuPageState extends ConsumerState<ScanMenuPage> {
  bool _isProcessing = false;
  File? _capturedImage;
  List<MenuItem>? _parsedItems;

  @override
  void dispose() {
    _capturedImage?.delete();
    super.dispose();
  }

  Future<void> _captureMenu() async {
    final hasPermission =
        await PermissionService.checkAndRequestCamera(context);
    if (!hasPermission) return;

    final camera = ref.read(cameraServiceProvider);
    final image = await camera.captureMenuImage();

    if (image != null && mounted) {
      setState(() => _capturedImage = image);
      await _analyzeImage(image);
    }
  }

  Future<void> _pickImage() async {
    final hasPermission =
        await PermissionService.checkAndRequestPhotos(context);
    if (!hasPermission) return;

    final camera = ref.read(cameraServiceProvider);
    final image = await camera.pickImageFromGallery();

    if (image != null && mounted) {
      setState(() => _capturedImage = image);
      await _analyzeImage(image);
    }
  }

  Future<void> _analyzeImage(File image) async {
    setState(() {
      _isProcessing = true;
      _parsedItems = null;
    });

    try {
      final aiService = ref.read(menuAiServiceProvider);
      final hasKey = await aiService.hasApiKey();

      if (!hasKey) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Please add your Google Gemini API key in Settings first'),
            ),
          );
        }
        return;
      }

      final items = await aiService.parseMenuImage(image);
      if (mounted) {
        setState(() {
          _parsedItems = items;
        });
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _saveItems() async {
    if (_parsedItems == null || _parsedItems!.isEmpty) return;

    final restaurant = await ref.read(restaurantDetailProvider(widget.restaurantId).future);
    if (restaurant == null) return;

    final updated = restaurant.copyWith(
      menu: [...restaurant.menu, ..._parsedItems!],
    );

    await ref.read(restaurantsProvider.notifier).updateRestaurant(updated);
    ref.invalidate(restaurantDetailProvider(widget.restaurantId));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${_parsedItems!.length} menu items!')),
      );
      setState(() {
        _capturedImage = null;
        _parsedItems = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Menu'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Scan a menu to automatically add items',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Take a photo of the menu or pick from gallery. '
              'AI will extract the items.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            if (_capturedImage != null) ...[
              Card(
                clipBehavior: Clip.antiAlias,
                child: Image.file(
                  _capturedImage!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_isProcessing)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Analyzing menu...'),
                    ],
                  ),
                ),
              ),
            if (!_isProcessing && _parsedItems == null) ...[
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _captureMenu,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Photo'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
              ),
            ],
            if (_parsedItems != null) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Found ${_parsedItems!.length} items:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ..._parsedItems!.map((item) => Card(
                    child: ListTile(
                      leading: item.itemNumber != null
                          ? CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              child: Text('${item.itemNumber}'),
                            )
                          : null,
                      title: Text(item.name),
                      subtitle: item.description != null
                          ? Text(item.description!)
                          : null,
                    ),
                  )),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _capturedImage = null;
                          _parsedItems = null;
                        });
                      },
                      child: const Text('Retake'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saveItems,
                      child: const Text('Add to Menu'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Card(
              color: colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Requires a Google Gemini API key for AI analysis. '
                        'Add it in Settings > AI Service.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}