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
import '../../ui/pages/session/session_page.dart';
import '../../ui/pages/session/personal_order_page.dart';
import '../../ui/pages/session/merged_order_page.dart';
import '../../ui/pages/session/checklist_page.dart';
import '../../ui/pages/restaurant/restaurant_detail_page.dart';
import '../../ui/pages/scan_menu/scan_menu_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
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
      ShellRoute(
        builder: (context, state, child) => SessionPage(
          sessionId: state.pathParameters['id']!,
          child: child,
        ),
        routes: [
          GoRoute(
            path: 'sessions/:id',
            redirect: (context, state) => '${state.path}/order',
          ),
          GoRoute(
            path: 'sessions/:id/order',
            pageBuilder: (context, state) => NoTransitionPage(
              child: PersonalOrderPage(
                sessionId: state.pathParameters['id']!,
              ),
            ),
          ),
          GoRoute(
            path: 'sessions/:id/merged',
            pageBuilder: (context, state) => NoTransitionPage(
              child: MergedOrderPage(
                sessionId: state.pathParameters['id']!,
              ),
            ),
          ),
          GoRoute(
            path: 'sessions/:id/checklist',
            pageBuilder: (context, state) => NoTransitionPage(
              child: ChecklistPage(
                sessionId: state.pathParameters['id']!,
              ),
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
