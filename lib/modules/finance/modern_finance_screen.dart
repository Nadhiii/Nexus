import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/modern/modern_widgets.dart';
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
  int _selectedTab = 0;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex, animationDuration: const Duration(milliseconds: 400));
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedTab = _tabController.index;
          _isSearching = false;
          _searchController.clear();
        });
      }
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountProvider>().initialize();
      context.read<TransactionProvider>().loadTransactions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: colorScheme.background,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.background,
                  colorScheme.background.withOpacity(0.8),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, colorScheme),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildAccountsTab(context, colorScheme),
                      _buildTransactionsTab(context, colorScheme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          key: ValueKey<int>(_selectedTab),
          onPressed: () {
            if (_selectedTab == 0) {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ModernAddAccountScreen()));
            } else {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ModernAddTransactionScreen()));
            }
          },
          backgroundColor: colorScheme.primary,
          icon: Icon(Icons.add, color: colorScheme.onPrimary),
          label: Text(
            _selectedTab == 0 ? 'Account' : 'Transaction',
            style: AppTypography.titleSmall.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Finance',
            style: AppTypography.displaySmall.copyWith(color: colorScheme.onBackground, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_selectedTab == 0)
            Consumer<AccountProvider>(
              builder: (context, provider, child) {
                return ModernBalanceCard(
                  title: 'Total Balance',
                  amount: provider.totalBalance,
                  currency: '₹',
                  gradientColors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
                );
              },
            ),
          const SizedBox(height: AppSpacing.xl),
          _buildTabSelector(context, colorScheme),
          if (_isSearching) ...[
            const SizedBox(height: AppSpacing.md),
            _buildSearchBar(context, colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildTabSelector(BuildContext context, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildTabItem(context, colorScheme, 'Accounts', Icons.account_balance_wallet, 0),
          _buildTabItem(context, colorScheme, 'Transactions', Icons.receipt_long, 1),
        ],
      ),
    );
  }

  Widget _buildTabItem(BuildContext context, ColorScheme colorScheme, String title, IconData icon, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.xs),
              Text(title, style: AppTypography.titleSmall.copyWith(
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, ColorScheme colorScheme) {
    return TextField(
      controller: _searchController,
      autofocus: true,
      style: AppTypography.bodyLarge.copyWith(color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: _selectedTab == 0 ? 'Search accounts...' : 'Search transactions...',
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
        suffixIcon: IconButton(
          icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
          onPressed: () => setState(() {
            _isSearching = false;
            _searchController.clear();
          }),
        ),
        filled: true,
        fillColor: colorScheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (value) => setState(() {}),
    );
  }

  Widget _buildAccountsTab(BuildContext context, ColorScheme colorScheme) {
    return Consumer<AccountProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.accounts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.error != null) {
          return _buildErrorState(context, colorScheme, message: provider.error!, onRetry: () => provider.loadAccounts());
        }
        if (provider.accounts.isEmpty) {
          return _buildEmptyState(context, colorScheme, icon: Icons.account_balance_wallet_outlined, title: 'No accounts yet', subtitle: 'Create your first account');
        }

        final accounts = _isSearching
            ? provider.accounts.where((a) => a.name.toLowerCase().contains(_searchController.text.toLowerCase())).toList()
            : provider.accounts;

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 140),
          itemCount: accounts.length + 1,
          separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildSearchButton(context, colorScheme, 'Search accounts');
            }
            final account = accounts[index - 1];
            return ModernAccountTile(
              name: account.name,
              balance: '₹${account.balance.toStringAsFixed(2)}',
              icon: account.icon,
              iconColor: account.color,
              percentage: '${(provider.totalBalance > 0 ? (account.balance / provider.totalBalance) * 100 : 0).toStringAsFixed(1)}%',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => ModernAccountDetailScreen(account: account))),
            );
          },
        );
      },
    );
  }

  Widget _buildTransactionsTab(BuildContext context, ColorScheme colorScheme) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.transactions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.error != null) {
          return _buildErrorState(context, colorScheme, message: provider.error!, onRetry: () => provider.loadTransactions());
        }
        if (provider.transactions.isEmpty) {
          return _buildEmptyState(context, colorScheme, icon: Icons.receipt_long_outlined, title: 'No transactions yet', subtitle: 'Add your first transaction');
        }

        final transactions = _isSearching
            ? provider.transactions.where((t) => t.description?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false).toList()
            : provider.transactions;
        final grouped = _groupTransactionsByDate(transactions);

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 140),
          itemCount: grouped.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildSearchButton(context, colorScheme, 'Search transactions');
            }
            final dateKey = grouped.keys.elementAt(index - 1);
            final transactionsForDate = grouped[dateKey]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text(_formatDateHeader(dateKey), style: AppTypography.titleSmall.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                ),
                ...transactionsForDate.map((t) => ModernTransactionTile(
                      title: t.categoryId ?? 'Uncategorized',
                      subtitle: t.description ?? 'No description',
                      amount: '₹${t.amount.toStringAsFixed(2)}',
                      isIncome: t.type == TransactionType.income,
                      icon: _getTransactionIcon(t.categoryId),
                      onTap: () {},
                    )),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSearchButton(BuildContext context, ColorScheme colorScheme, String hint) {
    return GestureDetector(
      onTap: () => setState(() => _isSearching = true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.md),
            Text(hint, style: AppTypography.bodyLarge.copyWith(color: colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Map<DateTime, List<Transaction>> _groupTransactionsByDate(List<Transaction> transactions) {
    final grouped = <DateTime, List<Transaction>>{};
    for (final transaction in transactions) {
      final date = DateTime(transaction.date.year, transaction.date.month, transaction.date.day);
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(transaction);
    }
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (final key in sortedKeys) key: grouped[key]!};
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (date == today) return 'Today';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  IconData _getTransactionIcon(String? category) {
    // Simplified icon mapping
    return Icons.more_horiz;
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme, {required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: AppSpacing.xl),
          Text(title, style: AppTypography.titleLarge.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.sm),
          Text(subtitle, style: AppTypography.bodyLarge.copyWith(color: colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ColorScheme colorScheme, {required String message, required VoidCallback onRetry}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
          const SizedBox(height: AppSpacing.xl),
          Text('Error', style: AppTypography.titleLarge.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.sm),
          Text(message, style: AppTypography.bodyLarge.copyWith(color: colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
