import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/swipe_to_delete.dart';
import '../../core/models/transaction.dart';
import '../../core/providers/account_provider.dart';
import '../../core/providers/transaction_provider.dart';
import '../accounts/modern_add_account_screen.dart';
import '../accounts/modern_account_detail_screen.dart';
import '../transactions/modern_add_transaction_screen.dart';
import '../pdf_import/pdf_import_screen.dart';

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
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: Text(
          'Delete ${_selectedTransactionIds.length} Transaction(s)?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
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
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 24),
                  title: _isSelectionMode
                      ? Text(
                          '${_selectedTransactionIds.length} selected',
                          style: AppTypography.headlineMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : Text(
                          'Wallet',
                          style: AppTypography.headlineMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton.extended(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => _currentView == WalletView.accounts
                    ? const ModernAddAccountScreen()
                    : const ModernAddTransactionScreen(),
              ),
            );
          },
          icon: Icon(
            _currentView == WalletView.accounts
                ? Icons.account_balance_wallet
                : Icons.receipt_long,
          ),
          label: Text(
            _currentView == WalletView.accounts
                ? 'Add Account'
                : 'Log Transaction',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCashCard(double total, int count) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade900.withOpacity(0.8),
            const Color(0xFF1E3A8A), // Dark Blue
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
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
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count Accounts',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${NumberFormat('#,##,###').format(total)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
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
        duration: const Duration(milliseconds: 200),
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
              confirmTitle: 'Delete Account?',
              confirmMessage: 'This will delete all linked transactions.',
              onDelete: () => provider.deleteAccount(account.id),
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
          children: [
            _buildEmptyState("No Recent Activity", Icons.receipt),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PDFImportScreen(),
                  ),
                ),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Import from PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final transactions = List<Transaction>.from(provider.transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 200),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          // Add PDF import button at the top
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PDFImportScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Import from PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            );
          }

          // Adjust index for transactions list
          final txnIndex = index - 1;
          final t = transactions[txnIndex];
          final showHeader =
              txnIndex == 0 ||
              !_isSameDay(t.date, transactions[txnIndex - 1].date);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showHeader) _buildDateHeader(t.date),
              _buildTransactionTile(context, t, provider),
            ],
          );
        }, childCount: transactions.length + 1), // +1 for the PDF button
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, dynamic account) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ModernAccountDetailScreen(account: account),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: account.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(account.icon, color: account.color, size: 24),
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
                  Text(
                    account.typeDisplayName,
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              "₹${account.balance.toStringAsFixed(0)}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
        color: _isSelectionMode && isSelected
            ? AppColors.primaryBlue.withOpacity(0.2)
            : AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isSelectionMode && isSelected
              ? AppColors.primaryBlue
              : Colors.white.withOpacity(0.05),
          width: _isSelectionMode && isSelected ? 2 : 1,
        ),
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
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
                Text(
                  t.categoryId ?? "General",
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            "$sign₹${t.amount.toStringAsFixed(0)}",
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
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
