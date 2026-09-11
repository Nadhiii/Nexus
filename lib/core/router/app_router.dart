import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Screens - only import screens that exist and work standalone
import '../../modules/more/reports_and_analytics_screen.dart';
import '../../modules/more/export_reports_screen.dart';
import '../../modules/notifications/notifications_screen.dart';
import '../../modules/goals/goals_screen.dart';
import '../../modules/subscriptions/subscription_screen.dart';
import '../../modules/bike/screens/garage_screen.dart';
import '../../modules/bike/ui/bike_screen.dart';
import '../../modules/family/screens/family_dashboard_screen.dart';
import '../../modules/debts/screens/liabilities_screen.dart';

/// Route names for type-safe navigation
///
/// This router is designed for gradual migration. The main app still uses
/// the existing navigation system with callbacks. This router handles
/// standalone screens that can be pushed on top.
class AppRoutes {
  // Main shell routes (handled by existing system)
  static const String home = '/';
  static const String dashboard = '/dashboard';
  static const String finance = '/finance';
  static const String budgets = '/budgets';
  static const String more = '/more';

  // Standalone screens (can be navigated to via go_router)
  static const String reports = '/reports';
  static const String exportReports = '/export-reports';
  static const String notifications = '/notifications';
  static const String goals = '/goals';
  static const String subscriptions = '/subscriptions';
  static const String bike = '/bike';
  static const String garage = '/garage';
  static const String family = '/family';
  static const String debts = '/debts';
}

/// App Router configuration for standalone screens
///
/// NOTE: This router is designed for gradual migration from the existing
/// navigation system. It provides type-safe navigation for screens that
/// don't depend on the main app's callback-based navigation.
class AppRouter {
  static final _navigatorKey = GlobalKey<NavigatorState>();

  /// Get the navigator key for integration with MaterialApp
  static GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  /// Routes that can be used independently
  static final GoRouter standaloneRouter = GoRouter(
    navigatorKey: _navigatorKey,
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: false,
    routes: [
      // Placeholder for home - actual home is handled by existing system
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Use existing navigation'),
      ),

      // Reports & Analytics
      GoRoute(
        path: AppRoutes.reports,
        name: 'reports',
        builder: (context, state) => const ReportsAndAnalyticsScreen(),
      ),

      // Export Reports
      GoRoute(
        path: AppRoutes.exportReports,
        name: 'exportReports',
        builder: (context, state) => const ExportReportsScreen(),
      ),

      // Notifications
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        builder: (context, state) => const ModernNotificationsScreen(),
      ),

      // Goals
      GoRoute(
        path: AppRoutes.goals,
        name: 'goals',
        builder: (context, state) => const ModernGoalsScreen(),
      ),

      // Subscriptions
      GoRoute(
        path: AppRoutes.subscriptions,
        name: 'subscriptions',
        builder: (context, state) => const ModernSubscriptionScreen(),
      ),

      // Garage Management
      GoRoute(
        path: AppRoutes.garage,
        name: 'garage',
        builder: (context, state) => const ModernBikeScreen(),
      ),

      // Family Dashboard
      GoRoute(
        path: AppRoutes.family,
        name: 'family',
        builder: (context, state) => const FamilyDashboardScreen(),
      ),

      // Debts / Liabilities
      GoRoute(
        path: AppRoutes.debts,
        name: 'debts',
        builder: (context, state) => const LiabilitiesScreen(),
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => _ErrorScreen(path: state.uri.path),
  );
}

/// Extension for type-safe navigation using go_router
///
/// Usage: context.goToReports() or context.goToExportReports()
extension GoRouterNavigation on BuildContext {
  void goToReports() => push(AppRoutes.reports);
  void goToExportReports() => push(AppRoutes.exportReports);
  void goToNotifications() => push(AppRoutes.notifications);
  void goToGoals() => push(AppRoutes.goals);
  void goToSubscriptions() => push(AppRoutes.subscriptions);
  void goToGarage() => push(AppRoutes.garage);
  void goToFamily() => push(AppRoutes.family);
  void goToDebts() => push(AppRoutes.debts);
}

/// Placeholder screen for routes handled by existing navigation
class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 64),
            const SizedBox(height: 16),
            Text(title),
            const SizedBox(height: 8),
            const Text(
              'This route is handled by the existing navigation system.',
            ),
          ],
        ),
      ),
    );
  }
}

/// Error screen for unknown routes
class _ErrorScreen extends StatelessWidget {
  final String path;

  const _ErrorScreen({required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: $path'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
