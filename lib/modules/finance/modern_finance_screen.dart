import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/modern/modern_widgets.dart';
import '../../core/models/account.dart';
import '../../core/models/transaction.dart';
import '../../core/providers/account_provider.dart';
import '../../core/providers/transaction_provider.dart';
import '../accounts/modern_add_account_screen.dart';
import '../accounts/modern_account_detail_screen.dart';
import '../transactions/modern_add_transaction_screen.dart';

class ModernFinanceScreen extends StatefulWidget {
  final int initialTabIndex;

  const ModernFinanceScreen({super.key, this.initialTabIndex = 0});

  @override
  State<ModernFinanceScreen> createState() => _ModernFinanceScreenState();
}

class _ModernFinanceScreenState extends State<ModernFinanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountProvider>().initialize();
      context.read<TransactionProvider>().loadTransactions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAccountsTab(context),
          _buildTransactionsTab(context),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton.extended(
          onPressed: () {
            if (_tabController.index == 0) {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ModernAddAccountScreen()));
            } else {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ModernAddTransactionScreen()));
            }
          },
          label: Text(_tabController.index == 0 ? 'New Account' : 'New Transaction'),
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      title: Text('Finance', style: textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onBackground)),
      backgroundColor: Colors.transparent,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: colorScheme.primaryContainer,
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: colorScheme.onPrimaryContainer,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            labelStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            unselectedLabelStyle: textTheme.titleSmall,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Accounts'),
              Tab(text: 'Transactions'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountsTab(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Consumer<AccountProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.accounts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 140),
          itemCount: provider.accounts.length,
          itemBuilder: (context, index) {
            final account = provider.accounts[index];
            return Dismissible(
              key: ValueKey(account.id),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) async {
                await provider.deleteAccount(account.id);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text('Account "${account.name}" deleted.')));
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Icon(Icons.delete, color: colorScheme.onErrorContainer),
              ),
              child: ModernAccountTile(
                name: account.name,
                balance: '₹${account.balance.toStringAsFixed(2)}',
                icon: account.icon,
                iconColor: account.color,
                percentage: '${(provider.totalBalance > 0 ? (account.balance / provider.totalBalance) * 100 : 0).toStringAsFixed(1)}%',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => ModernAccountDetailScreen(account: account))),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTransactionsTab(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.transactions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 140),
          itemCount: provider.transactions.length,
          itemBuilder: (context, index) {
            final transaction = provider.transactions[index];
            return Dismissible(
              key: ValueKey(transaction.id),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) async {
                await provider.deleteTransaction(transaction.id);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text('Transaction deleted.')));
              },
               background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Icon(Icons.delete, color: colorScheme.onErrorContainer),
              ),
              child: ModernTransactionTile(
                title: transaction.categoryId ?? 'Uncategorized',
                subtitle: transaction.description ?? 'No description',
                amount: '₹${transaction.amount.toStringAsFixed(2)}',
                isIncome: transaction.type == TransactionType.income,
                icon: _getTransactionIcon(transaction.categoryId),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => ModernAddTransactionScreen(transaction: transaction))),
              ),
            );
          },
        );
      },
    );
  }

  IconData _getTransactionIcon(String? category) {
    // This can be expanded into a proper mapping
    return Icons.more_horiz;
  }
}
