import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
import '../providers/knowledge_provider.dart';
import '../providers/transaction_relationship_provider.dart';
import '../providers/nbox_provider.dart';
import '../providers/debt_provider.dart';
import '../providers/investment_provider.dart';
import '../providers/bike_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/biometric_provider.dart';
import 'biometric_auth_wrapper.dart';
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
        return Provider<KnowledgeProvider>(
          create: (_) => KnowledgeProvider(userId: snapshot.data!.uid),
          child: const AuthenticatedApp(),
        );
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
      Provider.of<CategoryProvider>(context, listen: false).clear();
      Provider.of<KnowledgeProvider>(context, listen: false).clear();
      Provider.of<TransactionRelationshipProvider>(
        context,
        listen: false,
      ).clear();
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
  bool _biometricInitializationComplete = false;
  bool _deferredInitializationScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuthenticatedApp(context);
    });
  }

  Future<void> _initializeAuthenticatedApp(BuildContext context) async {
    final biometricProvider = Provider.of<BiometricProvider>(
      context,
      listen: false,
    );
    await biometricProvider.initialize();

    if (!mounted) return;
    await _initializeCriticalProviders(context);

    if (!mounted) return;
    setState(() {
      _biometricInitializationComplete = true;
    });

    if (!mounted || _deferredInitializationScheduled) return;
    _deferredInitializationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeDeferredProviders(context);
      }
    });
  }

  Future<void> _initializeCriticalProviders(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
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
    final bikeProvider = Provider.of<BikeProvider>(context, listen: false);

    // Dashboard dependencies: wait for account and transaction data before
    // exposing the authenticated shell. Subscription and bike providers use
    // stream-backed initialization APIs and begin loading here.
    await Future.wait([
      accountProvider.initialize(),
      transactionProvider.initialize(),
    ]);
    subscriptionProvider.initialize();
    bikeProvider.fetchBikes();
  }

  Future<void> _initializeDeferredProviders(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

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
    final knowledgeProvider = Provider.of<KnowledgeProvider>(
      context,
      listen: false,
    );
    final relationshipProvider = Provider.of<TransactionRelationshipProvider>(
      context,
      listen: false,
    );
    final nboxProvider = Provider.of<NewNboxProvider>(context, listen: false);
    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );
    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );
    nboxProvider.setFinancialDependencies(
      accountProvider: accountProvider,
      transactionProvider: transactionProvider,
      knowledgeProvider: knowledgeProvider,
    );

    if (!_ranLegacyMigration) {
      _ranLegacyMigration = true;
      try {
        await LegacyDataMigrationService().migrateIfNeeded();
      } catch (e) {
        debugPrint('Legacy data migration error: $e');
      }
    }

    try {
      budgetProvider.initialize();
    } catch (e) {
      debugPrint('Budget initialization error: $e');
    }

    try {
      await goalProvider.loadGoals(user.uid);
    } catch (e) {
      debugPrint('Goal initialization error: $e');
    }

    try {
      await categoryProvider.refresh();
    } catch (e) {
      debugPrint('Category initialization error: $e');
    }

    try {
      await knowledgeProvider.refresh();
      await relationshipProvider.refresh();
    } catch (e) {
      debugPrint('Knowledge initialization error: $e');
    }

    if (!_initializedNotifications) {
      _initializedNotifications = true;
      try {
        await NotificationService().initialize(notificationProvider);
      } catch (e) {
        debugPrint('Notification initialization error: $e');
      }
    }

    // FIX: STRICT SEQUENCING for Google Play Services
    // Step 1: Execute Backup API calls
    if (!_ranAutoBackupRestore) {
      _ranAutoBackupRestore = true;
      if (kDebugMode) {
        debugPrint('[Backup] Skipped automatic backup/restore in debug.');
      } else {
        await _maybeAutoBackupAndRestore();
      }
    }
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
    if (!_biometricInitializationComplete) {
      return const Center(child: CircularProgressIndicator());
    }

    return const BiometricAuthWrapper(child: MainScreen());
  }
}
