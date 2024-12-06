import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../screens/splash_screen.dart';
import '../screens/home_screen.dart';
import '../screens/puzzle_catalog_screen.dart';
import '../screens/puzzle_screen.dart';
import '../screens/achievements_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/statistics_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return AppRouter.router;
});

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      // Splash screen
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Home route
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),

      // Puzzle route
      GoRoute(
        path: '/puzzle/:id',
        builder: (context, state) {
          final puzzleId = state.pathParameters['id']!;
          return PuzzleScreen(puzzleId: puzzleId);
        },
      ),

      // Puzzle catalog route
      GoRoute(
        path: '/catalog',
        builder: (context, state) => const PuzzleCatalogScreen(),
        routes: [
          GoRoute(
            path: 'category/:categoryId',
            builder: (context, state) {
              final categoryId = state.pathParameters['categoryId']!;
              return PuzzleCatalogScreen(categoryId: categoryId);
            },
          ),
        ],
      ),

      // Achievements route
      GoRoute(
        path: '/achievements',
        builder: (context, state) => const AchievementsScreen(),
      ),
      //
      // // Statistics route
      GoRoute(
        path: '/statistics',
        builder: (context, state) => const StatisticsScreen(),
      ),
      //
      // // Settings route
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => ErrorScreen(error: state.error),

    // Redirect logic
    redirect: (BuildContext context, GoRouterState state) {
      // Add any authentication or initialization checks here
      return null;
    },
  );
}

// Bottom navigation bar scaffold
class ScaffoldWithBottomNavBar extends ConsumerStatefulWidget {
  final Widget child;

  const ScaffoldWithBottomNavBar({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<ScaffoldWithBottomNavBar> createState() =>
      _ScaffoldWithBottomNavBarState();
}

class _ScaffoldWithBottomNavBarState
    extends ConsumerState<ScaffoldWithBottomNavBar> {
  int _getCurrentIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/catalog')) return 1;
    if (location.startsWith('/achievements')) return 2;
    if (location.startsWith('/statistics')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _getCurrentIndex(location);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: DefaultTextStyle(
        style: const TextStyle(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        child: NavigationBar(
          indicatorColor: Theme.of(context).primaryColor,
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                context.go('/home');
                break;
              case 1:
                context.go('/catalog');
                break;
              case 2:
                context.go('/achievements');
                break;
              case 3:
                context.go('/statistics');
                break;
              case 4:
                context.go('/settings');
                break;
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: Colors.white),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view, color: Colors.white),
              label: 'Puzzles',
            ),
            DefaultTextStyle(
              style: TextStyle(fontSize: 9),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              child: NavigationDestination(
                icon: Icon(Icons.emoji_events_outlined),
                selectedIcon: Icon(Icons.emoji_events, color: Colors.white),
                label: 'Achievements',
              ),
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart, color: Colors.white),
              label: 'Statistics',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings, color: Colors.white),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

// Error screen
class ErrorScreen extends StatelessWidget {
  final Exception? error;

  const ErrorScreen({
    Key? key,
    this.error,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
