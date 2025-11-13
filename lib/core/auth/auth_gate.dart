import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../screens/login_screen.dart';
import '../../screens/main_screen.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/investment_provider.dart';
import '../providers/debt_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/biometric_provider.dart';
import 'biometric_auth_wrapper.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If user is logged in, show the main app with biometric protection
        if (snapshot.hasData && snapshot.data != null) {
          return AuthenticatedApp(user: snapshot.data!);
        }

        // Otherwise, show the login screen
        return const LoginScreen();
      },
    );
  }
}

class AuthenticatedApp extends StatefulWidget {
  final User user;

  const AuthenticatedApp({super.key, required this.user});

  @override
  State<AuthenticatedApp> createState() => _AuthenticatedAppState();
}

class _AuthenticatedAppState extends State<AuthenticatedApp> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeProviders();
  }

  Future<void> _initializeProviders() async {
    try {
      final biometricProvider = Provider.of<BiometricProvider>(context, listen: false);
      final accountProvider = Provider.of<AccountProvider>(context, listen: false);
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final investmentProvider = Provider.of<InvestmentProvider>(context, listen: false);
      final debtProvider = Provider.of<DebtProvider>(context, listen: false);
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);

      // Initialize providers with authenticated user
      await biometricProvider.initialize();
      await accountProvider.initialize();
      await transactionProvider.initialize();
      investmentProvider.initialize();
      debtProvider.initialize();
      subscriptionProvider.initialize();
      budgetProvider.initialize();

      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      print('Error initializing providers: $e');
      if (mounted) {
        setState(() {
          _initialized = true; // Allow app to continue even if initialization fails
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing your financial data...'),
            ],
          ),
        ),
      );
    }

    return BiometricAuthWrapper(child: MainScreen());
  }
}
