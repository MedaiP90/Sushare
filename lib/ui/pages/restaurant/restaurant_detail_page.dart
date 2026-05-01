import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/models/restaurant.dart';
import '../../../domain/models/saved_order.dart';
import '../../../domain/models/personal_sub_order.dart';
import '../../../l10n/app_localizations.dart';
import '../../viewmodels/restaurant_viewmodel.dart';
import '../../viewmodels/saved_order_viewmodel.dart';

class RestaurantDetailPage extends ConsumerStatefulWidget {
  final String restaurantId;

  const RestaurantDetailPage({super.key, required this.restaurantId});

  @override
  ConsumerState<RestaurantDetailPage> createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends ConsumerState<RestaurantDetailPage> {
  bool _isSearchExpanded = false;
  String _searchQuery = '';
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String restaurantId = widget.restaurantId;
    final restaurantAsync = ref.watch(restaurantDetailProvider(restaurantId));
    final templatesAsync = ref.watch(savedOrdersForRestaurantProvider(restaurantId));
    final l10n = AppLocalizations.of(context)!;

    return restaurantAsync.when(
      data: (restaurant) {
        if (restaurant == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(l10n.restaurantNotFound)),
          );
        }

        final sortedMenu = List<MenuItem>.from(restaurant.menu)
          ..sort((a, b) {
            if (a.isYummie && !b.isYummie) return -1;
            if (!a.isYummie && b.isYummie) return 1;
            return (a.itemNumber ?? 0).compareTo(b.itemNumber ?? 0);
          });
        final filteredMenu = _searchQuery.isEmpty
            ? sortedMenu
            : sortedMenu.where((item) {
                final q = _searchQuery.toLowerCase();
                return item.name.toLowerCase().contains(q) ||
                    (item.description?.toLowerCase().contains(q) ?? false) ||
                    (item.itemNumber?.toString().contains(q) ?? false);
              }).toList();

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                centerTitle: true,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(restaurant.name),
                  collapseMode: CollapseMode.parallax,
                  background: restaurant.coverImagePath != null
                      ? ShaderMask(
                          shaderCallback: (rect) => LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 1.0),
                              Colors.black.withValues(alpha: 0.9),
                              Colors.black.withValues(alpha: 0.65),
                              Colors.black.withValues(alpha: 0.15),
                              Colors.black.withValues(alpha: 0.0),
                            ],
                          ).createShader(
                              Rect.fromLTRB(0, 0, rect.width, rect.height)),
                          blendMode: BlendMode.dstIn,
                          child: Image.file(
                            File(restaurant.coverImagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              child: const Icon(Icons.restaurant, size: 64),
                            ),
                          ),
                        )
                      : Container(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.restaurant,
                            size: 64,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                ),
                actions: [
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        _showEditSheet(context, ref, restaurant);
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(l10n.restaurantDeleteTitle),
                            content: Text(l10n.restaurantDeleteMessage(restaurant.name)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(l10n.cancel),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                ),
                                child: Text(l10n.delete),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          await ref
                              .read(restaurantsProvider.notifier)
                              .deleteRestaurant(restaurantId);
                          if (context.mounted) context.pop();
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                      PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                    ],
                  ),
                ],
              ),
              if (restaurant.address != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            color: Theme.of(context).colorScheme.outline),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(restaurant.address!,
                              style: Theme.of(context).textTheme.bodyLarge),
                        ),
                      ],
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Text(l10n.restaurantOrderTemplates,
                          style: Theme.of(context).textTheme.titleLarge),
                      const Spacer(),
                      FilledButton.tonalIcon(
                        onPressed: () =>
                            _showAddTemplateSheet(context, ref, restaurant),
                        icon: const Icon(Icons.add),
                        label: Text(l10n.add),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: templatesAsync.when(
                    data: (templates) => templates.isEmpty
                        ? Text(
                            l10n.restaurantTemplatesEmpty,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: templates
                                .map((t) => _TemplateChip(
                                      label: '${t.label} (${t.entries.length})',
                                      onTap: () =>
                                          _editTemplate(ref, restaurant, t, l10n),
                                      onDelete: () =>
                                          _deleteTemplate(context, ref, t, l10n),
                                    ))
                                .toList(),
                          ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Text(l10n.restaurantMenuSection,
                          style: Theme.of(context).textTheme.titleLarge),
                      const Spacer(),
                      FilledButton.tonalIcon(
                        onPressed: () =>
                            context.push('/scan-menu/$restaurantId'),
                        icon: const Icon(Icons.document_scanner),
                        label: Text(l10n.restaurantScanButton),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = filteredMenu[index];
                    return ListTile(
                      leading: item.itemNumber != null
                          ? CircleAvatar(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primaryContainer,
                              child: Text('${item.itemNumber}'),
                            )
                          : null,
                      title: Row(
                        children: [
                          if (item.isYummie) ...[
                            const Icon(Icons.restaurant, size: 14),
                            const SizedBox(width: 4),
                          ],
                          Expanded(child: Text(item.name)),
                        ],
                      ),
                      subtitle: item.description != null ? Text(item.description!) : null,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditMenuItemSheet(context, ref, restaurant, item);
                          } else if (value == 'yummie') {
                            _toggleYummie(ref, restaurant, item);
                          } else if (value == 'delete') {
                            _deleteMenuItem(ref, restaurant, item);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                          PopupMenuItem(
                            value: 'yummie',
                            child: Text(item.isYummie
                                ? l10n.restaurantMenuRemoveYummie
                                : l10n.restaurantMenuMarkYummie),
                          ),
                          PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                        ],
                      ),
                    );
                  },
                  childCount: filteredMenu.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_isSearchExpanded)
                Card(
                  elevation: 6,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: SizedBox(
                      width: 240,
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.searchDishes,
                          prefixIcon: const Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    heroTag: 'fab_search',
                    onPressed: () => setState(() {
                      _isSearchExpanded = !_isSearchExpanded;
                      if (!_isSearchExpanded) {
                        _searchQuery = '';
                        _searchController.clear();
                      }
                    }),
                    child: Icon(_isSearchExpanded ? Icons.close : Icons.search),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton(
                    heroTag: 'fab_add',
                    onPressed: () => _showAddMenuItemSheet(context, ref, restaurant),
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(AppLocalizations.of(context)!.errorMessage(error.toString()))),
      ),
    );
  }

  void _toggleYummie(WidgetRef ref, Restaurant restaurant, MenuItem item) {
    final updatedItem = item.copyWith(isYummie: !item.isYummie);
    final updatedMenu =
        restaurant.menu.map((i) => i.id == item.id ? updatedItem : i).toList();
    ref.read(restaurantsProvider.notifier).updateRestaurant(
          restaurant.copyWith(menu: updatedMenu),
        );
  }

  Future<void> _deleteTemplate(BuildContext context, WidgetRef ref,
      SavedOrder template, AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.restaurantTemplateDeleteTitle),
        content: Text(l10n.restaurantTemplateDeleteMessage(template.label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref
          .read(savedOrderActionsProvider)
          .deleteTemplate(template.id, template.restaurantId);
    }
  }

  void _editTemplate(WidgetRef ref, Restaurant restaurant, SavedOrder template,
      AppLocalizations l10n) {
    showModalBottomSheet(
      context: ref.context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => _AddTemplateSheet(
        restaurant: restaurant,
        editingTemplate: template,
        onSave: (label, selectedIds) async {
          if (label.isEmpty || selectedIds.isEmpty) return;
          final entries = selectedIds.map((id) {
            final item = restaurant.menu.where((m) => m.id == id).firstOrNull;
            return SubOrderEntry(menuItemId: id, name: item?.name ?? id, quantity: 1);
          }).toList();
          await ref.read(savedOrderActionsProvider).saveTemplate(
                restaurantId: restaurant.id,
                label: label,
                entries: entries,
              );
          final confirmDelete = await showDialog<bool>(
            context: sheetContext,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.restaurantTemplateReplaceTitle),
              content: Text(l10n.restaurantTemplateReplaceMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.keep),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(ctx).colorScheme.error,
                  ),
                  child: Text(l10n.delete),
                ),
              ],
            ),
          );
          if (confirmDelete == true) {
            await ref
                .read(savedOrderActionsProvider)
                .deleteTemplate(template.id, template.restaurantId);
          }
          if (sheetContext.mounted) Navigator.pop(sheetContext);
        },
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, Restaurant restaurant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => EditRestaurantSheet(
        restaurant: restaurant,
        onSave: (name, address, coverImagePath) async {
          final updated = restaurant.copyWith(
            name: name,
            address: address,
            coverImagePath: coverImagePath,
          );
          await ref.read(restaurantsProvider.notifier).updateRestaurant(updated);
          ref.invalidate(restaurantDetailProvider(widget.restaurantId));
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _showAddMenuItemSheet(
      BuildContext context, WidgetRef ref, Restaurant restaurant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _MenuItemSheet(
        nextNumber: restaurant.menu.length + 1,
        onSave: (name, description, itemNumber) async {
          if (name.trim().isEmpty) return;
          final newItem = MenuItem(
            id: const Uuid().v4(),
            name: name.trim(),
            description: description,
            itemNumber: itemNumber,
          );
          final updated = restaurant.copyWith(menu: [...restaurant.menu, newItem]);
          await ref.read(restaurantsProvider.notifier).updateRestaurant(updated);
          ref.invalidate(restaurantDetailProvider(widget.restaurantId));
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditMenuItemSheet(
      BuildContext context, WidgetRef ref, Restaurant restaurant, MenuItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _MenuItemSheet(
        initialName: item.name,
        initialDescription: item.description,
        initialNumber: item.itemNumber,
        isEditing: true,
        onSave: (name, description, itemNumber) async {
          if (name.trim().isEmpty) return;
          final updatedItem = item.copyWith(
            name: name.trim(),
            description: description,
            itemNumber: itemNumber,
          );
          final updatedMenu =
              restaurant.menu.map((i) => i.id == item.id ? updatedItem : i).toList();
          final updated = restaurant.copyWith(menu: updatedMenu);
          await ref.read(restaurantsProvider.notifier).updateRestaurant(updated);
          ref.invalidate(restaurantDetailProvider(widget.restaurantId));
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _deleteMenuItem(WidgetRef ref, Restaurant restaurant, MenuItem item) {
    final updatedMenu = restaurant.menu.where((i) => i.id != item.id).toList();
    ref.read(restaurantsProvider.notifier).updateRestaurant(
          restaurant.copyWith(menu: updatedMenu),
        );
    ref.invalidate(restaurantDetailProvider(widget.restaurantId));
  }

  void _showAddTemplateSheet(
      BuildContext context, WidgetRef ref, Restaurant restaurant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _AddTemplateSheet(
        restaurant: restaurant,
        onSave: (label, selectedIds) async {
          if (label.isEmpty || selectedIds.isEmpty) return;
          final entries = selectedIds.map((id) {
            final item = restaurant.menu.where((m) => m.id == id).firstOrNull;
            return SubOrderEntry(menuItemId: id, name: item?.name ?? id, quantity: 1);
          }).toList();
          await ref.read(savedOrderActionsProvider).saveTemplate(
                restaurantId: restaurant.id,
                label: label,
                entries: entries,
              );
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }
}

// ── Add Template Sheet ────────────────────────────────────────────────────────

class _AddTemplateSheet extends StatefulWidget {
  final Restaurant restaurant;
  final SavedOrder? editingTemplate;
  final Future<void> Function(String label, Set<String> selectedIds) onSave;

  const _AddTemplateSheet({
    required this.restaurant,
    this.editingTemplate,
    required this.onSave,
  });

  @override
  State<_AddTemplateSheet> createState() => _AddTemplateSheetState();
}

class _AddTemplateSheetState extends State<_AddTemplateSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _searchController;
  late final Set<String> _selectedIds;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.editingTemplate?.label ?? '',
    );
    _searchController = TextEditingController();
    _selectedIds = widget.editingTemplate?.entries
            .map((e) => e.menuItemId)
            .toSet() ??
        {};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final sortedMenu = List<MenuItem>.from(widget.restaurant.menu)
      ..sort((a, b) {
        if (a.isYummie && !b.isYummie) return -1;
        if (!a.isYummie && b.isYummie) return 1;
        return (a.itemNumber ?? 0).compareTo(b.itemNumber ?? 0);
      });
    final filteredMenu = _searchQuery.isEmpty
        ? sortedMenu
        : sortedMenu.where((item) {
            final q = _searchQuery.toLowerCase();
            return item.name.toLowerCase().contains(q) ||
                (item.description?.toLowerCase().contains(q) ?? false) ||
                (item.itemNumber?.toString().contains(q) ?? false);
          }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DragHandle(scheme: scheme),
                Text(
                  widget.editingTemplate != null
                      ? l10n.restaurantTemplateEditTitle
                      : l10n.restaurantTemplateNewTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.restaurantTemplateNameLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.restaurantTemplateSelectDishes,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchDishes,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: filteredMenu.length,
              itemBuilder: (context, index) {
                final item = filteredMenu[index];
                return StatefulBuilder(
                  builder: (context, setItem) => CheckboxListTile(
                    value: _selectedIds.contains(item.id),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedIds.add(item.id);
                        } else {
                          _selectedIds.remove(item.id);
                        }
                      });
                    },
                    secondary: CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      child: Text('${item.itemNumber ?? '-'}'),
                    ),
                    title: Row(
                      children: [
                        if (item.isYummie) ...[
                          const Icon(Icons.restaurant, size: 14),
                          const SizedBox(width: 4),
                        ],
                        Expanded(child: Text(item.name)),
                      ],
                    ),
                    subtitle: item.description != null ? Text(item.description!) : null,
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: _selectedIds.isNotEmpty && _nameController.text.trim().isNotEmpty
                    ? () => widget.onSave(_nameController.text.trim(), _selectedIds)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(l10n.restaurantTemplateSave(_selectedIds.length)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Edit Restaurant Sheet ─────────────────────────────────────────────────────

class EditRestaurantSheet extends StatefulWidget {
  final Restaurant restaurant;
  final Future<void> Function(
      String name, String? address, String? coverImagePath) onSave;

  const EditRestaurantSheet(
      {super.key, required this.restaurant, required this.onSave});

  @override
  State<EditRestaurantSheet> createState() => _EditRestaurantSheetState();
}

class _EditRestaurantSheetState extends State<EditRestaurantSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  String? _coverImagePath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.restaurant.name);
    _addressController =
        TextEditingController(text: widget.restaurant.address ?? '');
    _coverImagePath = widget.restaurant.coverImagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'restaurant_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final saved = await File(image.path).copy('${appDir.path}/$fileName');
      setState(() => _coverImagePath = saved.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DragHandle(scheme: scheme),
            Text(l10n.restaurantEditTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_coverImagePath != null)
                      Image.file(File(_coverImagePath!), fit: BoxFit.cover)
                    else
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 40, color: scheme.outline),
                          const SizedBox(height: 8),
                          Text(l10n.restaurantAddCoverPhoto,
                              style: TextStyle(color: scheme.outline)),
                        ],
                      ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: scheme.primaryContainer,
                        child: Icon(Icons.edit, size: 16, color: scheme.onPrimaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.restaurantNameLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: l10n.restaurantAddressLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => widget.onSave(
                      _nameController.text.trim(),
                      _addressController.text.trim().isEmpty
                          ? null
                          : _addressController.text.trim(),
                      _coverImagePath,
                    ),
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Menu Item Sheet ───────────────────────────────────────────────────────────

class _MenuItemSheet extends StatefulWidget {
  final String? initialName;
  final String? initialDescription;
  final int? initialNumber;
  final int nextNumber;
  final bool isEditing;
  final Future<void> Function(
      String name, String? description, int? itemNumber) onSave;

  const _MenuItemSheet({
    this.initialName,
    this.initialDescription,
    this.initialNumber,
    this.nextNumber = 1,
    this.isEditing = false,
    required this.onSave,
  });

  @override
  State<_MenuItemSheet> createState() => _MenuItemSheetState();
}

class _MenuItemSheetState extends State<_MenuItemSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _numberController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _descriptionController =
        TextEditingController(text: widget.initialDescription ?? '');
    _numberController = TextEditingController(
      text: widget.initialNumber?.toString() ?? widget.nextNumber.toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DragHandle(scheme: scheme),
            Text(
              widget.isEditing ? l10n.restaurantMenuItemEditTitle : l10n.restaurantMenuItemAddTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.restaurantMenuItemNameLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.restaurantMenuItemDescLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _numberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.restaurantMenuItemNumberLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      if (_nameController.text.trim().isEmpty) return;
                      widget.onSave(
                        _nameController.text.trim(),
                        _descriptionController.text.trim().isEmpty
                            ? null
                            : _descriptionController.text.trim(),
                        int.tryParse(_numberController.text),
                      );
                    },
                    child: Text(widget.isEditing ? l10n.save : l10n.add),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared ────────────────────────────────────────────────────────────────────

class _TemplateChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TemplateChip({required this.label, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bookmarks_outlined, size: 16),
              const SizedBox(width: 6),
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(width: 4),
              InkWell(onTap: onDelete, child: const Icon(Icons.close, size: 16)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  final ColorScheme scheme;
  const _DragHandle({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 32,
        height: 4,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: scheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
