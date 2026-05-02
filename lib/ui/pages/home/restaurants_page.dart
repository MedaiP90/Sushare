import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/style/app_style.dart';
import '../../../domain/models/restaurant.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/widgets/glass_aware_app_bar.dart';
import '../../core/widgets/glass_aware_scaffold.dart';
import '../../viewmodels/restaurant_viewmodel.dart';
import '../../viewmodels/saved_order_viewmodel.dart';
import '../restaurant/restaurant_detail_page.dart';

class RestaurantsPage extends ConsumerWidget {
  const RestaurantsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantsAsync = ref.watch(restaurantsProvider);
    final l10n = AppLocalizations.of(context)!;
    final isGlass = ref.watch(styleModeProvider) == AppStyleMode.liquidGlass;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final iconColor = isLight ? Colors.black87 : Colors.white;
    final glassSettings = LiquidGlassSettings(
      blur: isLight ? 12 : 8,
      thickness: 25,
      glassColor: isLight ? const Color(0x18000000) : const Color(0x30FFFFFF),
    );

    return GlassAwareScaffold(
      appBar: GlassAwareAppBar(
        title: Text(l10n.restaurantsTitle),
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
                  Text(l10n.restaurantsEmpty, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    l10n.restaurantsEmptySubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _showAddRestaurantSheet(context, ref, l10n),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.restaurantsAdd),
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
              final templatesAsync =
                  ref.watch(savedOrdersForRestaurantProvider(restaurant.id));
              final templateCount = templatesAsync.valueOrNull?.length ?? 0;
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => context.push('/restaurants/${restaurant.id}'),
                  onLongPress: () =>
                      _showRestaurantActions(context, ref, restaurant, l10n),
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
                            Text(restaurant.name, style: Theme.of(context).textTheme.titleLarge),
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
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Chip(
                                  label: Text(l10n.restaurantDishes(restaurant.menu.length)),
                                  visualDensity: VisualDensity.compact,
                                ),
                                if (templateCount > 0)
                                  Chip(
                                    label: Text(l10n.restaurantTemplatesCount(templateCount)),
                                    visualDensity: VisualDensity.compact,
                                  ),
                              ],
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
              Text(l10n.errorMessage(error.toString())),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(restaurantsProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: isGlass
          ? GlassButton.custom(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: iconColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.restaurantsAdd,
                    style: TextStyle(
                        color: iconColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              onTap: () => _showAddRestaurantSheet(context, ref, l10n),
              width: 200,
              height: 56,
              shape: const LiquidRoundedSuperellipse(borderRadius: 28),
              useOwnLayer: true,
              settings: glassSettings,
            )
          : FloatingActionButton.extended(
              onPressed: () => _showAddRestaurantSheet(context, ref, l10n),
              icon: const Icon(Icons.add),
              label: Text(l10n.restaurantsAdd),
            ),
    );
  }

  void _showRestaurantActions(
      BuildContext context, WidgetRef ref, Restaurant restaurant, AppLocalizations l10n) {
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
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.edit),
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
                      await ref.read(restaurantsProvider.notifier).updateRestaurant(updated);
                      if (editContext.mounted) Navigator.pop(editContext);
                    },
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline,
                  color: Theme.of(sheetContext).colorScheme.error),
              title: Text(
                l10n.delete,
                style: TextStyle(color: Theme.of(sheetContext).colorScheme.error),
              ),
              onTap: () async {
                Navigator.pop(sheetContext);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(l10n.restaurantDeleteTitle),
                    content: Text(l10n.restaurantDeleteMessage(restaurant.name)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: Text(l10n.cancel),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(dialogContext).colorScheme.error,
                        ),
                        child: Text(l10n.delete),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await ref.read(restaurantsProvider.notifier).deleteRestaurant(restaurant.id);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAddRestaurantSheet(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
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
    final l10n = AppLocalizations.of(context)!;

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
            Text(l10n.restaurantAddTitle, style: Theme.of(context).textTheme.titleLarge),
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
                          Icon(Icons.add_photo_alternate_outlined, size: 40, color: scheme.outline),
                          const SizedBox(height: 8),
                          Text(l10n.restaurantAddCoverPhoto,
                              style: TextStyle(color: scheme.outline)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: widget.nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.restaurantNameLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: widget.addressController,
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
                    onPressed: () => widget.onAdd(_coverImagePath),
                    child: Text(l10n.add),
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
