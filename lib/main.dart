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
import 'core/providers/backup_provider.dart';
import 'core/providers/investment_provider.dart';
import 'core/providers/biometric_provider.dart';
import 'core/providers/notification_provider.dart';
import 'core/providers/subscription_provider.dart';
import 'core/providers/budget_provider.dart';
import 'core/providers/user_provider.dart';
import 'core/auth/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
        ChangeNotifierProvider(create: (_) => NewNboxProvider()), 
        ChangeNotifierProvider(create: (_) => DebtProvider()),
        ChangeNotifierProvider(create: (_) => BackupProvider()),
        ChangeNotifierProvider(create: (_) => InvestmentProvider()),
        ChangeNotifierProvider(create: (_) => BiometricProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),

        ChangeNotifierProxyProvider<NotificationProvider, SubscriptionProvider>(
          create: (context) => SubscriptionProvider(),
          update: (context, notificationProvider, subscriptionProvider) => 
              SubscriptionProvider(notificationProvider: notificationProvider),
        ),
        ChangeNotifierProxyProvider<NotificationProvider, BudgetProvider>(
          create: (context) => BudgetProvider(),
          update: (context, notificationProvider, budgetProvider) => 
              BudgetProvider(notificationProvider: notificationProvider),
        ),
        ChangeNotifierProxyProvider2<NotificationProvider, BudgetProvider, TransactionProvider>(
          create: (context) => TransactionProvider(),
          update: (context, notificationProvider, budgetProvider, transactionProvider) => 
              TransactionProvider(
                notificationProvider: notificationProvider,
                budgetProvider: budgetProvider,
              ),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return DynamicColorBuilder(
            builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
              return MaterialApp(
                title: 'Nexus',
                debugShowCheckedModeBanner: false,
                theme: themeProvider.useMaterialYou
                    ? AppTheme.getTheme(lightDynamic ?? const ColorScheme.light())
                    : AppTheme.lightTheme,
                darkTheme: themeProvider.useMaterialYou
                    ? AppTheme.getTheme(darkDynamic ?? const ColorScheme.dark())
                    : AppTheme.darkTheme,
                themeMode: themeProvider.themeMode,
                home: const AuthGate(),
              );
            },
          );
        },
      ),
    );
  }
}
