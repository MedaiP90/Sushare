import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/models/restaurant.dart';
import '../../../domain/models/personal_sub_order.dart';
import '../../../domain/models/saved_order.dart';
import '../../../domain/models/session.dart';
import '../../viewmodels/session_viewmodel.dart';
import '../../viewmodels/restaurant_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/personal_order_viewmodel.dart';
import '../../viewmodels/saved_order_viewmodel.dart';

class PersonalOrderContent extends ConsumerStatefulWidget {
  final String sessionId;

  const PersonalOrderContent({super.key, required this.sessionId});

  @override
  ConsumerState<PersonalOrderContent> createState() => _PersonalOrderContentState();
}

class _PersonalOrderContentState extends ConsumerState<PersonalOrderContent> {
  final _quantities = <String, int>{};
  DateTime? _lastLoadedAt;

  @override
  Widget build(BuildContext context, ) {
    final sessionAsync = ref.watch(sessionDetailProvider(widget.sessionId));
    final user = ref.watch(profileViewModelProvider).value;

    if (user == null) {
      return const Center(child: Text('Please log in first'));
    }

    return sessionAsync.when(
      data: (session) {
        if (session == null) {
          return const Center(child: Text('Table not found'));
        }

        final restaurantAsync = ref.watch(restaurantDetailProvider(session.restaurantId));
        final personalOrderKey = '${widget.sessionId}:${user.id}';
        final personalOrderAsync = ref.watch(personalOrderProvider(personalOrderKey));
        final templatesAsync = ref.watch(savedOrdersForRestaurantProvider(session.restaurantId));

        return restaurantAsync.when(
          data: (restaurant) {
            if (restaurant == null) {
              return const Center(child: Text('Restaurant not found'));
            }

            personalOrderAsync.whenData((order) {
              final orderUpdatedAt = order?.updatedAt;
              final isNewer = _lastLoadedAt == null ||
                  (orderUpdatedAt != null && orderUpdatedAt.isAfter(_lastLoadedAt!));
              if (isNewer) {
                _lastLoadedAt = orderUpdatedAt ?? DateTime.now();
                _quantities.clear();
                if (order != null) {
                  for (final entry in order.entries) {
                    _quantities[entry.menuItemId] = entry.quantity;
                  }
                }
              }
            });

            final orderedItems = _quantities.entries
                .where((e) => e.value > 0)
                .map((e) {
                  final menuItem = restaurant.menu.where((m) => m.id == e.key).firstOrNull;
                  final name = menuItem?.name ?? e.key;
                  return _OrderedItem(
                    id: e.key,
                    name: name,
                    quantity: e.value,
                    isYummie: menuItem?.isYummie ?? false,
                  );
                })
                .toList();

            final totalItems = _quantities.values.fold(0, (a, b) => a + b);
            final isEditable = session.status != SessionStatus.closed;
            final templates = templatesAsync.valueOrNull ?? [];

            final String userName = user.username;
            final String userFullName = '${user.firstName} ${user.lastName}'.trim();
            final String? userProfilePicturePath = user.profilePicturePath;

            return Scaffold(
              body: orderedItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_shopping_cart,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your order is empty',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the button below to add dishes',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          'Your Order ($totalItems items)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        ...orderedItems.map((item) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primaryContainer,
                                  child: Text(
                                      '${_getItemNumber(restaurant, item.id) ?? '-'}'),
                                ),
                                title: Row(
                                  children: [
                                    if (item.isYummie) ...[
                                      Icon(Icons.restaurant,
                                          size: 14, color: Colors.amber[700]),
                                      const SizedBox(width: 4),
                                    ],
                                    Expanded(child: Text(item.name)),
                                  ],
                                ),
                                trailing: isEditable
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove),
                                            onPressed: () async {
                                              final qty = _quantities[item.id] ?? 0;
                                              setState(() {
                                                if (qty > 1) {
                                                  _quantities[item.id] = qty - 1;
                                                } else {
                                                  _quantities.remove(item.id);
                                                }
                                              });
                                              await _saveOrder(context, user.id, restaurant.menu,
                                                  silent: true,
                                                  userName: userName,
                                                  userFullName: userFullName,
                                                  userProfilePicturePath: userProfilePicturePath);
                                            },
                                          ),
                                          SizedBox(
                                            width: 32,
                                            child: Text(
                                              '${item.quantity}',
                                              textAlign: TextAlign.center,
                                              style: Theme.of(context).textTheme.titleMedium,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add),
                                            onPressed: () async {
                                              setState(() {
                                                _quantities[item.id] =
                                                    (_quantities[item.id] ?? 0) + 1;
                                              });
                                              await _saveOrder(context, user.id, restaurant.menu,
                                                  silent: true,
                                                  userName: userName,
                                                  userFullName: userFullName,
                                                  userProfilePicturePath: userProfilePicturePath);
                                            },
                                          ),
                                        ],
                                      )
                                    : Text(
                                        'x${item.quantity}',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                              ),
                            )),
                      ],
                    ),
              floatingActionButton: isEditable
                  ? _SpeedDial(
                      items: [
                        if (_quantities.isNotEmpty)
                          _DialItem(
                            icon: Icons.bookmark_add_outlined,
                            label: 'Save as template',
                            onTap: () => _saveAsTemplate(
                                context, ref, restaurant, userName),
                          ),
                        if (templates.isNotEmpty)
                          _DialItem(
                            icon: Icons.bookmarks_outlined,
                            label: 'Use template',
                            onTap: () => _showUseTemplateSheet(
                                context, ref, templates, restaurant, user.id,
                                userName, userFullName, userProfilePicturePath),
                          ),
                        _DialItem(
                          icon: Icons.restaurant_menu,
                          label: 'Menu',
                          onTap: () => _showAddFromMenuSheet(
                              context, restaurant, user.id, userName,
                              userFullName, userProfilePicturePath),
                        ),
                        _DialItem(
                          icon: Icons.add,
                          label: 'Custom dish',
                          onTap: () => _showAddCustomDishSheet(
                              context, restaurant, user.id, userName,
                              userFullName, userProfilePicturePath),
                        ),
                      ],
                    )
                  : null,
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  int? _getItemNumber(Restaurant restaurant, String itemId) {
    final item = restaurant.menu.where((m) => m.id == itemId).firstOrNull;
    return item?.itemNumber;
  }

  void _showAddFromMenuSheet(BuildContext context, Restaurant restaurant,
      String userId, String userName, String userFullName, String? userProfilePicturePath) {
    final selectedIds = <String>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            final currentRestaurant =
                ref.read(restaurantDetailProvider(restaurant.id)).valueOrNull ?? restaurant;
            final sortedMenu = List<MenuItem>.from(currentRestaurant.menu)
              ..sort((a, b) {
                if (a.isYummie && !b.isYummie) return -1;
                if (!a.isYummie && b.isYummie) return 1;
                return (a.itemNumber ?? 0).compareTo(b.itemNumber ?? 0);
              });

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        'Add from Menu',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: sortedMenu.length,
                    itemBuilder: (context, index) {
                      final item = sortedMenu[index];
                      final isSelected = selectedIds.contains(item.id);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (checked) {
                          setSheetState(() {
                            if (checked == true) {
                              selectedIds.add(item.id);
                            } else {
                              selectedIds.remove(item.id);
                            }
                          });
                        },
                        secondary: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: Text('${item.itemNumber ?? '-'}'),
                        ),
                        title: Row(
                          children: [
                            if (item.isYummie) ...[
                              Icon(Icons.restaurant,
                                  size: 14, color: Colors.amber[700]),
                              const SizedBox(width: 4),
                            ],
                            Expanded(child: Text(item.name)),
                          ],
                        ),
                        subtitle: item.description != null
                            ? Text(item.description!)
                            : null,
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton(
                      onPressed: selectedIds.isNotEmpty
                          ? () async {
                              Navigator.pop(context);
                              setState(() {
                                for (final id in selectedIds) {
                                  _quantities[id] = (_quantities[id] ?? 0) + 1;
                                }
                              });
                              final r = ref
                                      .read(restaurantDetailProvider(restaurant.id))
                                      .valueOrNull ??
                                  restaurant;
                              await _saveOrder(context, userId, r.menu,
                                  userName: userName,
                                  userFullName: userFullName,
                                  userProfilePicturePath: userProfilePicturePath);
                            }
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Add ${selectedIds.length} items'),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showAddCustomDishSheet(BuildContext context, Restaurant restaurant,
      String userId, String userName, String userFullName, String? userProfilePicturePath) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final numberController = TextEditingController();

    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Add Custom Dish',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Dish name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: numberController,
              decoration: const InputDecoration(
                labelText: 'Menu number (optional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                Navigator.pop(context, {
                  'name': nameController.text.trim(),
                  'description': descController.text.trim(),
                  'number': numberController.text.trim(),
                });
              },
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Add'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      final dishId = const Uuid().v4();
      final currentRestaurantForNum =
          ref.read(restaurantDetailProvider(restaurant.id)).valueOrNull ?? restaurant;
      final maxNumber = currentRestaurantForNum.menu
          .map((m) => m.itemNumber ?? 0)
          .fold(0, (a, b) => a > b ? a : b);
      final number =
          result['number']!.isEmpty ? maxNumber + 1 : int.tryParse(result['number']!);

      final newItem = MenuItem(
        id: dishId,
        name: result['name']!,
        description: result['description']!.isEmpty ? null : result['description'],
        itemNumber: number,
      );

      final updatedRestaurant = currentRestaurantForNum.copyWith(
        menu: [...currentRestaurantForNum.menu, newItem],
      );

      await ref.read(restaurantsProvider.notifier).updateRestaurant(updatedRestaurant);

      setState(() {
        _quantities[dishId] = 1;
      });

      final entries = _quantities.entries
          .where((e) => e.value > 0)
          .map((e) {
            final item = updatedRestaurant.menu.where((m) => m.id == e.key).firstOrNull;
            return SubOrderEntry(
              menuItemId: e.key,
              name: item?.name ?? e.key,
              quantity: e.value,
            );
          })
          .toList();

      await ref
          .read(personalOrderProvider('${widget.sessionId}:$userId').notifier)
          .saveOrder(
            sessionId: widget.sessionId,
            userId: userId,
            entries: entries,
            userName: userName,
            userFullName: userFullName,
            userProfilePicturePath: userProfilePicturePath,
          );

      ref.invalidate(subOrdersForSessionProvider(widget.sessionId));
      ref.invalidate(sessionDetailProvider(widget.sessionId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added "${newItem.name}" to order')),
        );
      }
    }
  }

  Future<void> _saveOrder(BuildContext context, String userId, List<MenuItem> menuItems,
      {bool silent = false, String? userName, String? userFullName, String? userProfilePicturePath}) async {
    final entries = _quantities.entries
        .where((e) => e.value > 0)
        .map((e) {
          final item = menuItems.where((m) => m.id == e.key).firstOrNull;
          return SubOrderEntry(
            menuItemId: e.key,
            name: item?.name ?? e.key,
            quantity: e.value,
          );
        })
        .toList();

    await ref
        .read(personalOrderProvider('${widget.sessionId}:$userId').notifier)
        .saveOrder(
          sessionId: widget.sessionId,
          userId: userId,
          entries: entries,
          userName: userName,
          userFullName: userFullName,
          userProfilePicturePath: userProfilePicturePath,
        );

    ref.invalidate(subOrdersForSessionProvider(widget.sessionId));
    ref.invalidate(sessionDetailProvider(widget.sessionId));

    if (!silent && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order saved with ${entries.length} items')),
      );
    }
  }

  Future<void> _saveAsTemplate(
      BuildContext context, WidgetRef ref, Restaurant restaurant, String suggestedName) async {
    if (_quantities.isEmpty) return;

    final nameController = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save as Template'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Template name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (label == null || label.isEmpty) return;

    final entries = _quantities.entries
        .where((e) => e.value > 0)
        .map((e) {
          final item = restaurant.menu.where((m) => m.id == e.key).firstOrNull;
          return SubOrderEntry(menuItemId: e.key, name: item?.name ?? e.key, quantity: 1);
        })
        .toList();

    await ref.read(savedOrderActionsProvider).saveTemplate(
          restaurantId: restaurant.id,
          label: label,
          entries: entries,
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Template "$label" saved')),
      );
    }
  }

  void _showUseTemplateSheet(
      BuildContext context,
      WidgetRef ref,
      List<SavedOrder> templates,
      Restaurant restaurant,
      String userId,
      String userName,
      String userFullName,
      String? userProfilePicturePath) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Text(
                  'Choose a Template',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Divider(),
              ...templates.map((t) => ListTile(
                    leading: const Icon(Icons.bookmarks_outlined),
                    title: Text(t.label),
                    subtitle: Text('${t.entries.length} items'),
                    onTap: () async {
                      Navigator.pop(context);
                      setState(() {
                        for (final entry in t.entries) {
                          _quantities[entry.menuItemId] =
                              (_quantities[entry.menuItemId] ?? 0) + 1;
                        }
                      });
                      await _saveOrder(context, userId, restaurant.menu,
                          userName: userName,
                          userFullName: userFullName,
                          userProfilePicturePath: userProfilePicturePath);
                    },
                  )),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Speed Dial ────────────────────────────────────────────────────────────────

class _SpeedDial extends StatefulWidget {
  final List<_DialItem> items;
  const _SpeedDial({required this.items});

  @override
  State<_SpeedDial> createState() => _SpeedDialState();
}

class _SpeedDialState extends State<_SpeedDial> with SingleTickerProviderStateMixin {
  bool _open = false;
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _ctrl.forward() : _ctrl.reverse();
  }

  void _close() {
    setState(() => _open = false);
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ...widget.items.map((item) => FadeTransition(
              opacity: _anim,
              child: SizeTransition(
                sizeFactor: _anim,
                axisAlignment: 1.0,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        elevation: 1,
                        color: scheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: Text(item.label,
                              style: Theme.of(context).textTheme.labelLarge),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton.small(
                        heroTag: 'dial_${item.label}',
                        onPressed: () {
                          _close();
                          item.onTap();
                        },
                        child: Icon(item.icon),
                      ),
                    ],
                  ),
                ),
              ),
            )),
        FloatingActionButton(
          heroTag: 'speed_dial_main',
          onPressed: _toggle,
          child: AnimatedRotation(
            turns: _open ? 0.125 : 0,
            duration: const Duration(milliseconds: 250),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _DialItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DialItem({required this.icon, required this.label, required this.onTap});
}

class _OrderedItem {
  final String id;
  final String name;
  final int quantity;
  final bool isYummie;

  _OrderedItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.isYummie,
  });
}
