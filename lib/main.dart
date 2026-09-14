import 'dart:async';
import 'core/services/ota_update_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/account_provider.dart';
import 'core/providers/transaction_provider.dart';
import 'core/providers/nbox_provider.dart';
import 'core/providers/debt_provider.dart';
import 'core/providers/investment_provider.dart';
import 'core/providers/biometric_provider.dart';
import 'core/providers/notification_provider.dart';
import 'core/providers/subscription_provider.dart';
import 'core/providers/budget_provider.dart';
import 'core/providers/user_provider.dart';
import 'core/providers/gmail_provider.dart';
import 'core/providers/goal_provider.dart';
import 'core/providers/category_provider.dart';
import 'core/providers/knowledge_provider.dart';
import 'core/providers/transaction_relationship_provider.dart';
import 'core/providers/bike_provider.dart';
import 'core/providers/vehicle_management_provider.dart';
import 'core/providers/fuel_price_provider.dart';
import 'core/providers/shared_expense_provider.dart';
import 'core/providers/family_debt_provider.dart';
import 'core/auth/auth_gate.dart';
import 'core/services/crash_reporting_service.dart';
import 'core/services/widget_sync_service.dart';
import 'core/services/intent_navigation_service.dart';
import 'package:another_telephony/telephony.dart' hide NetworkType;
import 'core/services/nbox_background_service.dart';

// ---------------------------------------------------------------------
// Background OTA check (workmanager)
// ---------------------------------------------------------------------

const String otaBackgroundTaskName = 'nexus-ota-check';

/// Reads the running app's version as "<version>+<buildNumber>", matching
/// the format used by the GitHub release tags (e.g. v1.2.0+5).
Future<String> _currentAppVersionString() async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version}+${info.buildNumber}';
}

/// Entry point for background work. Must stay top-level (not a class
/// method) since workmanager runs it in a separate background isolate
/// with no access to the running app's state.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final otaService = OTAUpdateService();
      await otaService.initNotifications();

      final currentVersion = await _currentAppVersionString();
      await otaService.checkAndNotifyOnStartup(currentVersion);
    } catch (e) {
      debugPrint('OTA: Background check failed — $e');
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register this before the widget tree starts. The top-level background
  // handler is retained by another_telephony for SMS_RECEIVED broadcasts when
  // Android has to start a fresh Flutter isolate.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    Telephony.instance.listenIncomingSms(
      onNewMessage: nboxForegroundSmsHandler,
      onBackgroundMessage: nboxBackgroundSmsHandler,
    );
  }

  // Only Firebase is truly required before runApp
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Crashlytics for error reporting
  await CrashReportingService().initialize();
  IntentNavigationService.initialize();

  // Register periodic background OTA check (Android only — workmanager's
  // iOS support is opportunistic/unreliable for polling use cases).
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await Workmanager().initialize(
      callbackDispatcher,
    );
    await Workmanager().registerPeriodicTask(
      otaBackgroundTaskName,
      otaBackgroundTaskName,
      frequency: const Duration(hours: 6),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  runApp(const NexusApp());
}

class NexusApp extends StatelessWidget {
  const NexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => DebtProvider()),
        ChangeNotifierProvider(create: (_) => InvestmentProvider()),
        ChangeNotifierProvider(create: (_) => BiometricProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => GoalProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => KnowledgeProvider()),
        ChangeNotifierProvider(
          create: (_) => TransactionRelationshipProvider(),
        ),
        ChangeNotifierProvider(create: (_) => BikeProvider()),
        ChangeNotifierProvider(create: (_) => VehicleManagementProvider()),
        ChangeNotifierProvider(create: (_) => FuelPriceProvider()),
        ChangeNotifierProvider(create: (_) => SharedExpenseProvider()),
        ChangeNotifierProvider(create: (_) => FamilyDebtProvider()),
        ChangeNotifierProxyProvider<CategoryProvider, GmailProvider>(
          create: (context) => GmailProvider(),
          update: (context, categoryProvider, gmailProvider) {
            return gmailProvider ?? GmailProvider();
          },
        ),
        ChangeNotifierProxyProvider2<
          GmailProvider,
          CategoryProvider,
          NewNboxProvider
        >(
          create: (context) =>
              NewNboxProvider(gmailProvider: context.read<GmailProvider>()),
          update: (context, gmailProvider, categoryProvider, nboxProvider) {
            nboxProvider!.update(gmailProvider);
            return nboxProvider;
          },
        ),
        ChangeNotifierProxyProvider<NotificationProvider, SubscriptionProvider>(
          create: (context) => SubscriptionProvider(),
          update: (context, notificationProvider, subscriptionProvider) {
            subscriptionProvider?.update(notificationProvider);
            return subscriptionProvider!;
          },
        ),
        ChangeNotifierProxyProvider<NotificationProvider, BudgetProvider>(
          create: (context) => BudgetProvider(),
          update: (context, notificationProvider, budgetProvider) {
            budgetProvider?.update(notificationProvider);
            return budgetProvider!;
          },
        ),
        ChangeNotifierProxyProvider3<
          AccountProvider,
          BudgetProvider,
          NotificationProvider,
          TransactionProvider
        >(
          create: (context) => TransactionProvider(),
          update:
              (
                context,
                accountProvider,
                budgetProvider,
                notificationProvider,
                transactionProvider,
              ) {
                transactionProvider?.update(
                  accountProvider,
                  budgetProvider,
                  notificationProvider,
                );
                return transactionProvider!;
              },
        ),
      ],
      child: _AppInitializer(
        child: MaterialApp(
          title: 'Nexus',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const AuthGate(),
        ),
      ),
    );
  }
}

class _AppInitializer extends StatefulWidget {
  final Widget child;
  const _AppInitializer({required this.child});

  @override
  State<_AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<_AppInitializer> {
  bool _initialized = false;
  final OTAUpdateService _otaService = OTAUpdateService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        WidgetSyncService.instance.initialize(
          transactionProvider: context.read<TransactionProvider>(),
          accountProvider: context.read<AccountProvider>(),
          subscriptionProvider: context.read<SubscriptionProvider>(),
          debtProvider: context.read<DebtProvider>(),
        );

        await CrashReportingService().initialize();
        await _otaService.initNotifications();

        // Notification permission is required on Android 13+ (API 33+) for
        // any notification, including the OTA "update available" one below.
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
          final status = await Permission.notification.status;
          if (!status.isGranted) {
            await Permission.notification.request();
          }
        }

        // Startup OTA check — runs every time the app is opened, in
        // addition to the periodic background check registered in main().
        unawaited(
          _currentAppVersionString().then(
            (version) => _otaService.checkAndNotifyOnStartup(version),
          ),
        );

        // Restore Google session and Gmail permissions on startup
        if (mounted) {
          await context.read<GmailProvider>().initialize();
        }

        // Trigger simultaneous scan for SMS and Gmail (if linked)
        if (mounted) {
          unawaited(context.read<NewNboxProvider>().scanAll());
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
