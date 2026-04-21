import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../domain/models/restaurant.dart';
import '../../viewmodels/restaurant_viewmodel.dart';
import '../restaurant/restaurant_detail_page.dart';

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
                    onPressed: () => _showAddRestaurantSheet(context, ref),
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
                  onLongPress: () =>
                      _showRestaurantActions(context, ref, restaurant),
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
        onPressed: () => _showAddRestaurantSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Restaurant'),
      ),
    );
  }

  void _showRestaurantActions(
      BuildContext context, WidgetRef ref, Restaurant restaurant) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  restaurant.name,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(sheetContext);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (editContext) => EditRestaurantSheet(
                    restaurant: restaurant,
                    onSave: (name, address, coverImagePath) async {
                      final updated = restaurant.copyWith(
                        name: name,
                        address: address,
                        coverImagePath: coverImagePath,
                      );
                      await ref
                          .read(restaurantsProvider.notifier)
                          .updateRestaurant(updated);
                      if (editContext.mounted) Navigator.pop(editContext);
                    },
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline,
                  color: Theme.of(sheetContext).colorScheme.error),
              title: Text('Delete',
                  style: TextStyle(
                      color: Theme.of(sheetContext).colorScheme.error)),
              onTap: () async {
                Navigator.pop(sheetContext);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Delete Restaurant'),
                    content: Text(
                        'Are you sure you want to delete "${restaurant.name}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              Theme.of(dialogContext).colorScheme.error,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await ref
                      .read(restaurantsProvider.notifier)
                      .deleteRestaurant(restaurant.id);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAddRestaurantSheet(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _AddRestaurantSheet(
        nameController: nameController,
        addressController: addressController,
        onAdd: (coverImagePath) async {
          if (nameController.text.trim().isEmpty) return;
          await ref.read(restaurantsProvider.notifier).addRestaurant(
                name: nameController.text.trim(),
                address: addressController.text.trim().isEmpty
                    ? null
                    : addressController.text.trim(),
                coverImagePath: coverImagePath,
                menu: [],
              );
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }
}

class _AddRestaurantSheet extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController addressController;
  final Future<void> Function(String? coverImagePath) onAdd;

  const _AddRestaurantSheet({
    required this.nameController,
    required this.addressController,
    required this.onAdd,
  });

  @override
  State<_AddRestaurantSheet> createState() => _AddRestaurantSheetState();
}

class _AddRestaurantSheetState extends State<_AddRestaurantSheet> {
  String? _coverImagePath;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'restaurant_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await File(image.path).copy('${appDir.path}/$fileName');
      setState(() => _coverImagePath = savedImage.path);
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
            Center(
              child: Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Add Restaurant',
              style: Theme.of(context).textTheme.titleLarge,
            ),
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
                child: _coverImagePath != null
                    ? Image.file(File(_coverImagePath!), fit: BoxFit.cover)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 40, color: scheme.outline),
                          const SizedBox(height: 8),
                          Text('Add Cover Photo',
                              style: TextStyle(color: scheme.outline)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: widget.nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Restaurant Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: widget.addressController,
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
                    onPressed: () => widget.onAdd(_coverImagePath),
                    child: const Text('Add'),
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