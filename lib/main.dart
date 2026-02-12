import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/account_provider.dart';
import 'core/providers/transaction_provider.dart';
import 'core/providers/new_nbox_provider.dart';
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
import 'core/providers/fuel_price_provider.dart';
import 'core/providers/pdf_import_provider.dart';
import 'core/providers/shared_expense_provider.dart';
import 'core/providers/financial_health_provider.dart';
import 'modules/ai_assistant/providers/ai_assistant_provider.dart';
import 'core/auth/auth_gate.dart';
import 'core/services/crash_reporting_service.dart';
import 'core/services/widget_sync_service.dart';
import 'core/services/intent_navigation_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Crashlytics for error reporting
  await CrashReportingService().initialize();

  await dotenv.load(fileName: ".env");

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
        ChangeNotifierProvider(create: (_) => GmailProvider()),
        ChangeNotifierProvider(create: (_) => GoalProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => BikeProvider()),
        ChangeNotifierProvider(create: (_) => FuelPriceProvider()),
        ChangeNotifierProvider(create: (_) => PDFImportProvider()),
        ChangeNotifierProvider(create: (_) => SharedExpenseProvider()),
        ChangeNotifierProvider(create: (_) => FinancialHealthProvider()),
        ChangeNotifierProvider(create: (_) => AIAssistantProvider()),
        ChangeNotifierProxyProvider<GmailProvider, NewNboxProvider>(
          create: (context) => NewNboxProvider(),
          update: (context, gmailProvider, nboxProvider) {
            nboxProvider?.update(gmailProvider);
            return nboxProvider!;
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
      child:
          Consumer4<
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

                  return MaterialApp(
                    title: 'Nexus',
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.darkTheme,
                    themeMode: ThemeMode.dark,
                    home: const AuthGate(),
                  );
                },
          ),
    );
  }
}
