import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../../core/style/app_style.dart';
import '../../../core/style/bottom_actions_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/widgets/glass_aware_scaffold.dart';

class HomePage extends ConsumerWidget {
  final Widget child;

  const HomePage({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home/sessions')) return 0;
    if (location.startsWith('/home/restaurants')) return 1;
    if (location.startsWith('/home/settings')) return 2;
    return 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home/sessions');
        break;
      case 1:
        context.go('/home/restaurants');
        break;
      case 2:
        context.go('/home/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final styleMode = ref.watch(styleModeProvider);
    final selectedIndex = _calculateSelectedIndex(context);
    final isGlass = styleMode == AppStyleMode.liquidGlass;
    final actions = ref.watch(bottomActionsProvider);

    if (isGlass) {
      final isLight = Theme.of(context).brightness == Brightness.light;
      final iconColor =
          isLight ? Colors.black87 : Colors.white;
      final unselectedColor =
          isLight ? Colors.black54 : Colors.white70;
      return GlassAwareScaffold(
        body: child,
        bottomNavigationBar: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              if (actions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < actions.length; i++) ...[
                        actions[i],
                        if (i < actions.length - 1) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              Expanded(
                child: GlassBottomBar(
                  glassSettings: LiquidGlassSettings(
                    thickness: 25,
                    blur: isLight ? 12 : 8,
                    glassColor: isLight ? const Color(0x18000000) : const Color(0x30FFFFFF),
                    refractiveIndex: 1.59,
                    saturation: 0.7,
                    ambientStrength: isLight ? 0.3 : 1,
                    lightIntensity: 0.6,
                    chromaticAberration: 0.3,
                  ),
                  selectedIconColor: iconColor,
                  unselectedIconColor: unselectedColor,
                  selectedIndex: selectedIndex,
                  onTabSelected: (index) => _onDestinationSelected(context, index),
                  tabs: [
                    GlassBottomBarTab(
                      icon: const Icon(Icons.groups_outlined),
                      activeIcon: const Icon(Icons.groups),
                      label: l10n.navTables,
                    ),
                    GlassBottomBarTab(
                      icon: const Icon(Icons.restaurant_outlined),
                      activeIcon: const Icon(Icons.restaurant),
                      label: l10n.navRestaurants,
                    ),
                    GlassBottomBarTab(
                      icon: const Icon(Icons.settings_outlined),
                      activeIcon: const Icon(Icons.settings),
                      label: l10n.navSettings,
                    ),
                  ],
                ),
              ),
            ],
          ),
      );
    }

    ref.read(bottomActionsProvider.notifier).clear();
    return GlassAwareScaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) =>
            _onDestinationSelected(context, index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.groups_outlined),
            selectedIcon: const Icon(Icons.groups),
            label: l10n.navTables,
          ),
          NavigationDestination(
            icon: const Icon(Icons.restaurant_outlined),
            selectedIcon: const Icon(Icons.restaurant),
            label: l10n.navRestaurants,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}
