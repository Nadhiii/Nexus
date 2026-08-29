// ignore_for_file: unused_element
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import '../../core/widgets/collapsible_fab.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/animated_number_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_animations.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/nexus_button.dart';
import '../../core/widgets/nexus_card.dart';
import '../../core/widgets/swipe_to_delete.dart';
import '../../core/models/transaction.dart';
import '../../core/providers/account_provider.dart';
import '../../core/providers/category_provider.dart';
import '../../core/providers/transaction_provider.dart';
import '../../core/widgets/total_balance_card.dart';
import '../accounts/add_account_screen.dart';
import '../accounts/account_detail_screen.dart';
import '../transactions/add_transaction_screen.dart';
import '../../core/utils/transaction_display.dart';
import '../../core/utils/logo_utils.dart';

enum WalletView { accounts, history }

class ModernFinanceScreen extends StatefulWidget {
  final int initialTabIndex;
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
    _applyInitialTab(widget.initialTabIndex);
  }

  @override
  void didUpdateWidget(covariant ModernFinanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabIndex != widget.initialTabIndex) {
      _applyInitialTab(widget.initialTabIndex);
    }
  }

  void _applyInitialTab(int tabIndex) {
    _currentView = tabIndex == 1 ? WalletView.history : WalletView.accounts;
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
    if (_selectedTransactionIds.isEmpty) {
      return;
    }

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
              NexusCard(
                variant: NexusCardVariant.error,
                padding: AppSpacing.cardPaddingMd,
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
                      child: NexusButton(
                        width: double.infinity,
                        onPressed: () => Navigator.pop(context, false),
                        label: 'Cancel',
                        variant: NexusButtonVariant.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: NexusButton(
                        width: double.infinity,
                        onPressed: () => Navigator.pop(context, true),
                        label: 'Delete',
                        variant: NexusButtonVariant.destructive,
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              SliverAppBar(
                pinned: true,
                expandedHeight: 110,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
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
                      titlePadding: const EdgeInsets.only(left: AppSpacing.xl, bottom: AppSpacing.xl2),
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

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOutCubic,
                    alignment: Alignment.topCenter,
                    child: _buildTotalCashCard(
                      totalCash,
                      accountProvider.accounts.length,
                      monthExpense,
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: _buildViewToggle(),
                ),
              ),

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
          final destination = _currentView == WalletView.accounts
              ? const ModernAddAccountScreen()
              : const ModernAddTransactionScreen();
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  destination,
              transitionDuration: AppAnimations.pageTransitionDuration,
              reverseTransitionDuration: AppAnimations.pageTransitionDuration,
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) =>
                      SharedAxisTransition(
                        animation: animation,
                        secondaryAnimation: secondaryAnimation,
                        transitionType: SharedAxisTransitionType.vertical,
                        child: child,
                      ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildTotalCashCard(double total, int count, double monthExpense) {
    return const TotalBalanceCard();
  }

  Widget _buildEmptyStateWithAction(
    BuildContext context,
    String text,
    IconData icon,
    String actionLabel,
    VoidCallback onPressed,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppColors.textTertiary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(text, style: TextStyle(color: AppColors.textTertiary)),
          const SizedBox(height: AppSpacing.xl2),
          NexusButton(
            icon: Icon(icon, size: AppSpacing.iconSm),
            label: actionLabel,
            variant: NexusButtonVariant.primary,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppColors.textTertiary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(text, style: TextStyle(color: AppColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Row(
      children: [
        _buildPill("Accounts", WalletView.accounts),
        const SizedBox(width: AppSpacing.md),
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : AppColors.cardSurface,
          borderRadius: AppSpacing.borderRadiusFull,
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
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
    return amount < 0 ? '-Γé╣$absFormatted' : 'Γé╣$absFormatted';
  }

  Widget _buildAccountsList(BuildContext context, AccountProvider provider) {
    if (provider.isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (provider.accounts.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyStateWithAction(
          context,
          "No Accounts Linked",
          Icons.account_balance,
          "Add Account",
          () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ModernAddAccountScreen(),
            ),
          ),
        ),
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
        child: _buildEmptyStateWithAction(
          context,
          "No Recent Activity",
          Icons.receipt,
          "Log Transaction",
          () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ModernAddTransactionScreen(),
            ),
          ),
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
      child: NexusCard(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(color: account.color.withValues(alpha: 0.24)),
        padding: AppSpacing.cardPadding,
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
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs / 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs / 2,
                    ),
                    decoration: BoxDecoration(
                      color: account.color.withValues(alpha: 0.1),
                      borderRadius: AppSpacing.borderRadiusXs,
                    ),
                    child: Text(
                      account.typeDisplayName,
                      style: AppTypography.labelSmall.copyWith(color: account.color),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                Text(
                  "Γé╣${account.balance.toStringAsFixed(0)}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: AppTypography.titleLarge.fontSize,
                    fontWeight: AppTypography.titleLarge.fontWeight,
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
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      account.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: AppTypography.labelSmall.fontSize,
                      ),
                    ),
                  ],
                ),
                ],
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
        ? Theme.of(context).colorScheme.primary
        : (isIncome ? AppColors.success : AppColors.error);
    final icon = isTransfer
        ? Icons.swap_horiz
        : (isIncome ? Icons.arrow_downward : Icons.arrow_upward);
    final sign = isIncome ? "+" : (isTransfer ? "" : "-");

    Widget tile = Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xs + 2),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: _isSelectionMode && isSelected
            ? LinearGradient(
                colors: [
                  AppColors.primaryBlue.withValues(alpha: 0.12),
                  AppColors.primaryBlue.withValues(alpha: 0.06),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withValues(alpha: 0.05), Theme.of(context).colorScheme.surfaceContainerHighest],
              ),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: _isSelectionMode && isSelected
              ? AppColors.primaryBlue
              : color.withValues(alpha: 0.08),
          width: _isSelectionMode && isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.03),
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
            const SizedBox(width: AppSpacing.sm),
          ],
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.12),
                  color.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: AppSpacing.borderRadiusSm,
              border: Border.all(color: color.withValues(alpha: 0.12)),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.description?.isNotEmpty == true
                      ? t.description!
                      : (isTransfer ? "Transfer" : "Transaction"),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleSmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.borderRadiusXs,
                  ),
                  child: Text(
                    categoryLabel,
                    style: TextStyle(
                      color: color,
                      fontSize: AppTypography.labelSmall.fontSize,
                      fontWeight: AppTypography.labelSmall.fontWeight,
                    ),
                  ),
                ),
                if (t.metadata?['source'] == 'nexus_tasks')
                  Container(
                    margin: const EdgeInsets.only(top: AppSpacing.xs),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: AppSpacing.borderRadiusXs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 9,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'via Tasks',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: AppTypography.labelSmall.fontSize,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                "$signΓé╣${t.amount.toStringAsFixed(0)}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: AppTypography.titleMedium.fontSize,
                ),
                ),
                ],
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
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      label = "Yesterday";
    }

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

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _WalletFlipCard extends StatefulWidget {
  final double total;
  final int count;
  final double monthExpense;
  final _BalanceStatus Function(double, double) resolveStatus;
  final String Function(double) formatCurrency;

  const _WalletFlipCard({
    required this.total,
    required this.count,
    required this.monthExpense,
    required this.resolveStatus,
    required this.formatCurrency,
  });

  @override
  State<_WalletFlipCard> createState() => _WalletFlipCardState();
}

