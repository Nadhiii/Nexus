import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../screens/main_screen.dart';
import '../../screens/login_screen.dart';
import '../providers/user_provider.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/debt_provider.dart';
import '../providers/goal_provider.dart';
import '../providers/investment_provider.dart';
import '../providers/gmail_provider.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _lastUserId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading screen while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          // User is signed in
          final user = snapshot.data!;

          // Only initialize if this is a new user or first login
          if (_lastUserId != user.uid) {
            _lastUserId = user.uid;
            // Defer provider initialization to avoid calling setState during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _initializeProviders(context, user);
            });
          }

          return const MainScreen();
        } else {
          // User is not signed in
          _lastUserId = null;
          return const LoginScreen();
        }
      },
    );
  }

  void _initializeProviders(BuildContext context, User user) {
    // Initialize providers that need to be loaded on auth change
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );
    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(
      context,
      listen: false,
    );
    final debtProvider = Provider.of<DebtProvider>(context, listen: false);
    final goalProvider = Provider.of<GoalProvider>(context, listen: false);
    final investmentProvider = Provider.of<InvestmentProvider>(
      context,
      listen: false,
    );
    final gmailProvider = Provider.of<GmailProvider>(context, listen: false);

    userProvider.loadUser(user);
    accountProvider.initialize();
    transactionProvider.initialize();
    budgetProvider.initialize();
    subscriptionProvider.initialize();
    debtProvider.initialize();
    goalProvider.loadGoals(user.uid);
    investmentProvider.loadInvestments(user.uid);
    gmailProvider.scanEmails();
  }
}
