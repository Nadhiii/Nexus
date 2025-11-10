import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/modern/modern_widgets.dart';
import '../../core/models/transaction.dart';
import '../../core/providers/account_provider.dart';
import '../../core/providers/transaction_provider.dart';
import '../accounts/modern_add_account_screen.dart';
import '../accounts/modern_account_detail_screen.dart';
import '../transactions/modern_add_transaction_screen.dart';

/// Modern Finance Screen - Combined Accounts & Transactions
/// Features: Segmented control tabs, gradient background, smooth transitions
class ModernFinanceScreen extends StatefulWidget {
  const ModernFinanceScreen({super.key});

  @override
  State<ModernFinanceScreen> createState() => _ModernFinanceScreenState();
}

class _ModernFinanceScreenState extends State<ModernFinanceScreen> with SingleTickerProviderStateMixin {
  int _selectedTab = 0; // 0 = Accounts, 1 = Transactions
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2, 
      vsync: this,
      animationDuration: const Duration(milliseconds: 400), // Smoother tab animation
    );
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppColors.darkGradient,
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),
                
                // Tab View
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const BouncingScrollPhysics(), // Smoother iOS-style physics
                    children: [
                      _buildAccountsTab(),
                      _buildTransactionsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      
      // Floating Action Button with smooth transition - positioned above bottom nav
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80), // Position above the bottom nav (70px + margin)
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(
              scale: animation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: FloatingActionButton.extended(
            key: ValueKey<int>(_selectedTab),
            onPressed: () {
            if (_selectedTab == 0) {
              // Add Account
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ModernAddAccountScreen(),
                ),
              );
            } else {
              // Add Transaction
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ModernAddTransactionScreen(),
                ),
              );
            }
          },
          backgroundColor: AppColors.primaryBlue,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            _selectedTab == 0 ? 'Account' : 'Transaction',
            style: AppTypography.titleSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Finance',
            style: AppTypography.displaySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          
          // Total Balance Card (only show on Accounts tab with smooth animation)
          AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            child: _selectedTab == 0
                ? Column(
                    children: [
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _selectedTab == 0 ? 1.0 : 0.0,
                        child: Consumer<AccountProvider>(
                          builder: (context, provider, child) {
                            final total = provider.totalBalance;
                            return ModernBalanceCard(
                              title: 'Total Balance',
                              amount: total,
                              currency: '₹',
                              gradientColors: AppColors.blueGradient,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          
          // Tab Selector
          _buildTabSelector(),
          
          // Search Bar (show when searching)
          if (_isSearching) ...[
            const SizedBox(height: AppSpacing.md),
            _buildSearchBar(),
          ],
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDarkElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _tabController.animateTo(0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400), // Smoother, longer duration
                curve: Curves.easeInOutCubic, // More fluid curve
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: _selectedTab == 0
                      ? AppColors.primaryBlue
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  boxShadow: _selectedTab == 0
                      ? [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedScale(
                      scale: _selectedTab == 0 ? 1.0 : 0.9,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOutCubic,
                      child: Icon(
                        Icons.account_balance_wallet,
                        size: 18,
                        color: _selectedTab == 0
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOutCubic,
                      style: AppTypography.titleSmall.copyWith(
                        color: _selectedTab == 0
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      child: const Text('Accounts'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _tabController.animateTo(1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400), // Smoother, longer duration
                curve: Curves.easeInOutCubic, // More fluid curve
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: _selectedTab == 1
                      ? AppColors.primaryBlue
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  boxShadow: _selectedTab == 1
                      ? [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedScale(
                      scale: _selectedTab == 1 ? 1.0 : 0.9,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOutCubic,
                      child: Icon(
                        Icons.receipt_long,
                        size: 18,
                        color: _selectedTab == 1
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOutCubic,
                      style: AppTypography.titleSmall.copyWith(
                        color: _selectedTab == 1
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      child: const Text('Transactions'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDarkElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        style: AppTypography.bodyLarge.copyWith(
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: _selectedTab == 0 ? 'Search accounts...' : 'Search transactions...',
          hintStyle: TextStyle(color: AppColors.textTertiary),
          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: IconButton(
            icon: Icon(Icons.close, color: AppColors.textSecondary),
            onPressed: () {
              setState(() {
                _isSearching = false;
                _searchController.clear();
              });
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildAccountsTab() {
    return Consumer<AccountProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.accounts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return _buildErrorState(
            message: provider.error!,
            onRetry: () => provider.loadAccounts(),
          );
        }

        if (provider.accounts.isEmpty) {
          return _buildEmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'No accounts yet',
            subtitle: 'Create your first account to start tracking your finances',
          );
        }

        // Filter accounts based on search
        final accounts = _isSearching && _searchController.text.isNotEmpty
            ? provider.accounts.where((account) {
                return account.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                    (account.bankName?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false);
              }).toList()
            : provider.accounts;

        if (_isSearching && accounts.isEmpty) {
          return _buildEmptyState(
            icon: Icons.search_off,
            title: 'No results',
            subtitle: 'Try a different search term',
          );
        }

        final total = provider.totalBalance;

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            140, // Extra space for FAB + bottom nav (70px nav + 30px margin + 40px buffer)
          ),
          itemCount: accounts.length + 1, // +1 for search button
          separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            if (index == 0) {
              // Search button
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardDarkElevated,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: AppColors.textSecondary),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        'Search accounts',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final account = accounts[index - 1];
            final percentage = total > 0 
                ? ((account.balance / total) * 100).toStringAsFixed(1)
                : '0.0';

            return ModernAccountTile(
              name: account.name,
              balance: '₹${account.balance.toStringAsFixed(2)}',
              icon: account.icon,
              iconColor: account.color,
              percentage: '$percentage%',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ModernAccountDetailScreen(
                      account: account,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTransactionsTab() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.transactions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return _buildErrorState(
            message: provider.error!,
            onRetry: () => provider.loadTransactions(),
          );
        }

        if (provider.transactions.isEmpty) {
          return _buildEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No transactions yet',
            subtitle: 'Add your first transaction to start tracking',
          );
        }

        // Filter transactions based on search
        final transactions = _isSearching && _searchController.text.isNotEmpty
            ? provider.transactions.where((transaction) {
                return (transaction.description?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false) ||
                    (transaction.categoryId?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false);
              }).toList()
            : provider.transactions;

        if (_isSearching && transactions.isEmpty) {
          return _buildEmptyState(
            icon: Icons.search_off,
            title: 'No results',
            subtitle: 'Try a different search term',
          );
        }

        // Group transactions by date
        final groupedTransactions = _groupTransactionsByDate(transactions);

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            140, // Extra space for FAB + bottom nav (70px nav + 30px margin + 40px buffer)
          ),
          itemCount: groupedTransactions.length + 1, // +1 for search button
          itemBuilder: (context, index) {
            if (index == 0) {
              // Search button
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchController.clear();
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardDarkElevated,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: AppColors.textSecondary),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          'Search transactions',
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final dateKey = groupedTransactions.keys.elementAt(index - 1);
            final transactionsForDate = groupedTransactions[dateKey]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date header
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.sm,
                    bottom: AppSpacing.sm,
                    top: AppSpacing.md,
                  ),
                  child: Text(
                    _formatDateHeader(dateKey),
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                // Transactions for this date
                ...transactionsForDate.map((transaction) {
                  final isIncome = transaction.type == TransactionType.income;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ModernTransactionTile(
                      title: transaction.categoryId ?? 'Uncategorized',
                      subtitle: transaction.description ?? 'No description',
                      amount: '₹${transaction.amount.toStringAsFixed(2)}',
                      isIncome: isIncome,
                      icon: _getTransactionIcon(transaction.categoryId),
                      onTap: () {
                        // TODO: Navigate to transaction detail
                      },
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  Map<DateTime, List<Transaction>> _groupTransactionsByDate(List<Transaction> transactions) {
    final grouped = <DateTime, List<Transaction>>{};
    
    for (final transaction in transactions) {
      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(transaction);
    }
    
    // Sort by date descending
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final sortedMap = <DateTime, List<Transaction>>{};
    for (final key in sortedKeys) {
      sortedMap[key] = grouped[key]!;
    }
    
    return sortedMap;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (date == today) {
      return 'Today';
    } else if (date == yesterday) {
      return 'Yesterday';
    } else {
      final diff = today.difference(date).inDays;
      if (diff < 7) {
        return '$diff days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    }
  }

  IconData _getTransactionIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'food & dining':
        return Icons.restaurant;
      case 'shopping':
        return Icons.shopping_bag;
      case 'transportation':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'bills':
        return Icons.receipt_long;
      case 'healthcare':
        return Icons.local_hospital;
      case 'salary':
        return Icons.account_balance_wallet;
      case 'investment':
        return Icons.trending_up;
      default:
        return Icons.more_horiz;
    }
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl2),
              decoration: BoxDecoration(
                color: AppColors.cardDarkElevated,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              title,
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState({
    required String message,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Error',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl2,
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
