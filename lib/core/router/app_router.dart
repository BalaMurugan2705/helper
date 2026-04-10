import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/shell/main_shell.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/cleaning/cleaning_screen.dart';
import '../../screens/shopping/shopping_screen.dart';
import '../../screens/budget/budget_screen.dart';
import '../../screens/health/health_screen.dart';
import '../../screens/advisor/advisor_screen.dart';
import '../../screens/expenses/expense_screen.dart';
import '../../screens/food/food_tracker_screen.dart';
import '../../screens/settings/notification_settings_screen.dart';
import '../../screens/wishlist/wishlist_screen.dart';

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable:
      _GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final onLogin = state.matchedLocation == '/login';
    if (user == null && !onLogin) return '/login';
    if (user != null && onLogin) return '/';

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: LoginScreen(),
      ),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return MainShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/cleaning',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CleaningScreen(),
          ),
        ),
        GoRoute(
          path: '/shopping',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ShoppingScreen(),
          ),
        ),
        GoRoute(
          path: '/budget',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: BudgetScreen(),
          ),
        ),
        GoRoute(
          path: '/expenses',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ExpenseScreen(),
          ),
        ),
        GoRoute(
          path: '/health',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HealthScreen(),
          ),
        ),
        GoRoute(
          path: '/food',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: FoodTrackerScreen(),
          ),
        ),
        GoRoute(
          path: '/wishlist',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: WishlistScreen(),
          ),
        ),
        GoRoute(
          path: '/advisor',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AdvisorScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const MaterialPage(
            child: NotificationSettingsScreen(),
          ),
        ),
      ],
    ),
  ],
);
