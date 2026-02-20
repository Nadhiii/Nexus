import 'package:flutter/material.dart';
import '../../core/widgets/collapsible_fab.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_animations.dart';
import '../../core/widgets/swipe_to_delete.dart';
import '../../core/models/transaction.dart';
import '../../core/providers/account_provider.dart';
import '../../core/providers/category_provider.dart';
import '../../core/providers/transaction_provider.dart';
import '../accounts/modern_add_account_screen.dart';
import '../accounts/modern_account_detail_screen.dart';
import '../transactions/modern_add_transaction_screen.dart';
import '../../core/utils/transaction_display.dart';
import '../../core/utils/logo_utils.dart';

enum WalletView { accounts, history }

class ModernFinanceScreen extends StatefulWidget {
  final int initialTabIndex; // Kept for backward compatibility if needed
  const ModernFinanceScreen({super.key, this.initialTabIndex = 0});

  @override
  State<ModernFinanceScreen> createState() => _ModernFinanceScreenState();
}

class _ModernFinanceScreenState extends State<ModernFinanceScreen> {
  WalletView _currentView = WalletView.accounts;
  bool _isSelectionMode = false;
  final Set<String> _selectedTransactionIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialTabIndex == 1) {
      _currentView = WalletView.history;
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedTransactionIds.clear();
      }
    });
  }

  void _selectAll(List<Transaction> transactions) {
    setState(() {
      _selectedTransactionIds.clear();
      _selectedTransactionIds.addAll(transactions.map((t) => t.id));
    });
  }

  void _deleteSelected(TransactionProvider provider) async {
    if (_selectedTransactionIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.backgroundBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        insetPadding: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delete ${_selectedTransactionIds.length} Transaction(s)?',
                style: AppTypography.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: AppColors.error, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This action cannot be undone.',
                        style: TextStyle(color: AppColors.error, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      for (final id in _selectedTransactionIds) {
        await provider.deleteTransaction(id);
      }
      setState(() {
        _selectedTransactionIds.clear();
        _isSelectionMode = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: Consumer2<AccountProvider, TransactionProvider>(
        builder: (context, accountProvider, txnProvider, child) {
          final totalCash = accountProvider.accounts.fold(
            0.0,
            (sum, a) => sum + a.balance,
          );
          final now = DateTime.now();
          final monthStart = DateTime(now.year, now.month, 1);
          final monthTxns = txnProvider.transactions
              .where((t) => t.date.isAfter(monthStart))
              .toList();
          final monthExpense = monthTxns
              .where((t) => t.type == TransactionType.expense)
              .fold(0.0, (sum, t) => sum + t.amount);

          return CustomScrollView(
            slivers: [
              // 1. HEADER
              SliverAppBar(
                pinned: true,
                expandedHeight: 110,
                backgroundColor: AppColors.backgroundBlack,
                surfaceTintColor: AppColors.backgroundBlack,
                elevation: 0,
                automaticallyImplyLeading: false,
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final percent =
                        ((constraints.maxHeight - kToolbarHeight) /
                                (110 - kToolbarHeight))
                            .clamp(0.0, 1.0);
                    return FlexibleSpaceBar(
                      centerTitle: false,
                      titlePadding: const EdgeInsets.only(left: 20, bottom: 24),
                      title: _isSelectionMode
                          ? AnimatedOpacity(
                              opacity: percent,
                              duration: const Duration(milliseconds: 200),
                              child: AnimatedScale(
                                scale: 0.9 + 0.1 * percent,
                                duration: const Duration(milliseconds: 200),
                                child: Text(
                                  '${_selectedTransactionIds.length} selected',
                                  style: AppTypography.headlineMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            )
                          : AnimatedOpacity(
                              opacity: percent,
                              duration: const Duration(milliseconds: 200),
                              child: AnimatedScale(
                                scale: 0.9 + 0.1 * percent,
                                duration: const Duration(milliseconds: 200),
                                child: Text(
                                  'Wallet',
                                  style: AppTypography.headlineMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                    );
                  },
                ),
                actions: _currentView == WalletView.history
                    ? [
                        if (_isSelectionMode) ...[
                          IconButton(
                            icon: const Icon(Icons.select_all),
                            onPressed: () =>
                                _selectAll(txnProvider.transactions),
                            tooltip: 'Select All',
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: AppColors.error,
                            ),
                            onPressed: () => _deleteSelected(txnProvider),
                            tooltip: 'Delete Selected',
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _toggleSelectionMode,
                            tooltip: 'Cancel',
                          ),
                        ] else ...[
                          IconButton(
                            icon: const Icon(Icons.checklist),
                            onPressed: _toggleSelectionMode,
                            tooltip: 'Select Transactions',
                          ),
                        ],
                      ]
                    : null,
              ),

              // 2. TOTAL CASH HERO (Only show on Accounts view, or always? Let's show always for context)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: _buildTotalCashCard(
                    totalCash,
                    accountProvider.accounts.length,
                    monthExpense,
                  ),
                ),
              ),

              // 3. GLASS TOGGLE
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: _buildViewToggle(),
                ),
              ),

              // 4. CONTENT LIST
              if (_currentView == WalletView.accounts)
                _buildAccountsList(context, accountProvider)
              else
                _buildTransactionsList(context, txnProvider),
            ],
          );
        },
      ),
      floatingActionButton: CollapsibleFab(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        icon: Icon(
          _currentView == WalletView.accounts
              ? Icons.account_balance_wallet
              : Icons.receipt_long,
        ),
        label: _currentView == WalletView.accounts
            ? 'Add Account'
            : 'Log Transaction',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => _currentView == WalletView.accounts
                  ? const ModernAddAccountScreen()
                  : const ModernAddTransactionScreen(),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildTotalCashCard(double total, int count, double monthExpense) {
    final status = _resolveBalanceStatus(total, monthExpense);
    final formattedTotal = _formatSignedCurrency(total);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade900.withOpacity(0.9),
            const Color(0xFF1E3A8A),
            AppColors.cardSurface,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LIQUID ASSETS',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(status.icon, color: status.color, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      status.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formattedTotal,
            style: AppTypography.displaySmall.copyWith(
              color: Colors.white,
              fontSize: 36,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            status.message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white70,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                '$count Accounts',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Row(
      children: [
        _buildPill("Accounts", WalletView.accounts),
        const SizedBox(width: 12),
        _buildPill("History", WalletView.history),
      ],
    );
  }

  Widget _buildPill(String label, WalletView view) {
    final isSelected = _currentView == view;
    return GestureDetector(
      onTap: () => setState(() => _currentView = view),
      child: AnimatedContainer(
        duration: AppAnimations.standard,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  _BalanceStatus _resolveBalanceStatus(double balance, double monthlyExpense) {
    if (balance < 0) {
      return _BalanceStatus(
        label: 'Overdrawn',
        color: AppColors.error,
        icon: Icons.trending_down,
        message: 'In the red right now',
      );
    }

    if (balance < 5000) {
      return _BalanceStatus(
        label: 'Low',
        color: AppColors.warning,
        icon: Icons.warning_amber,
        message: _buildRunwayMessage(balance, monthlyExpense),
      );
    }

    if (monthlyExpense > 0) {
      final runway = balance / monthlyExpense;
      if (runway >= 2) {
        return _BalanceStatus(
          label: 'Good',
          color: AppColors.success,
          icon: Icons.verified,
          message: _buildRunwayMessage(balance, monthlyExpense),
        );
      }

      if (runway >= 1) {
        return _BalanceStatus(
          label: 'Moderate',
          color: AppColors.info,
          icon: Icons.trending_flat,
          message: _buildRunwayMessage(balance, monthlyExpense),
        );
      }

      return _BalanceStatus(
        label: 'Low',
        color: AppColors.warning,
        icon: Icons.warning_amber,
        message: _buildRunwayMessage(balance, monthlyExpense),
      );
    }

    final label = balance >= 20000 ? 'Good' : 'Moderate';
    final color = balance >= 20000 ? AppColors.success : AppColors.info;
    final icon = balance >= 20000 ? Icons.verified : Icons.trending_flat;

    return _BalanceStatus(
      label: label,
      color: color,
      icon: icon,
      message: 'No spend data yet',
    );
  }

  String _buildRunwayMessage(double balance, double monthlyExpense) {
    if (monthlyExpense <= 0) {
      return 'No spend data yet';
    }
    final runway = balance / monthlyExpense;
    if (runway <= 0) {
      return 'In the red right now';
    }
    if (runway < 0.5) {
      return 'Watch your wallet';
    } else if (runway < 1) {
      return 'Chill till next paycheck';
    } else if (runway < 2) {
      return 'You\'re good for a month';
    } else if (runway < 3) {
      return 'Chill for ~${runway.toStringAsFixed(1)} months';
    } else if (runway < 6) {
      return 'You\'re golden for a few months';
    } else {
      return 'You\'re set for life (almost)';
    }
  }

  String _formatSignedCurrency(double amount) {
    final absFormatted = NumberFormat('#,##,###').format(amount.abs());
    return amount < 0 ? '-₹$absFormatted' : '₹$absFormatted';
  }

  Widget _buildAccountsList(BuildContext context, AccountProvider provider) {
    if (provider.isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (provider.accounts.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState("No Accounts Linked", Icons.account_balance),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 140),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final account = provider.accounts[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SwipeToDelete(
              itemKey: ValueKey(account.id),
              itemId: account.id,
              itemName: account.name,
              showConfirmation: true,
              confirmTitle: 'Delete Account?',
              confirmMessage: 'This will delete all linked transactions.',
              onDelete: () => provider.deleteAccount(account.id),
              onUndoDelete: () => provider.restoreDeletedAccount(),
              child: _buildAccountCard(context, account),
            ),
          );
        }, childCount: provider.accounts.length),
      ),
    );
  }

  Widget _buildTransactionsList(
    BuildContext context,
    TransactionProvider provider,
  ) {
    if (provider.isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (provider.transactions.isEmpty) {
      return SliverFillRemaining(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [_buildEmptyState("No Recent Activity", Icons.receipt)],
        ),
      );
    }

    final transactions = List<Transaction>.from(provider.transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 200),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final t = transactions[index];
          final showHeader =
              index == 0 || !_isSameDay(t.date, transactions[index - 1].date);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showHeader) _buildDateHeader(t.date),
              _buildTransactionTile(context, t, provider),
            ],
          );
        }, childCount: transactions.length),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, dynamic account) {
    final bankLogo = LogoUtils.bankLogoFor(account.bankName ?? account.name);
    final logoScale = LogoUtils.bankLogoScale(account.bankName ?? account.name);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ModernAccountDetailScreen(account: account),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [account.color.withOpacity(0.15), AppColors.cardSurface],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: account.color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: account.color.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: Center(
                child: bankLogo != null
                    ? LogoUtils.buildLogo(bankLogo, size: 28 * logoScale)
                    : Icon(account.icon, color: account.color, size: 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: account.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      account.typeDisplayName,
                      style: TextStyle(
                        color: account.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "₹${account.balance.toStringAsFixed(0)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: account.isActive
                            ? AppColors.success
                            : AppColors.textTertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      account.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(
    BuildContext context,
    Transaction t,
    TransactionProvider provider,
  ) {
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );
    final categoryLabel = resolveTransactionDisplayLabel(
      t,
      categoryProvider.categories,
      emptyLabel: 'General',
    );
    final isIncome = t.type == TransactionType.income;
    final isTransfer = t.type == TransactionType.transfer;
    final isSelected = _selectedTransactionIds.contains(t.id);

    final color = isTransfer
        ? Colors.blue
        : (isIncome ? AppColors.success : AppColors.error);
    final icon = isTransfer
        ? Icons.swap_horiz
        : (isIncome ? Icons.arrow_downward : Icons.arrow_upward);
    final sign = isIncome ? "+" : (isTransfer ? "" : "-");

    Widget tile = Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: _isSelectionMode && isSelected
            ? LinearGradient(
                colors: [
                  AppColors.primaryBlue.withOpacity(0.12),
                  AppColors.primaryBlue.withOpacity(0.06),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withOpacity(0.05), AppColors.cardSurface],
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isSelectionMode && isSelected
              ? AppColors.primaryBlue
              : color.withOpacity(0.08),
          width: _isSelectionMode && isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_isSelectionMode) ...[
            Checkbox(
              value: isSelected,
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _selectedTransactionIds.add(t.id);
                  } else {
                    _selectedTransactionIds.remove(t.id);
                  }
                });
              },
              activeColor: AppColors.primaryBlue,
            ),
            const SizedBox(width: 8),
          ],
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.12), color.withOpacity(0.06)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.12)),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.description?.isNotEmpty == true
                      ? t.description!
                      : (isTransfer ? "Transfer" : "Transaction"),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    categoryLabel,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$sign₹${t.amount.toStringAsFixed(0)}",
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (_isSelectionMode) {
      return GestureDetector(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedTransactionIds.remove(t.id);
            } else {
              _selectedTransactionIds.add(t.id);
            }
          });
        },
        child: tile,
      );
    } else {
      return SwipeToDelete(
        itemKey: ValueKey(t.id),
        itemId: t.id,
        itemName: "Transaction",
        onDelete: () => provider.deleteTransaction(t.id),
        child: GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ModernAddTransactionScreen(transaction: t),
            ),
          ),
          child: tile,
        ),
      );
    }
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    String label = DateFormat('MMM dd').format(date);
    if (_isSameDay(date, now)) {
      label = "Today";
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1))))
      label = "Yesterday";

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: AppColors.textTertiary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textTertiary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(text, style: TextStyle(color: AppColors.textTertiary)),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _BalanceStatus {
  final String label;
  final Color color;
  final IconData icon;
  final String message;

  const _BalanceStatus({
    required this.label,
    required this.color,
    required this.icon,
    required this.message,
  });
}
