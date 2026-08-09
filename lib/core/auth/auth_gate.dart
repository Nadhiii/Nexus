import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../screens/main_screen.dart';
import '../../screens/login_screen.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/goal_provider.dart';
import '../providers/category_provider.dart';
import '../providers/debt_provider.dart';
import '../providers/investment_provider.dart';
import '../providers/bike_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/gmail_provider.dart';
import '../services/notification_service.dart';
import '../services/backup_service.dart';
import '../services/legacy_data_migration_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // User logged out - clear all provider data
        if (!snapshot.hasData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _clearAllProviders(context);
          });
          return const LoginScreen();
        }

        // User logged in - initialize providers
        return const AuthenticatedApp();
      },
    );
  }

  void _clearAllProviders(BuildContext context) {
    try {
      Provider.of<AccountProvider>(context, listen: false).clear();
      Provider.of<TransactionProvider>(context, listen: false).clear();
      Provider.of<SubscriptionProvider>(context, listen: false).reset();
      Provider.of<BudgetProvider>(context, listen: false).reset();
      Provider.of<GoalProvider>(context, listen: false).clear();
      Provider.of<DebtProvider>(context, listen: false).clear();
      Provider.of<InvestmentProvider>(context, listen: false).clear();
      Provider.of<BikeProvider>(context, listen: false).clear();
      debugPrint('✅ All providers cleared on logout');
    } catch (e) {
      debugPrint('⚠️ Error clearing providers: $e');
    }
  }
}

class AuthenticatedApp extends StatefulWidget {
  const AuthenticatedApp({super.key});

  @override
  State<AuthenticatedApp> createState() => _AuthenticatedAppState();
}

class _AuthenticatedAppState extends State<AuthenticatedApp> {
  bool _ranAutoBackupRestore = false;
  bool _initializedNotifications = false;
  bool _ranLegacyMigration = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders(context);
    });
  }

  Future<void> _initializeProviders(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    if (!_ranLegacyMigration) {
      _ranLegacyMigration = true;
      await LegacyDataMigrationService().migrateIfNeeded();
    }

    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );
    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );
    final subscriptionProvider = Provider.of<SubscriptionProvider>(
      context,
      listen: false,
    );
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final goalProvider = Provider.of<GoalProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );
    final bikeProvider = Provider.of<BikeProvider>(context, listen: false);
    final gmailProvider = Provider.of<GmailProvider>(context, listen: false);

    // Initialize all standard providers synchronously
    accountProvider.initialize();
    transactionProvider.initialize();
    subscriptionProvider.initialize();
    budgetProvider.initialize();
    goalProvider.loadGoals(user.uid);
    categoryProvider.refresh();
    bikeProvider.fetchBikes();

    if (!_initializedNotifications) {
      _initializedNotifications = true;
      await NotificationService().initialize(notificationProvider);
    }

    // FIX: STRICT SEQUENCING for Google Play Services
    // Step 1: Execute Backup API calls
    if (!_ranAutoBackupRestore) {
      _ranAutoBackupRestore = true;
      await _maybeAutoBackupAndRestore();
    }

    // Step 2: ONLY once Backup is complete, initialize Gmail API calls.
    // This prevents the Google Play Services broker from crashing the Android Binder.
    await gmailProvider.initialize();
  }

  Future<void> _maybeAutoBackupAndRestore() async {
    if (!mounted) return;

    final service = BackupService();
    try {
      // Auto-restore first (if user has no data)
      final restored = await service.performAutoRestoreIfNeeded();

      // If data was restored, reload all providers to refresh their caches
      if (restored && mounted) {
        debugPrint('[Backup] Data restored, refreshing providers...');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initializeProviders(context);
        });
        return;
      }

      // Then auto-backup (creates single auto-backup, replaces old one)
      await service.performAutoBackupIfNeeded();
    } catch (e) {
      debugPrint('Auto backup/restore error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const MainScreen();
  }
}
