import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/models/restaurant.dart';
import '../../viewmodels/restaurant_viewmodel.dart';

class RestaurantDetailPage extends ConsumerWidget {
  final String restaurantId;

  const RestaurantDetailPage({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantAsync = ref.watch(restaurantDetailProvider(restaurantId));

    return restaurantAsync.when(
      data: (restaurant) {
        if (restaurant == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Restaurant not found')),
          );
        }

        final sortedMenu = List<MenuItem>.from(restaurant.menu)
          ..sort((a, b) => (a.itemNumber ?? 0).compareTo(b.itemNumber ?? 0));

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
                              Colors.black,
                              Colors.black.withValues(alpha: 0.9),
                              Colors.black.withValues(alpha: 0.7),
                              Colors.transparent,
                            ],
                          ).createShader(
                              Rect.fromLTRB(0, 0, rect.width, rect.height)),
                          blendMode: BlendMode.dstIn,
                          child: Image.file(
                            File(restaurant.coverImagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              child: const Icon(Icons.restaurant, size: 64),
                            ),
                          ),
                        )
                      : Container(
                          color:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.restaurant,
                            size: 64,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
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
                            title: const Text('Delete Restaurant'),
                            content: Text(
                                'Are you sure you want to delete "${restaurant.name}"?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.error,
                                ),
                                child: const Text('Delete'),
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
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                          value: 'delete', child: Text('Delete')),
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
                            color:
                                Theme.of(context).colorScheme.outline),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(restaurant.address!,
                              style:
                                  Theme.of(context).textTheme.bodyLarge),
                        ),
                      ],
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text('Menu',
                          style: Theme.of(context).textTheme.titleLarge),
                      const Spacer(),
                      FilledButton.tonalIcon(
                        onPressed: () =>
                            context.push('/scan-menu/$restaurantId'),
                        icon: const Icon(Icons.document_scanner),
                        label: const Text('Scan'),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = sortedMenu[index];
                    return ListTile(
                      leading: item.itemNumber != null
                          ? CircleAvatar(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              child: Text('${item.itemNumber}'),
                            )
                          : null,
                      title: Text(item.name),
                      subtitle: item.description != null
                          ? Text(item.description!)
                          : null,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditMenuItemSheet(
                                context, ref, restaurant, item);
                          } else if (value == 'delete') {
                            _deleteMenuItem(ref, restaurant, item);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                              value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(
                              value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    );
                  },
                  childCount: sortedMenu.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () =>
                _showAddMenuItemSheet(context, ref, restaurant),
            child: const Icon(Icons.add),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  void _showEditSheet(
      BuildContext context, WidgetRef ref, Restaurant restaurant) {
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
          ref.invalidate(restaurantDetailProvider(restaurantId));
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
          final updated =
              restaurant.copyWith(menu: [...restaurant.menu, newItem]);
          await ref.read(restaurantsProvider.notifier).updateRestaurant(updated);
          ref.invalidate(restaurantDetailProvider(restaurantId));
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
          final updatedMenu = restaurant.menu
              .map((i) => i.id == item.id ? updatedItem : i)
              .toList();
          final updated = restaurant.copyWith(menu: updatedMenu);
          await ref.read(restaurantsProvider.notifier).updateRestaurant(updated);
          ref.invalidate(restaurantDetailProvider(restaurantId));
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _deleteMenuItem(WidgetRef ref, Restaurant restaurant, MenuItem item) {
    final updatedMenu =
        restaurant.menu.where((i) => i.id != item.id).toList();
    final updated = restaurant.copyWith(menu: updatedMenu);
    ref.read(restaurantsProvider.notifier).updateRestaurant(updated);
    ref.invalidate(restaurantDetailProvider(restaurantId));
  }
}

// ── Edit Restaurant Sheet ────────────────────────────────────────────────────

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
    _nameController =
        TextEditingController(text: widget.restaurant.name);
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
      final fileName =
          'restaurant_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final saved =
          await File(image.path).copy('${appDir.path}/$fileName');
      setState(() => _coverImagePath = saved.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DragHandle(scheme: scheme),
            Text('Edit Restaurant',
                style: Theme.of(context).textTheme.titleLarge),
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
                          Text('Add Cover Photo',
                              style: TextStyle(color: scheme.outline)),
                        ],
                      ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: scheme.primaryContainer,
                        child: Icon(Icons.edit,
                            size: 16,
                            color: scheme.onPrimaryContainer),
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
              decoration: const InputDecoration(
                labelText: 'Restaurant Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
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
                    child: const Text('Save'),
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

// ── Menu Item Sheet (add & edit) ─────────────────────────────────────────────

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
    _nameController =
        TextEditingController(text: widget.initialName ?? '');
    _descriptionController =
        TextEditingController(text: widget.initialDescription ?? '');
    _numberController = TextEditingController(
      text: widget.initialNumber?.toString() ??
          widget.nextNumber.toString(),
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
              widget.isEditing ? 'Edit Menu Item' : 'Add Menu Item',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _numberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Item Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
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
                    child:
                        Text(widget.isEditing ? 'Save' : 'Add'),
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

// ── Shared ───────────────────────────────────────────────────────────────────

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
