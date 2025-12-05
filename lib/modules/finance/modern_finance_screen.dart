import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern/modern_widgets.dart';
import '../../core/widgets/swipe_to_delete.dart';
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

class _ModernFinanceScreenState extends State<ModernFinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkGradient.first,
      body: Stack(
        children: [
          // 1. Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppColors.darkGradient,
              ),
            ),
          ),

          // 2. Nested Scroll View
          NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
                  return <Widget>[
                    SliverOverlapAbsorber(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context,
                      ),
                      sliver: _buildAppBar(context, innerBoxIsScrolled),
                    ),
                  ];
                },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildAccountsTab(context),
                _buildTransactionsTab(context),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 90.0),
            child: FloatingActionButton.extended(
              onPressed: () {
                if (_tabController.index == 0) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ModernAddAccountScreen(),
                    ),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ModernAddTransactionScreen(),
                    ),
                  );
                }
              },
              label: Text(
                _tabController.index == 0 ? 'New Account' : 'New Transaction',
              ),
              icon: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool innerBoxIsScrolled) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 140.0, // Matches standard expanded headers better
      forceElevated: innerBoxIsScrolled,
      backgroundColor: AppColors.darkGradient.first,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        expandedTitleScale:
            1.0, // Disable scaling to match Insights static size or set to 1.2 for subtle effect
        title: Padding(
          padding: const EdgeInsets.only(bottom: 50), // Push title above tabs
          child: Text('Finance', style: AppTypography.headlineMedium),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          // Subtle background to ensure legibility when scrolling
          color: AppColors.darkGradient.first,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: colorScheme.primaryContainer,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: colorScheme.onPrimaryContainer,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              labelStyle: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: textTheme.titleSmall,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Accounts'),
                Tab(text: 'Transactions'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountsTab(BuildContext context) {
    return Builder(
      builder: (BuildContext context) {
        return CustomScrollView(
          slivers: <Widget>[
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            Consumer<AccountProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.accounts.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                return SliverPadding(
                  // Adjusted padding to prevent overflow
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    140,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final account = provider.accounts[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: SwipeToDelete(
                          itemKey: ValueKey(account.id),
                          itemId: account.id,
                          itemName: account.name,
                          showConfirmation: true,
                          confirmTitle: 'Delete Account',
                          confirmMessage:
                              'Are you sure you want to delete "${account.name}"? All transactions in this account will remain but won\'t be linked to any account.',
                          onDelete: () {
                            provider.deleteAccount(account.id);
                          },
                          child: ModernAccountTile(
                            name: account.name,
                            balance: '₹${account.balance.toStringAsFixed(2)}',
                            icon: account.icon,
                            iconColor: account.color,
                            percentage:
                                '${(provider.totalBalance > 0 ? (account.balance / provider.totalBalance) * 100 : 0).toStringAsFixed(1)}%',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    ModernAccountDetailScreen(account: account),
                              ),
                            ),
                          ),
                        ),
                      );
                    }, childCount: provider.accounts.length),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransactionsTab(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Builder(
      builder: (BuildContext context) {
        return CustomScrollView(
          slivers: <Widget>[
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            Consumer<TransactionProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.transactions.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (provider.transactions.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: colorScheme.onSurfaceVariant.withOpacity(
                              0.5,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'No transactions yet',
                            style: AppTypography.titleMedium.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Tap the + button to add your first transaction',
                            style: AppTypography.bodySmall.copyWith(
                              color: colorScheme.onSurfaceVariant.withOpacity(
                                0.7,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    140,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final transaction = provider.transactions[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: SwipeToDelete(
                          itemKey: ValueKey(transaction.id),
                          itemId: transaction.id,
                          itemName: 'Transaction',
                          onDelete: () {
                            provider.deleteTransaction(transaction.id);
                          },
                          onUndoDelete: () {
                            provider.restoreTransaction(transaction);
                          },
                          child: ModernTransactionTile(
                            title: transaction.categoryId ?? 'Uncategorized',
                            subtitle:
                                transaction.description ?? 'No description',
                            amount: '₹${transaction.amount.toStringAsFixed(2)}',
                            isIncome:
                                transaction.type == TransactionType.income,
                            icon: Icons.receipt_long,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ModernAddTransactionScreen(
                                        transaction: transaction,
                                      ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }, childCount: provider.transactions.length),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
