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
import '../services/notification_service.dart';
import '../services/backup_service.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders(context);
    });
  }

  Future<void> _initializeProviders(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

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

    // Initialize all providers
    accountProvider.initialize();
    transactionProvider.initialize();
    subscriptionProvider.initialize();
    budgetProvider.initialize();
    goalProvider.loadGoals(user.uid);
    categoryProvider.refresh(); // Refresh categories after authentication

    if (!_initializedNotifications) {
      _initializedNotifications = true;
      await NotificationService().initialize(notificationProvider);
    }

    if (!_ranAutoBackupRestore) {
      _ranAutoBackupRestore = true;
      _maybeAutoBackupAndRestore();
    }
  }

  Future<void> _maybeAutoBackupAndRestore() async {
    final service = BackupService();
    try {
      final autoBackup = await service.getAutoBackupEnabled();
      final autoRestore = await service.getAutoRestoreEnabled();

      // Auto-backup if last backup older than 24h
      if (autoBackup) {
        final latest = await service.latestBackup();
        final lastBackupAt =
            latest?.createdAt ?? await service.getLastBackupAt();
        final now = DateTime.now();
        final needsBackup =
            lastBackupAt == null || now.difference(lastBackupAt).inHours >= 24;
        if (needsBackup) {
          await service.createBackup();
        }
      }

      // Auto-restore if user has zero data and a backup exists
      if (autoRestore) {
        final hasData = await service.hasAnyUserData();
        if (!hasData) {
          final latest = await service.latestBackup();
          if (latest != null) {
            await service.restoreBackup(latest.id, replace: false);
          }
        }
      }
    } catch (e) {
      debugPrint('Auto backup/restore skipped: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const MainScreen();
  }
}
