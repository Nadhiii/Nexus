import 'core/services/ota_update_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
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
<<<<<<< Updated upstream
// REMOVED: flutter_dotenv import — no env vars exist, migrated to --dart-define
import 'package:another_telephony/telephony.dart';
import 'core/services/nbox_background_service.dart';
=======
import 'core/services/transaction_brain_service.dart';
>>>>>>> Stashed changes

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

  // Only Firebase is truly required before runApp — and even this
  // can be done faster with a loading screen
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

<<<<<<< Updated upstream
=======
  // Initialize Crashlytics for error reporting
  await CrashReportingService().initialize();

>>>>>>> Stashed changes
  IntentNavigationService.initialize();

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
<<<<<<< Updated upstream
        ChangeNotifierProvider(create: (_) => FamilyDebtProvider()),
        ChangeNotifierProxyProvider<CategoryProvider, GmailProvider>(
          create: (context) => GmailProvider(),
          update: (context, categoryProvider, gmailProvider) {
=======
        ChangeNotifierProvider(create: (_) => FinancialHealthProvider()),
        ChangeNotifierProvider(create: (_) => AIAssistantProvider()),
        // GmailProvider with AI dependencies
        ChangeNotifierProxyProvider2<
          AIAssistantProvider,
          CategoryProvider,
          GmailProvider
        >(
          create: (context) => GmailProvider(),
          update: (context, aiProvider, categoryProvider, gmailProvider) {
>>>>>>> Stashed changes
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
          // update must ALWAYS return the existing instance — never create a
          // second one. Creating a second NewNboxProvider triggers a parallel
          // initialize()/scanSmsInbox() which causes a permission deadlock/ANR.
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
<<<<<<< Updated upstream
      child: _AppInitializer(
        child: MaterialApp(
          title: 'Nexus',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const AuthGate(),
        ),
=======
      child: Consumer<AIAssistantProvider>(
        builder: (context, aiProvider, _) {
          // Initialize AI context providers after all providers are ready
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!aiProvider.isInitialized) {
              _initializeAIProvider(context);
            }
          });

          return Consumer4<
            ThemeProvider,
            TransactionProvider,
            AccountProvider,
            SubscriptionProvider
          >(
            builder:
                (
                  context,
                  themeProvider,
                  transactionProvider,
                  accountProvider,
                  subscriptionProvider,
                  child,
                ) {
                  // Initialize WidgetSyncService with providers
                  final debtProvider = Provider.of<DebtProvider>(
                    context,
                    listen: false,
                  );
                  WidgetSyncService.instance.initialize(
                    transactionProvider: transactionProvider,
                    accountProvider: accountProvider,
                    subscriptionProvider: subscriptionProvider,
                    debtProvider: debtProvider,
                  );

                  // Initialize TransactionBrain - the central "brain" for all transactions
                  TransactionBrainService.instance.initialize(
                    transactionProvider: transactionProvider,
                    accountProvider: accountProvider,
                    budgetProvider: Provider.of<BudgetProvider>(
                      context,
                      listen: false,
                    ),
                    debtProvider: debtProvider,
                    subscriptionProvider: subscriptionProvider,
                    goalProvider: Provider.of<GoalProvider>(
                      context,
                      listen: false,
                    ),
                    investmentProvider: Provider.of<InvestmentProvider>(
                      context,
                      listen: false,
                    ),
                    bikeProvider: Provider.of<BikeProvider>(
                      context,
                      listen: false,
                    ),
                  );

                  return MaterialApp(
                    title: 'Nexus',
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.darkTheme,
                    themeMode: ThemeMode.dark,
                    home: const AuthGate(),
                  );
                },
          );
        },
>>>>>>> Stashed changes
      ),
    );
  }
}

/// Initializes OTA notifications and secondary services once after the first frame,
/// without causing unnecessary rebuilds of the widget tree.
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

        // Initialize secondary services after the first frame paints
        await CrashReportingService().initialize();

        // Environment config: use --dart-define flags at build time
        // e.g. flutter run --dart-define=GEMINI_API_KEY=xxx
        // Access via: const String.fromEnvironment('GEMINI_API_KEY')

        // ONLY initialize notifications here — version check lives in More Screen
        // to avoid the "Reply already submitted" crash during login/SMS scan.
        await _otaService.initNotifications();
      });
    }
  }
<<<<<<< Updated upstream

  @override
  Widget build(BuildContext context) => widget.child;
=======
>>>>>>> Stashed changes
}
