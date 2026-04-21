import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
                  title: Text(
                    restaurant.name,
                  ),
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
                          ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height)),
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
                        _showEditDialog(context, ref, restaurant);
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Restaurant'),
                            content: Text('Are you sure you want to delete "${restaurant.name}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          await ref.read(restaurantsProvider.notifier).deleteRestaurant(restaurantId);
                          if (context.mounted) context.pop();
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
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
                        Icon(
                          Icons.location_on_outlined,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            restaurant.address!,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
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
                      Text(
                        'Menu',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      FilledButton.tonalIcon(
                        onPressed: () => context.push('/scan-menu/$restaurantId'),
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
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              child: Text('${item.itemNumber}'),
                            )
                          : null,
                      title: Text(item.name),
                      subtitle: item.description != null ? Text(item.description!) : null,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditMenuItemDialog(context, ref, restaurant, item);
                          } else if (value == 'delete') {
                            _deleteMenuItem(context, ref, restaurant, item);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
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
            onPressed: () => _showAddMenuItemDialog(context, ref, restaurant),
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

  void _showEditDialog(BuildContext context, WidgetRef ref, Restaurant restaurant) {
    final nameController = TextEditingController(text: restaurant.name);
    final addressController = TextEditingController(text: restaurant.address ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Restaurant'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Restaurant Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final updated = restaurant.copyWith(
                name: nameController.text.trim(),
                address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
              );
              await ref.read(restaurantsProvider.notifier).updateRestaurant(updated);
              ref.invalidate(restaurantDetailProvider(restaurantId));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddMenuItemDialog(BuildContext context, WidgetRef ref, Restaurant restaurant) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final itemNumberController = TextEditingController(text: '${restaurant.menu.length + 1}');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Menu Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: itemNumberController,
                decoration: const InputDecoration(
                  labelText: 'Item Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              final newItem = MenuItem(
                id: const Uuid().v4(),
                name: nameController.text.trim(),
                description: descriptionController.text.trim().isEmpty
                    ? null
                    : descriptionController.text.trim(),
                itemNumber: int.tryParse(itemNumberController.text),
              );

              final updated = restaurant.copyWith(
                menu: [...restaurant.menu, newItem],
              );
              await ref.read(restaurantsProvider.notifier).updateRestaurant(updated);
              ref.invalidate(restaurantDetailProvider(restaurantId));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditMenuItemDialog(BuildContext context, WidgetRef ref, Restaurant restaurant, MenuItem item) {
    final nameController = TextEditingController(text: item.name);
    final descriptionController = TextEditingController(text: item.description ?? '');
    final itemNumberController = TextEditingController(text: item.itemNumber?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Menu Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: itemNumberController,
                decoration: const InputDecoration(
                  labelText: 'Item Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              final updatedItem = item.copyWith(
                name: nameController.text.trim(),
                description: descriptionController.text.trim().isEmpty
                    ? null
                    : descriptionController.text.trim(),
                itemNumber: int.tryParse(itemNumberController.text),
              );

              final updatedMenu = restaurant.menu.map((i) => i.id == item.id ? updatedItem : i).toList();
              final updated = restaurant.copyWith(menu: updatedMenu);
              await ref.read(restaurantsProvider.notifier).updateRestaurant(updated);
              ref.invalidate(restaurantDetailProvider(restaurantId));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteMenuItem(BuildContext context, WidgetRef ref, Restaurant restaurant, MenuItem item) async {
    final updatedMenu = restaurant.menu.where((i) => i.id != item.id).toList();
    final updated = restaurant.copyWith(menu: updatedMenu);
    await ref.read(restaurantsProvider.notifier).updateRestaurant(updated);
    ref.invalidate(restaurantDetailProvider(restaurantId));
  }
}
