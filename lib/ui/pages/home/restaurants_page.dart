import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/models/restaurant.dart';
import '../../viewmodels/restaurant_viewmodel.dart';

class RestaurantsPage extends ConsumerWidget {
  const RestaurantsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantsAsync = ref.watch(restaurantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurants'),
        centerTitle: true,
      ),
      body: restaurantsAsync.when(
        data: (restaurants) {
          if (restaurants.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No restaurants yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first restaurant to get started',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _showAddRestaurantDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Restaurant'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final restaurant = restaurants[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => context.push('/restaurants/${restaurant.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (restaurant.coverImagePath != null)
                        Image.file(
                          File(restaurant.coverImagePath!),
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 150,
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.restaurant, size: 48),
                          ),
                        )
                      else
                        Container(
                          height: 120,
                          width: double.infinity,
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.restaurant,
                            size: 48,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              restaurant.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            if (restaurant.address != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      restaurant.address!,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(context).colorScheme.outline,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            Chip(
                              label: Text('${restaurant.menu.length} items'),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(restaurantsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRestaurantDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Restaurant'),
      ),
    );
  }

  void _showAddRestaurantDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final menuItems = <Map<String, String>>[];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Restaurant'),
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
                    labelText: 'Address (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Menu Items (${menuItems.length})'),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          menuItems.add({'name': '', 'category': 'Main'});
                        });
                      },
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                ...menuItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Item ${index + 1}',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (v) => item['name'] = v,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: item['category'],
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Main', child: Text('Main')),
                              DropdownMenuItem(value: 'Side', child: Text('Side')),
                              DropdownMenuItem(value: 'Drink', child: Text('Drink')),
                            ],
                            onChanged: (v) => setState(() => item['category'] = v!),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => menuItems.removeAt(index)),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  );
                }),
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

                final List<MenuItem> menu = menuItems
                    .where((item) => item['name']!.isNotEmpty)
                    .map<MenuItem>((item) => MenuItem(
                          id: const Uuid().v4(),
                          name: item['name']!,
                          category: item['category'] ?? 'Main',
                        ))
                    .toList();

                await ref.read(restaurantsProvider.notifier).addRestaurant(
                      name: nameController.text.trim(),
                      address: addressController.text.trim().isEmpty
                          ? null
                          : addressController.text.trim(),
                      menu: menu,
                    );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
