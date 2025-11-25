import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/account_provider.dart';
import 'core/providers/transaction_provider.dart';
import 'core/providers/new_nbox_provider.dart';
import 'core/providers/debt_provider.dart';

import 'core/providers/investment_provider.dart';
import 'core/providers/crypto_provider.dart';
import 'core/providers/biometric_provider.dart';
import 'core/providers/notification_provider.dart';
import 'core/providers/subscription_provider.dart';
import 'core/providers/budget_provider.dart';
import 'core/providers/user_provider.dart';
import 'core/providers/gmail_provider.dart';
import 'core/providers/goal_provider.dart';
import 'core/providers/category_provider.dart';
import 'core/services/learning_service.dart';
import 'core/auth/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final learningService = LearningService();
  await learningService.init();

  runApp(NexusApp(learningService: learningService));
}

class NexusApp extends StatelessWidget {
  final LearningService learningService;

  const NexusApp({super.key, required this.learningService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<LearningService>.value(value: learningService),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => DebtProvider()),
        ChangeNotifierProvider(create: (_) => InvestmentProvider()),
        ChangeNotifierProvider(create: (_) => CryptoProvider()),
        ChangeNotifierProvider(create: (_) => BiometricProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => GmailProvider()),
        ChangeNotifierProvider(create: (_) => GoalProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProxyProvider<GmailProvider, NewNboxProvider>(
          create: (context) => NewNboxProvider(),
          update: (context, gmailProvider, nboxProvider) {
            nboxProvider?.update(gmailProvider);
            return nboxProvider!;
          },
        ),
        ChangeNotifierProxyProvider<NotificationProvider, SubscriptionProvider>(
          // FIXED: Passed learningService to constructor
          create: (context) =>
              SubscriptionProvider(learningService: learningService),
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
          create: (context) =>
              TransactionProvider(learningService: learningService),
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
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return DynamicColorBuilder(
            builder: (_, ColorScheme? darkDynamic) {
              return MaterialApp(
                title: 'Nexus',
                debugShowCheckedModeBanner: false,
                theme: themeProvider.useMaterialYou
                    ? AppTheme.getTheme(darkDynamic ?? const ColorScheme.dark())
                    : AppTheme.darkTheme,
                themeMode: ThemeMode.dark,
                home: const AuthGate(),
              );
            },
          );
        },
      ),
    );
  }
}
