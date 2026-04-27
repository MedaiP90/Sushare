import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../ui/pages/onboarding/onboarding_page.dart';
import '../../ui/pages/profile/profile_setup_page.dart';
import '../../ui/pages/home/home_page.dart';
import '../../ui/pages/home/sessions_page.dart';
import '../../ui/pages/home/restaurants_page.dart';
import '../../ui/pages/home/settings_page.dart';
import '../../ui/pages/sessions/new_session_page.dart';
import '../../ui/pages/sessions/join_session_page.dart';
import '../../ui/pages/session/session_shell_page.dart';
import '../../ui/pages/restaurant/restaurant_detail_page.dart';
import '../../ui/pages/scan_menu/scan_menu_page.dart';
import '../../ui/viewmodels/profile_viewmodel.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final userAsync = ref.watch(profileViewModelProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final location = state.matchedLocation;
      final isOnRoot = location == '/';
      final isOnOnboarding = location == '/onboarding';
      final isOnProfileSetup = location == '/profile/setup';

      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

      if (!onboardingCompleted && !isOnOnboarding) {
        return '/onboarding';
      }

      if (onboardingCompleted && isOnOnboarding) {
        return '/profile/setup';
      }

      if (isOnOnboarding) {
        return null;
      }

      return userAsync.when(
        data: (user) {
          if (isOnRoot || (!onboardingCompleted && !isOnOnboarding)) {
            if (!onboardingCompleted) return '/onboarding';
            if (user == null) return '/profile/setup';
            return '/home/sessions';
          }
          if (user == null && !isOnProfileSetup) {
            return '/profile/setup';
          }
          if (user != null && isOnProfileSetup) {
            return '/home/sessions';
          }
          if (user == null && isOnProfileSetup) {
            return null;
          }
          return null;
        },
        loading: () => null,
        error: (_, __) => '/profile/setup',
      );
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/profile/setup',
        builder: (context, state) => const ProfileSetupPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomePage(child: child),
        routes: [
          GoRoute(
            path: '/home',
            redirect: (context, state) => '/home/sessions',
          ),
          GoRoute(
            path: '/home/sessions',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const SessionsPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          ),
          GoRoute(
            path: '/home/restaurants',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const RestaurantsPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          ),
          GoRoute(
            path: '/home/settings',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const SettingsPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/restaurants/:id',
        builder: (context, state) => RestaurantDetailPage(
          restaurantId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/sessions/new',
        builder: (context, state) => const NewSessionPage(),
      ),
      GoRoute(
        path: '/sessions/join',
        builder: (context, state) => const JoinSessionPage(),
      ),
      GoRoute(
        path: '/sessions/:sessionId',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          return SessionShellPage(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/scan-menu/:restaurantId',
        builder: (context, state) => ScanMenuPage(
          restaurantId: state.pathParameters['restaurantId']!,
        ),
      ),
    ],
  );
});
