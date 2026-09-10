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
import 'core/services/transaction_brain_service.dart';
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
        ChangeNotifierProvider(create: (_) => GoalProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => BikeProvider()),
        ChangeNotifierProvider(create: (_) => FuelPriceProvider()),
        ChangeNotifierProvider(create: (_) => PDFImportProvider()),
        ChangeNotifierProvider(create: (_) => SharedExpenseProvider()),
        ChangeNotifierProvider(create: (_) => FinancialHealthProvider()),
        ChangeNotifierProvider(create: (_) => AIAssistantProvider()),
        // GmailProvider with AI dependencies
        ChangeNotifierProxyProvider2<
          AIAssistantProvider,
          CategoryProvider,
          GmailProvider
        >(
          create: (context) => GmailProvider(
            aiAssistantProvider: context.read<AIAssistantProvider>(),
            categoryProvider: context.read<CategoryProvider>(),
          ),
          update: (context, aiProvider, categoryProvider, gmailProvider) {
            return gmailProvider ??
                GmailProvider(
                  aiAssistantProvider: aiProvider,
                  categoryProvider: categoryProvider,
                );
          },
        ),
        // NewNboxProvider with Gmail and AI dependencies
        ChangeNotifierProxyProvider3<
          GmailProvider,
          AIAssistantProvider,
          CategoryProvider,
          NewNboxProvider
        >(
          create: (context) => NewNboxProvider(
            gmailProvider: context.read<GmailProvider>(),
            aiAssistantProvider: context.read<AIAssistantProvider>(),
            categoryProvider: context.read<CategoryProvider>(),
          ),
          update:
              (
                context,
                gmailProvider,
                aiProvider,
                categoryProvider,
                nboxProvider,
              ) {
                nboxProvider?.update(gmailProvider);
                return nboxProvider ??
                    NewNboxProvider(
                      gmailProvider: gmailProvider,
                      aiAssistantProvider: aiProvider,
                      categoryProvider: categoryProvider,
                    );
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
                    budgetProvider: Provider.of<BudgetProvider>(context, listen: false),
                    debtProvider: debtProvider,
                    subscriptionProvider: subscriptionProvider,
                    goalProvider: Provider.of<GoalProvider>(context, listen: false),
                    investmentProvider: Provider.of<InvestmentProvider>(context, listen: false),
                    bikeProvider: Provider.of<BikeProvider>(context, listen: false),
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
      ),
    );
  }

  /// Initialize AIAssistantProvider with all context providers
  void _initializeAIProvider(BuildContext context) {
    try {
      final aiProvider = Provider.of<AIAssistantProvider>(
        context,
        listen: false,
      );

      // Set all context providers
      aiProvider.setContextProviders(
        accountProvider: Provider.of<AccountProvider>(context, listen: false),
        debtProvider: Provider.of<DebtProvider>(context, listen: false),
        investmentProvider: Provider.of<InvestmentProvider>(
          context,
          listen: false,
        ),
        subscriptionProvider: Provider.of<SubscriptionProvider>(
          context,
          listen: false,
        ),
        transactionProvider: Provider.of<TransactionProvider>(
          context,
          listen: false,
        ),
        budgetProvider: Provider.of<BudgetProvider>(context, listen: false),
        goalProvider: Provider.of<GoalProvider>(context, listen: false),
        bikeProvider: Provider.of<BikeProvider>(context, listen: false),
        nboxProvider: Provider.of<NewNboxProvider>(context, listen: false),
        pdfImportProvider: Provider.of<PDFImportProvider>(
          context,
          listen: false,
        ),
        sharedExpenseProvider: Provider.of<SharedExpenseProvider>(
          context,
          listen: false,
        ),
        categoryProvider: Provider.of<CategoryProvider>(context, listen: false),
      );

      // Initialize after setting providers
      aiProvider.initialize();
    } catch (e) {
      debugPrint('Error initializing AI provider: $e');
    }
  }
}