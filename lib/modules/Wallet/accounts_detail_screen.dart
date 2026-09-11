import 'package:flutter/material.dart';

import 'wallet_screen.dart';

/// Account and transaction details opened from the Wealth Accounts tile.
class AccountsDetailScreen extends StatelessWidget {
  final int initialTabIndex;

  const AccountsDetailScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ModernFinanceScreen(
      initialTabIndex: initialTabIndex,
      showBalanceHero: false,
      screenTitle: initialTabIndex == 1 ? 'Account Transactions' : 'Accounts',
    );
  }
}