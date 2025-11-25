import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/modern/modern_widgets.dart';
import '../../core/models/account.dart';
import '../../core/models/transaction.dart';
import '../../core/providers/transaction_provider.dart';
import '../transactions/modern_add_transaction_screen.dart';
import 'modern_add_account_screen.dart';

/// Modern Account Detail Screen - Revolut-inspired design
/// Features: Gradient background, modern cards, transaction list, clean layout
class ModernAccountDetailScreen extends StatefulWidget {
  final Account account;

  const ModernAccountDetailScreen({super.key, required this.account});

  @override
  State<ModernAccountDetailScreen> createState() =>
      _ModernAccountDetailScreenState();
}

class _ModernAccountDetailScreenState extends State<ModernAccountDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TransactionProvider>();
      // Force refresh to ensure transactions are loaded
      provider.loadTransactions();
    });
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
                // App Bar
                _buildAppBar(context),

                // Content
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      // Account Balance Card
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.xl,
                            AppSpacing.lg,
                            AppSpacing.xl,
                            AppSpacing.xl,
                          ),
                          child: ModernBalanceCard(
                            title: widget.account.name,
                            amount: widget.account.balance,
                            currency: '₹',
                            subtitle: widget.account.typeDisplayName,
                            gradientColors: [
                              widget.account.color.withOpacity(0.8),
                              widget.account.color,
                            ],
                            trailing: Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.account.icon,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Account Info
                      if (widget.account.bankName != null ||
                          widget.account.accountNumber != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.xl,
                              0,
                              AppSpacing.xl,
                              AppSpacing.xl,
                            ),
                            child: Container(
                              padding: AppSpacing.cardPaddingMd,
                              decoration: BoxDecoration(
                                color: AppColors.cardDarkElevated,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusLg,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Account Details',
                                    style: AppTypography.titleSmall.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  if (widget.account.bankName != null) ...[
                                    _buildInfoRow(
                                      Icons.account_balance_outlined,
                                      'Bank',
                                      widget.account.bankName!,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                  ],
                                  if (widget.account.accountNumber != null) ...[
                                    _buildInfoRow(
                                      Icons.credit_card_outlined,
                                      'Account Number',
                                      '**** ${widget.account.accountNumber}',
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                  ],
                                  _buildInfoRow(
                                    Icons.category_outlined,
                                    'Type',
                                    widget.account.typeDisplayName,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Transactions Header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.xl,
                            AppSpacing.md,
                            AppSpacing.xl,
                            AppSpacing.md,
                          ),
                          child: Text(
                            'Recent Transactions',
                            style: AppTypography.titleLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // Transactions List
                      Consumer<TransactionProvider>(
                        builder: (context, provider, child) {
                          // Filter transactions for this account
                          final accountTransactions =
                              provider.transactions
                                  .where(
                                    (t) => t.accountId == widget.account.id,
                                  )
                                  .toList()
                                ..sort(
                                  (a, b) => b.date.compareTo(a.date),
                                ); // Sort by date descending

                          if (accountTransactions.isEmpty) {
                            return SliverToBoxAdapter(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xl,
                                ),
                                padding: AppSpacing.cardPaddingLg,
                                decoration: BoxDecoration(
                                  color: AppColors.cardDarkElevated,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusLg,
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.receipt_long_outlined,
                                        size: 48,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      Text(
                                        'No transactions yet',
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

                          return SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.xl,
                              0,
                              AppSpacing.xl,
                              120,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final transaction = accountTransactions[index];
                                final isIncome =
                                    transaction.type == TransactionType.income;
                                final amountText =
                                    '₹${transaction.amount.toStringAsFixed(2)}';

                                return Dismissible(
                                  key: ValueKey(transaction.id),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (direction) async {
                                    return await showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          backgroundColor: AppColors.cardDark,
                                          title: Text(
                                            'Delete Transaction',
                                            style: AppTypography.titleLarge
                                                .copyWith(
                                                  color: AppColors.textPrimary,
                                                ),
                                          ),
                                          content: Text(
                                            'Are you sure you want to delete this transaction?',
                                            style: AppTypography.bodyMedium
                                                .copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pop(false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pop(true),
                                              child: Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: AppColors.error,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  onDismissed: (direction) async {
                                    final provider = context
                                        .read<TransactionProvider>();
                                    await provider.deleteTransaction(
                                      transaction.id,
                                    );
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Transaction deleted',
                                          ),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    }
                                  },
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.lg,
                                    ),
                                    margin: EdgeInsets.only(
                                      bottom:
                                          index ==
                                              accountTransactions.length - 1
                                          ? 0
                                          : AppSpacing.sm,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusLg,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      bottom:
                                          index ==
                                              accountTransactions.length - 1
                                          ? 0
                                          : AppSpacing.sm,
                                    ),
                                    child: ModernTransactionTile(
                                      title:
                                          transaction.description ??
                                          'Transaction',
                                      subtitle: _formatTransactionDate(
                                        transaction.date,
                                      ),
                                      amount: amountText,
                                      isIncome: isIncome,
                                      icon: isIncome
                                          ? Icons.arrow_downward
                                          : Icons.arrow_upward,
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
                              }, childCount: accountTransactions.length),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addTransaction(),
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: _handleAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined),
                      SizedBox(width: 8),
                      Text('Edit Account'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: AppColors.error),
                      SizedBox(width: 8),
                      Text(
                        'Delete Account',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatTransactionDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _handleAction(String action) {
    switch (action) {
      case 'edit':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                ModernAddAccountScreen(accountToEdit: widget.account),
          ),
        );
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text(
          'Are you sure you want to delete "${widget.account.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement delete
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _addTransaction() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ModernAddTransactionScreen(
          accountId: widget.account.id,
          initialType: TransactionType.expense,
        ),
      ),
    );
    // Refresh transactions after returning
    if (mounted) {
      context.read<TransactionProvider>().loadTransactions();
    }
  }
}
