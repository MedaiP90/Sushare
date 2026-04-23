import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/restaurant.dart';
import '../../../l10n/app_localizations.dart';
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
  final List<File> _capturedImages = [];
  List<MenuItem> _parsedItems = [];

  @override
  void dispose() {
    for (final f in _capturedImages) {
      f.delete().ignore();
    }
    super.dispose();
  }

  Future<void> _captureMenu() async {
    final hasPermission = await PermissionService.checkAndRequestCamera(context);
    if (!hasPermission) return;
    final image = await ref.read(cameraServiceProvider).captureMenuImage();
    if (image != null && mounted) await _processImage(image);
  }

  Future<void> _pickImage() async {
    final hasPermission = await PermissionService.checkAndRequestPhotos(context);
    if (!hasPermission) return;
    final image = await ref.read(cameraServiceProvider).pickImageFromGallery();
    if (image != null && mounted) await _processImage(image);
  }

  Future<void> _processImage(File image) async {
    setState(() {
      _capturedImages.add(image);
      _isProcessing = true;
    });

    try {
      final aiService = ref.read(menuAiServiceProvider);
      if (!await aiService.hasApiKey()) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.scanMenuNoApiKey)),
          );
        }
        return;
      }

      final items = await aiService.parseMenuImage(image);
      if (mounted) {
        setState(() => _mergeItems(items));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // Merges incoming items into _parsedItems, deduplicating by name.
  void _mergeItems(List<MenuItem> incoming) {
    final result = [..._parsedItems];
    for (final item in incoming) {
      final existingIdx = result.indexWhere(
        (e) => e.name.trim().toLowerCase() == item.name.trim().toLowerCase(),
      );
      if (existingIdx == -1) {
        result.add(item);
      } else {
        final existing = result[existingIdx];
        result[existingIdx] = existing.copyWith(
          description: existing.description ?? item.description,
          itemNumber: existing.itemNumber ?? item.itemNumber,
        );
      }
    }
    _parsedItems = result;
  }

  void _removeItem(int index) {
    setState(() => _parsedItems = [..._parsedItems]..removeAt(index));
  }

  void _reset() {
    for (final f in _capturedImages) {
      f.delete().ignore();
    }
    setState(() {
      _capturedImages.clear();
      _parsedItems = [];
    });
  }

  Future<void> _saveItems() async {
    if (_parsedItems.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final restaurant =
        await ref.read(restaurantDetailProvider(widget.restaurantId).future);
    if (restaurant == null) return;

    final existingMenu = restaurant.menu;

    // If the restaurant already has items, ask append vs. overwrite.
    bool overwrite = false;
    if (existingMenu.isNotEmpty && mounted) {
      final choice = await _showSaveModeSheet(existingMenu.length);
      if (choice == null) return; // user cancelled
      overwrite = choice;
    }

    final baseMenu = overwrite ? <MenuItem>[] : [...existingMenu];
    final baseMax = baseMenu
        .map((m) => m.itemNumber ?? 0)
        .fold<int>(0, (a, b) => a > b ? a : b);

    // Assign numbers to items without one, continuing from baseMax.
    final usedInBatch = _parsedItems
        .where((i) => i.itemNumber != null)
        .map((i) => i.itemNumber!)
        .toSet();

    int nextNumber = baseMax + 1;
    final numbered = <MenuItem>[];
    for (final item in _parsedItems) {
      if (item.itemNumber != null) {
        numbered.add(item);
      } else {
        while (usedInBatch.contains(nextNumber)) nextNumber++;
        usedInBatch.add(nextNumber);
        numbered.add(item.copyWith(itemNumber: nextNumber++));
      }
    }

    // Categorise each incoming item vs baseMenu (dedup logic).
    final updatedMenu = [...baseMenu];
    final toAdd = <MenuItem>[];
    final conflicts = <_NumberConflict>[];

    for (final incoming in numbered) {
      final nameIdx = updatedMenu.indexWhere(
        (e) => e.name.trim().toLowerCase() == incoming.name.trim().toLowerCase(),
      );
      if (nameIdx != -1) {
        final existing = updatedMenu[nameIdx];
        final newItemNumber = existing.itemNumber != null && incoming.itemNumber != null
            ? (existing.itemNumber! < incoming.itemNumber!
                ? existing.itemNumber
                : incoming.itemNumber)
            : (existing.itemNumber ?? incoming.itemNumber);
        updatedMenu[nameIdx] = existing.copyWith(
          description: incoming.description ?? existing.description,
          itemNumber: newItemNumber,
        );
        continue;
      }

      final numberIdx = incoming.itemNumber == null
          ? -1
          : updatedMenu.indexWhere((e) => e.itemNumber == incoming.itemNumber);

      if (numberIdx != -1) {
        conflicts.add(_NumberConflict(
          existing: updatedMenu[numberIdx],
          incoming: incoming,
          existingIndex: numberIdx,
        ));
      } else {
        toAdd.add(incoming);
      }
    }

    if (conflicts.isNotEmpty && mounted) {
      final resolutions = await _showConflictSheet(conflicts);
      if (resolutions == null) return;

      int renumberFrom = updatedMenu
          .map((m) => m.itemNumber ?? 0)
          .fold<int>(baseMax, (a, b) => a > b ? a : b);

      for (final conflict in conflicts) {
        final choice = resolutions[conflict.incoming.id];
        if (choice == _Resolution.useNew) {
          updatedMenu[conflict.existingIndex] = conflict.incoming;
        } else if (choice == _Resolution.keepBoth) {
          toAdd.add(conflict.incoming.copyWith(itemNumber: ++renumberFrom));
        }
      }
    }

    final finalMenu = [...updatedMenu, ...toAdd];
    await ref.read(restaurantsProvider.notifier).updateRestaurant(
          restaurant.copyWith(menu: finalMenu),
        );
    ref.invalidate(restaurantDetailProvider(widget.restaurantId));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.scanMenuUpdated)),
      );
      _reset();
    }
  }

  Future<bool?> _showSaveModeSheet(int existingCount) {
    final l10n = AppLocalizations.of(context)!;
    return showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.scanMenuSaveTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.scanMenuSaveDescription(existingCount),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.pop(ctx, false),
                icon: const Icon(Icons.playlist_add),
                label: Text(l10n.scanMenuAppend),
              ),
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                onPressed: () => Navigator.pop(ctx, true),
                icon: const Icon(Icons.swap_horiz),
                label: Text(l10n.scanMenuReplace),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, _Resolution>?> _showConflictSheet(
    List<_NumberConflict> conflicts,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final resolutions = <String, _Resolution>{
      for (final c in conflicts) c.incoming.id: _Resolution.keepBoth,
    };

    return showModalBottomSheet<Map<String, _Resolution>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (ctx, scrollController) => Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.scanMenuNumberConflicts,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.scanMenuConflictDescription(conflicts.length),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: conflicts
                      .map((c) => _ConflictTile(
                            conflict: c,
                            resolution: resolutions[c.incoming.id]!,
                            onChanged: (r) =>
                                setSheetState(() => resolutions[c.incoming.id] = r),
                          ))
                      .toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, resolutions),
                        child: Text(l10n.confirm),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final hasContent = _capturedImages.isNotEmpty || _parsedItems.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scanMenuTitle),
        centerTitle: true,
        actions: [
          if (hasContent)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: l10n.scanMenuStartOver,
              onPressed: _reset,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.scanMenuHeading,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.scanMenuSubtitle,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),

            if (_capturedImages.isNotEmpty) ...[
              Text(
                l10n.scanMenuPagesScanned(_capturedImages.length),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _capturedImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _capturedImages[i],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_isProcessing)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(l10n.scanMenuAnalyzing),
                    ],
                  ),
                ),
              ),

            if (!_isProcessing)
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _captureMenu,
                      icon: const Icon(Icons.camera_alt),
                      label: Text(
                          _capturedImages.isEmpty ? l10n.scanMenuTakePhoto : l10n.scanMenuAddPhoto),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library),
                      label: Text(
                          _capturedImages.isEmpty ? l10n.scanMenuGallery : l10n.scanMenuAddFromGallery),
                    ),
                  ),
                ],
              ),

            if (_parsedItems.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                l10n.scanMenuItemsFound(_parsedItems.length),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ..._parsedItems.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                return Card(
                  child: ListTile(
                    leading: item.itemNumber != null
                        ? CircleAvatar(
                            backgroundColor: colorScheme.primaryContainer,
                            foregroundColor: colorScheme.onPrimaryContainer,
                            child: Text('${item.itemNumber}'),
                          )
                        : CircleAvatar(
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.restaurant_menu, size: 16),
                          ),
                    title: Text(item.name),
                    subtitle: item.description != null
                        ? Text(item.description!)
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: l10n.scanMenuRemoveItem,
                      onPressed: () => _removeItem(i),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saveItems,
                icon: const Icon(Icons.save),
                label: Text(l10n.scanMenuSaveButton),
              ),
            ],

            const SizedBox(height: 24),
            Card(
              color: colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.scanMenuApiKeyHint,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
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

// ── conflict resolution types ─────────────────────────────────────────────────

enum _Resolution { keepExisting, useNew, keepBoth }

class _NumberConflict {
  final MenuItem existing;
  final MenuItem incoming;
  final int existingIndex;

  const _NumberConflict({
    required this.existing,
    required this.incoming,
    required this.existingIndex,
  });
}

class _ConflictTile extends StatelessWidget {
  final _NumberConflict conflict;
  final _Resolution resolution;
  final ValueChanged<_Resolution> onChanged;

  const _ConflictTile({
    required this.conflict,
    required this.resolution,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          Text(
            l10n.scanMenuNumberConflictLabel(conflict.incoming.itemNumber!),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          _row(context, l10n.scanMenuConflictExisting, conflict.existing),
          _row(context, l10n.scanMenuConflictNew, conflict.incoming),
          const SizedBox(height: 8),
          SegmentedButton<_Resolution>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: [
              ButtonSegment(
                  value: _Resolution.keepExisting, label: Text(l10n.scanMenuKeepExisting)),
              ButtonSegment(
                  value: _Resolution.useNew, label: Text(l10n.scanMenuUseNew)),
              ButtonSegment(
                  value: _Resolution.keepBoth, label: Text(l10n.scanMenuKeepBoth)),
            ],
            selected: {resolution},
            onSelectionChanged: (s) => onChanged(s.first),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, MenuItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall,
          children: [
            TextSpan(
                text: '$label: ',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: item.name),
          ],
        ),
      ),
    );
  }
}
