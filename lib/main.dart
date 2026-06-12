import 'core/services/ota_update_service.dart';
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
import 'core/providers/bike_provider.dart';
import 'core/providers/vehicle_management_provider.dart';
import 'core/providers/fuel_price_provider.dart';
import 'core/providers/shared_expense_provider.dart';
import 'core/providers/family_debt_provider.dart';
import 'core/auth/auth_gate.dart';
import 'core/services/crash_reporting_service.dart';
import 'core/services/widget_sync_service.dart';
import 'core/services/intent_navigation_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only Firebase is truly required before runApp — and even this
  // can be done faster with a loading screen
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
        ChangeNotifierProvider(create: (_) => BikeProvider()),
        ChangeNotifierProvider(create: (_) => VehicleManagementProvider()),
        ChangeNotifierProvider(create: (_) => FuelPriceProvider()),
        ChangeNotifierProvider(create: (_) => SharedExpenseProvider()),
        ChangeNotifierProvider(create: (_) => FamilyDebtProvider()),
        ChangeNotifierProxyProvider<CategoryProvider, GmailProvider>(
          create: (context) => GmailProvider(
            categoryProvider: context.read<CategoryProvider>(),
          ),
          update: (context, categoryProvider, gmailProvider) {
            return gmailProvider ??
                GmailProvider(categoryProvider: categoryProvider);
          },
        ),
        ChangeNotifierProxyProvider2<GmailProvider, CategoryProvider, NewNboxProvider>(
          create: (context) => NewNboxProvider(
            gmailProvider: context.read<GmailProvider>(),
            categoryProvider: context.read<CategoryProvider>(),
          ),
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
          update: (context, accountProvider, budgetProvider, notificationProvider, transactionProvider) {
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
        child: Consumer4<ThemeProvider, TransactionProvider, AccountProvider, SubscriptionProvider>(
          builder: (context, themeProvider, transactionProvider, accountProvider, subscriptionProvider, child) {
            WidgetSyncService.instance.initialize(
              transactionProvider: transactionProvider,
              accountProvider: accountProvider,
              subscriptionProvider: subscriptionProvider,
              debtProvider: Provider.of<DebtProvider>(context, listen: false),
            );

            return MaterialApp(
              title: 'Nexus',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.darkTheme,
              themeMode: ThemeMode.dark,
              home: const AuthGate(),
            );
          },
        ),
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
        
        // Initialize secondary services after the first frame paints
        await CrashReportingService().initialize();
        
        try {
          await dotenv.load(fileName: ".env");
        } catch (e) {
          debugPrint('dotenv load skipped: $e');
        }

        // ONLY initialize notifications here — version check lives in More Screen
        // to avoid the "Reply already submitted" crash during login/SMS scan.
        await _otaService.initNotifications();
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}