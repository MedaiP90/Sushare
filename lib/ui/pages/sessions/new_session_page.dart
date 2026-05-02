import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/widgets/glass_aware_app_bar.dart';
import '../../core/widgets/glass_aware_scaffold.dart';
import '../../viewmodels/session_viewmodel.dart';
import '../../viewmodels/restaurant_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';

class NewSessionPage extends ConsumerStatefulWidget {
  const NewSessionPage({super.key});

  @override
  ConsumerState<NewSessionPage> createState() => _NewSessionPageState();
}

class _NewSessionPageState extends ConsumerState<NewSessionPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedRestaurantId;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createSession() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(profileViewModelProvider).value;
      if (user == null) throw Exception('No user logged in');

      final restaurantId = _selectedRestaurantId ?? await _autoCreateRestaurant();

      final sessionId = await ref.read(sessionsProvider.notifier).createSession(
            name: _nameController.text.trim(),
            restaurantId: restaurantId,
            hostUserId: user.id,
            hostUserName: user.username,
            hostFullName: '${user.firstName} ${user.lastName}'.trim(),
            hostAvatarIconName: user.avatarIconName,
            hostAvatarColorValue: user.avatarColorValue,
          );

      if (mounted) {
        context.go('/sessions/$sessionId');
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.newTableError(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String> _autoCreateRestaurant() {
    final now = DateTime.now();
    final name =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return ref.read(restaurantsProvider.notifier).addRestaurant(name: name, menu: []);
  }

  @override
  Widget build(BuildContext context) {
    final restaurantsAsync = ref.watch(restaurantsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return GlassAwareScaffold(
      appBar: GlassAwareAppBar(
        title: Text(l10n.newTableTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.newTableHeading, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                l10n.newTableSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.newTableNameLabel,
                  hintText: l10n.newTableNameHint,
                  prefixIcon: const Icon(Icons.groups),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.newTableNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(l10n.newTableSelectRestaurant, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              restaurantsAsync.when(
                data: (restaurants) {
                  if (restaurants.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(Icons.restaurant_outlined, size: 48),
                            const SizedBox(height: 8),
                            Text(l10n.newTableNoRestaurants),
                            const SizedBox(height: 4),
                            Text(
                              l10n.newTableNoRestaurantsSubtitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => context.go('/home/restaurants'),
                              child: Text(l10n.newTableAddRestaurant),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: restaurants.map((restaurant) {
                      final isSelected = _selectedRestaurantId == restaurant.id;
                      return Card(
                        color: isSelected ? colorScheme.primaryContainer : null,
                        child: ListTile(
                          leading: Icon(
                            isSelected ? Icons.check_circle : Icons.restaurant,
                            color: isSelected ? colorScheme.primary : null,
                          ),
                          title: Text(restaurant.name),
                          subtitle: restaurant.address != null ? Text(restaurant.address!) : null,
                          trailing: Text(
                            l10n.newTableMenuItems(restaurant.menu.length),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          onTap: () => setState(() => _selectedRestaurantId = restaurant.id),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(l10n.errorMessage(error.toString()))),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isLoading ? null : _createSession,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : Text(l10n.newTableStart),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
