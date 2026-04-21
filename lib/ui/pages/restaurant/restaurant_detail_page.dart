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

        final groupedMenu = <String, List<MenuItem>>{};
        for (final item in restaurant.menu) {
          groupedMenu.putIfAbsent(item.category, () => []).add(item);
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    restaurant.name,
                    style: const TextStyle(
                      shadows: [Shadow(blurRadius: 4)],
                    ),
                  ),
                  background: restaurant.coverImagePath != null
                      ? Image.file(
                          File(restaurant.coverImagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            child: const Icon(Icons.restaurant, size: 64),
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
                        label: const Text('Scan Menu'),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              ...groupedMenu.entries.map((entry) {
                return SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          entry.key,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                      ...entry.value.map((item) => ListTile(
                            title: Text(item.name),
                            subtitle: item.description != null ? Text(item.description!) : null,
                            trailing: item.imageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      item.imageUrl!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.fastfood),
                                    ),
                                  )
                                : null,
                          )),
                    ],
                  ),
                );
              }),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
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
}
