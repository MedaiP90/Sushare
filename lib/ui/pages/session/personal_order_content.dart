import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/models/restaurant.dart';
import '../../../domain/models/personal_sub_order.dart';
import '../../../domain/models/saved_order.dart';
import '../../../domain/models/session.dart';
import '../../../l10n/app_localizations.dart';
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sessionAsync = ref.watch(sessionDetailProvider(widget.sessionId));
    final user = ref.watch(profileViewModelProvider).value;

    if (user == null) {
      return Center(child: Text(l10n.personalOrderLogin));
    }

    return sessionAsync.when(
      data: (session) {
        if (session == null) {
          return Center(child: Text(l10n.sessionTableNotFound));
        }

        final restaurantAsync = ref.watch(restaurantDetailProvider(session.restaurantId));
        final personalOrderKey = '${widget.sessionId}:${user.id}';
        final personalOrderAsync = ref.watch(personalOrderProvider(personalOrderKey));
        final templatesAsync = ref.watch(savedOrdersForRestaurantProvider(session.restaurantId));

        return restaurantAsync.when(
          data: (restaurant) {
            if (restaurant == null) {
              return Center(child: Text(l10n.personalOrderRestaurantNotFound));
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
            final canAddDishes = session.status == SessionStatus.open;
            final isSent = session.status == SessionStatus.sent;
            final templates = templatesAsync.valueOrNull ?? [];

            final String userName = user.username;
            final String userFullName = '${user.firstName} ${user.lastName}'.trim();
            final String? userProfilePicturePath = user.profilePicturePath;

            return Scaffold(
              body: Column(
                children: [
                  if (isSent)
                    MaterialBanner(
                      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                      content: Text(l10n.personalOrderSentBanner),
                      leading: Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      actions: [const SizedBox.shrink()],
                    ),
                  Expanded(
                    child: orderedItems.isEmpty
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
                                  l10n.personalOrderEmpty,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.personalOrderEmptyHint,
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
                        Row(
                          children: [
                            Text(
                              l10n.personalOrderTitle(totalItems),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Spacer(),
                            if (_quantities.isNotEmpty)
                              TextButton.icon(
                                onPressed: () => _saveAsTemplate(
                                    context, ref, restaurant, userName),
                                icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                                label: Text(l10n.personalOrderSaveButton),
                              ),
                          ],
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
                                      const Icon(Icons.restaurant, size: 14),
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
                  ),
                ],
              ),
              floatingActionButton: isEditable
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (templates.isNotEmpty)
                          FloatingActionButton(
                            heroTag: 'fab_use_template',
                            onPressed: canAddDishes
                                ? () => _showUseTemplateSheet(
                                    context, ref, templates, restaurant, user.id,
                                    userName, userFullName, userProfilePicturePath)
                                : null,
                            tooltip: l10n.personalOrderUseTemplate,
                            child: const Icon(Icons.bookmarks_outlined),
                          ),
                        const SizedBox(width: 12),
                        FloatingActionButton(
                          heroTag: 'fab_menu',
                          onPressed: canAddDishes
                              ? () => _showAddFromMenuSheet(
                                  context, restaurant, user.id, userName,
                                  userFullName, userProfilePicturePath)
                              : null,
                          tooltip: l10n.personalOrderFromMenu,
                          child: const Icon(Icons.restaurant_menu),
                        ),
                        const SizedBox(width: 12),
                        FloatingActionButton.extended(
                          heroTag: 'fab_custom_dish',
                          onPressed: canAddDishes
                              ? () => _showAddCustomDishSheet(
                                  context, restaurant, user.id, userName,
                                  userFullName, userProfilePicturePath)
                              : null,
                          tooltip: l10n.personalOrderCustomDish,
                          icon: const Icon(Icons.add),
                          label: Text(l10n.personalOrderCustomDish),
                        ),
                      ],
                    )
                  : null,
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(l10n.errorMessage(error.toString()))),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(AppLocalizations.of(context)!.errorMessage(error.toString()))),
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
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final l10n = AppLocalizations.of(sheetContext)!;
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (sheetContext, scrollController) {
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
                          l10n.personalOrderAddFromMenu,
                          style: Theme.of(sheetContext).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
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
                      itemBuilder: (sheetContext, index) {
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
                                Theme.of(sheetContext).colorScheme.primaryContainer,
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
                                Navigator.pop(sheetContext);
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
                          child: Text(l10n.personalOrderAddItemsButton(selectedIds.length)),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
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
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext)!;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
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
                    l10n.personalOrderAddCustomDishTitle,
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.personalOrderCustomDishName,
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: l10n.personalOrderCustomDishDesc,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: numberController,
                decoration: InputDecoration(
                  labelText: l10n.personalOrderCustomDishNumber,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;
                  Navigator.pop(sheetContext, {
                    'name': nameController.text.trim(),
                    'description': descController.text.trim(),
                    'number': numberController.text.trim(),
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.add),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );

    if (result != null && mounted) {
      final l10n = AppLocalizations.of(context)!;
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
          SnackBar(content: Text(l10n.personalOrderCustomDishAdded(newItem.name))),
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
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.personalOrderSaved(entries.length))),
      );
    }
  }

  Future<void> _saveAsTemplate(
      BuildContext context, WidgetRef ref, Restaurant restaurant, String suggestedName) async {
    if (_quantities.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.personalOrderSaveAsTemplate),
        content: TextField(
          controller: nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.personalOrderTemplateNameLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
            child: Text(l10n.save),
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
        SnackBar(content: Text(l10n.personalOrderTemplateSaved(label))),
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
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollController) {
          final l10n = AppLocalizations.of(ctx)!;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  children: [
                    Text(
                      l10n.personalOrderChooseTemplate,
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: templates.length,
                  itemBuilder: (ctx, index) {
                    final t = templates[index];
                    return _ExpandableTemplateTile(
                      template: t,
                      restaurant: restaurant,
                      onApply: () async {
                        Navigator.pop(sheetContext);
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
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ExpandableTemplateTile extends StatefulWidget {
  final SavedOrder template;
  final Restaurant restaurant;
  final VoidCallback onApply;

  const _ExpandableTemplateTile({
    required this.template,
    required this.restaurant,
    required this.onApply,
  });

  @override
  State<_ExpandableTemplateTile> createState() => _ExpandableTemplateTileState();
}

class _ExpandableTemplateTileState extends State<_ExpandableTemplateTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.bookmarks_outlined),
          title: Text(widget.template.label),
          subtitle: Text(l10n.checklistItemsCount(widget.template.entries.length)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                onPressed: () => setState(() => _expanded = !_expanded),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: widget.onApply,
              ),
            ],
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: widget.template.entries
                  .map((entry) {
                    final menuItem = widget.restaurant.menu
                        .where((m) => m.id == entry.menuItemId)
                        .firstOrNull;
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.only(left: 48),
                      title: Text(entry.name),
                      trailing: Text(
                        '#${menuItem?.itemNumber ?? '-'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
        const Divider(height: 1),
      ],
    );
  }
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
