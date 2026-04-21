import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/pages/profile/profile_setup_page.dart';
import '../../ui/pages/home/home_page.dart';
import '../../ui/pages/home/sessions_page.dart';
import '../../ui/pages/home/restaurants_page.dart';
import '../../ui/pages/home/settings_page.dart';
import '../../ui/pages/sessions/new_session_page.dart';
import '../../ui/pages/sessions/join_session_page.dart';
import '../../ui/pages/session/session_shell_page.dart';
import '../../ui/pages/session/personal_order_page.dart';
import '../../ui/pages/session/merged_order_page.dart';
import '../../ui/pages/session/checklist_page.dart';
import '../../ui/pages/restaurant/restaurant_detail_page.dart';
import '../../ui/pages/scan_menu/scan_menu_page.dart';
import '../../ui/viewmodels/profile_viewmodel.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final userAsync = ref.watch(profileViewModelProvider);

  return GoRouter(
    initialLocation: '/home/sessions',
    redirect: (context, state) {
      final isOnProfileSetup = state.matchedLocation == '/profile/setup';

      return userAsync.when(
        data: (user) {
          if (user == null && !isOnProfileSetup) {
            return '/profile/setup';
          }
          if (user != null && isOnProfileSetup) {
            return '/home/sessions';
          }
          return null;
        },
        loading: () => null,
        error: (_, __) => '/profile/setup',
      );
    },
    routes: [
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
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SessionsPage(),
            ),
          ),
          GoRoute(
            path: '/home/restaurants',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: RestaurantsPage(),
            ),
          ),
          GoRoute(
            path: '/home/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsPage(),
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
        routes: [
          GoRoute(
            path: 'order',
            builder: (context, state) => PersonalOrderPage(
              sessionId: state.pathParameters['sessionId']!,
            ),
          ),
          GoRoute(
            path: 'merged',
            builder: (context, state) => MergedOrderPage(
              sessionId: state.pathParameters['sessionId']!,
            ),
          ),
          GoRoute(
            path: 'checklist',
            builder: (context, state) => ChecklistPage(
              sessionId: state.pathParameters['sessionId']!,
            ),
          ),
        ],
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