class _WalletFlipCardState extends State<_WalletFlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.ultra,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.backdropCurve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() => _isFront = !_isFront);
  }

  String _getExplanation(String message) {
    switch (message) {
      case 'In the red right now':
        return 'Your balance is negative or zero compared to your monthly expenses. Consider reducing expenses or transferring funds.';
      case 'Watch your wallet':
        return 'Your balance covers less than half a month of expenses. Be cautious with spending.';
      case 'Chill till next paycheck':
        return 'Your balance will last until your next paycheck, but keep an eye on your spending.';
      case 'You\'re good for a month':
        return 'You have enough to cover a full month of expenses. Nice work!';
      case 'You\'re golden for a few months':
        return 'You have a healthy buffer for several months. Keep it up!';
      case 'You\'re set for life (almost)':
        return 'You have a very strong financial cushion. Enjoy the peace of mind!';
      case 'No spend data yet':
        return 'We don\'t have enough data on your monthly expenses to calculate your runway.';
      default:
        if (message.startsWith('Chill for ~')) {
          return 'You have enough to cover about ${message.replaceAll(RegExp(r'[^0-9\.]'), '')} months of expenses.';
        }
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.resolveStatus(widget.total, widget.monthExpense);
    final formattedTotal = widget.formatCurrency(widget.total);
    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * 3.1416;
          final isBack = _animation.value >= 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: isBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(3.1416),
                    child: _buildBack(context, status),
                  )
                : _buildFront(context, formattedTotal, status, widget.count),
          );
        },
      ),
    );
  }

  Widget _buildFront(
    BuildContext context,
    String formattedTotal,
    _BalanceStatus status,
    int count,
  ) {
    final isNegative = widget.total < 0;
    final gradientColors = isNegative
        ? AppColors.netWorthNegativeGradient
        : AppColors.netWorthPositiveGradient;
    final borderColor = Colors.white.withValues(alpha: 0.1);
    final boxShadowColor = Colors.black.withValues(alpha: 0.4);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: boxShadowColor,
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
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(status.icon, color: status.color, size: 11),
                    const SizedBox(width: 3),
                    Text(
                      status.label,
                      style: TextStyle(
                        color: status.color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedNumberText(
            number: widget.total,
            prefix: 'Γé╣',
            style: AppTypography.displaySmall.copyWith(
              color: Colors.white,
              fontSize: 36,
            ),
            decimalPlaces: 2,
          ),
          const SizedBox(height: 6),
          Text(
            status.message,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
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
                '${widget.count} Accounts',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerRight,
            child: Icon(Icons.flip, color: Colors.white38, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildBack(BuildContext context, _BalanceStatus status) {
    final message = status.message;
    final explanation = _getExplanation(message);
    final isNegative = widget.total < 0;
    final gradientColors = isNegative
        ? AppColors.netWorthNegativeGradient
        : AppColors.netWorthPositiveGradient;
    final borderColor = Colors.white.withValues(alpha: 0.1);
    final boxShadowColor = Colors.black.withValues(alpha: 0.4);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: boxShadowColor,
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(status.icon, color: status.color, size: 36),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (explanation.isNotEmpty)
            Text(
              explanation,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
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
