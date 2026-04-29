import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/permission_service.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _hasCheckedBluetooth = false;
  bool _bluetoothEnabled = true;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkBluetooth() async {
    if (_hasCheckedBluetooth) return;
    _hasCheckedBluetooth = true;
    
    final hasPermissions = await PermissionService.checkBluetoothPermissions();
    final isEnabled = await PermissionService.isBluetoothEnabled();
    
    if (mounted) {
      setState(() {
        _bluetoothEnabled = hasPermissions && isEnabled;
      });
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      context.go('/profile/setup');
    }
  }

  void _nextPage() async {
    if (_currentPage == 1) {
      await _checkBluetooth();
      if (!_bluetoothEnabled && mounted) {
        _showBluetoothWarning();
        return;
      }
    }
    
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _showBluetoothWarning() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.bluetooth_disabled_rounded,
          size: 48,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(l10n.bluetoothWarningTitle),
        content: Text(l10n.bluetoothWarningMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              PermissionService.openSettings();
            },
            child: Text(l10n.bluetoothWarningOpenSettings),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _pageController.nextPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
              );
            },
            child: Text(l10n.bluetoothWarningContinueAnyway),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final pages = [
      _OnboardingPageData(
        icon: Icons.add_circle_outline_rounded,
        gradientColors: [colorScheme.primaryContainer, colorScheme.primary.withValues(alpha: 0.3)],
        title: l10n.onboardingCreateTitle,
        description: l10n.onboardingCreateDescription,
      ),
      _OnboardingPageData(
        icon: Icons.group_add_rounded,
        gradientColors: [colorScheme.secondaryContainer, colorScheme.secondary.withValues(alpha: 0.3)],
        title: l10n.onboardingJoinTitle,
        description: l10n.onboardingJoinDescription,
      ),
      _OnboardingPageData(
        icon: Icons.restaurant_rounded,
        gradientColors: [colorScheme.tertiaryContainer, colorScheme.tertiary.withValues(alpha: 0.3)],
        title: l10n.onboardingEnjoyTitle,
        description: l10n.onboardingEnjoyDescription,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: pages.length,
                itemBuilder: (context, index) => _OnboardingPageContent(data: pages[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentPage == index
                              ? colorScheme.primary
                              : colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _nextPage,
                    icon: Icon(_currentPage == 2 ? Icons.check_rounded : Icons.arrow_forward_rounded),
                    label: Text(_currentPage == 2 ? l10n.onboardingGetStarted : l10n.onboardingNext),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(200, 56),
                    ),
                  ),
                  if (_currentPage > 0) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(l10n.onboardingSkip),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final List<Color> gradientColors;
  final String title;
  final String description;

  _OnboardingPageData({
    required this.icon,
    required this.gradientColors,
    required this.title,
    required this.description,
  });
}

class _OnboardingPageContent extends StatelessWidget {
  final _OnboardingPageData data;

  const _OnboardingPageContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: size.width * 0.7,
            height: size.width * 0.7,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: data.gradientColors,
              ),
              boxShadow: [
                BoxShadow(
                  color: data.gradientColors[0].withValues(alpha: 0.4),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Icon(
              data.icon,
              size: size.width * 0.35,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            data.title,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            data.description,
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}