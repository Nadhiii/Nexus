import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/providers/transaction_provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/modern/modern_widgets.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/account.dart';
import '../../core/models/transaction.dart';
import '../transactions/modern_add_transaction_screen.dart';
import '../notifications/modern_notifications_screen.dart';

class ModernDashboardScreen extends StatefulWidget {
  final Function(int, {int? financeTab}) onNavigate;

  const ModernDashboardScreen({super.key, required this.onNavigate});

  @override
  State<ModernDashboardScreen> createState() => _ModernDashboardScreenState();
}

class _ModernDashboardScreenState extends State<ModernDashboardScreen> {
  final _greetings = [
    'Hi',
    'Hello',
    'Welcome',
    'ನಮಸ್ಕಾರ', // Kannada
    'नमस्ते', // Hindi
  ];

  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Rotate greeting every 2.5 seconds
    _timer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _greetings.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: AppColors.darkGradient.first,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
          // Trigger a refresh if needed
          setState(() {});
        },
        child: CustomScrollView(
          slivers: [
            _buildModernAppBar(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.lg,
                ),
                child: StreamBuilder<List<Account>>(
                  stream: FirestoreService.getAccountsStream(),
                  builder: (context, snapshot) {
                    double totalBalance = 0.0;
                    int accountCount = 0;

                    if (snapshot.hasData && snapshot.data != null) {
                      final accounts = snapshot.data!
                          .where((a) => a.isActive)
                          .toList();
                      totalBalance = accounts.fold(
                        0.0,
                        (sum, account) => sum + account.balance,
                      );
                      accountCount = accounts.length;
                    }

                    return ModernBalanceCard(
                      title: 'Total Balance',
                      amount: totalBalance,
                      currency: '₹',
                      subtitle:
                          'Personal · $accountCount ${accountCount == 1 ? 'account' : 'accounts'}',
                      gradientColors: [
                        colorScheme.primary,
                        colorScheme.primary.withOpacity(0.8),
                      ],
                      trailing: GestureDetector(
                        onTap: () {
                          widget.onNavigate(1);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.onPrimary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusFull,
                            ),
                          ),
                          child: Text(
                            'Accounts',
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ModernActionButton(
                      icon: Icons.add_circle_outline,
                      label: 'Add\nTransaction',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const ModernAddTransactionScreen(),
                          ),
                        );
                      },
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                    ModernActionButton(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Accounts',
                      onTap: () {
                        widget.onNavigate(1);
                      },
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                    ModernActionButton(
                      icon: Icons.receipt_long_outlined,
                      label: 'Transactions',
                      onTap: () {
                        widget.onNavigate(1, financeTab: 1);
                      },
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl2)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.md,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Transactions',
                      style: AppTypography.titleLarge.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        widget.onNavigate(1, financeTab: 1);
                      },
                      child: Text(
                        'View All',
                        style: AppTypography.bodyMedium.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            StreamBuilder<List<Transaction>>(
              stream: FirestoreService.getTransactionsStream(limit: 5),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      padding: AppSpacing.cardPaddingLg,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                        border: Border.all(
                          color: colorScheme.onSurface.withOpacity(0.1),
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 48,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'No transactions yet',
                              style: AppTypography.bodyLarge.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Add your first transaction to get started',
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
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final transaction = snapshot.data![index];
                    return Padding(
                      padding: EdgeInsets.only(
                        left: AppSpacing.xl,
                        right: AppSpacing.xl,
                        bottom: index == snapshot.data!.length - 1
                            ? 0
                            : AppSpacing.sm,
                      ),
                      child: Dismissible(
                        key: ValueKey(transaction.id),
                        direction: DismissDirection.startToEnd,
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor: AppColors.cardDark,
                                title: Text(
                                  'Delete Transaction',
                                  style: AppTypography.titleLarge.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                content: Text(
                                  'Are you sure you want to delete this transaction?',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(color: AppColors.error),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        onDismissed: (direction) async {
                          await context
                              .read<TransactionProvider>()
                              .deleteTransaction(transaction.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Transaction deleted'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusLg,
                            ),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: ModernTransactionTile(
                          title: transaction.description ?? 'Transaction',
                          subtitle: _formatTransactionDate(transaction.date),
                          amount: '₹${transaction.amount.toStringAsFixed(2)}',
                          isIncome: transaction.type == TransactionType.income,
                          icon: transaction.type == TransactionType.income
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
                  }, childCount: snapshot.data!.length),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.split(' ').first ?? 'User';

    // Get the current greeting
    final currentGreeting = _greetings[_currentIndex];

    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: AppColors.darkGradient.first,
      foregroundColor: Colors.white,

      // 1. Profile Icon & Greeting
      title: Row(
        children: [
          GestureDetector(
            onTap: () => widget.onNavigate(4),
            child: CircleAvatar(
              radius: 18, // Slightly smaller
              backgroundColor: colorScheme.primary,
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? Icon(
                      user?.isAnonymous == true
                          ? Icons.person_off
                          : Icons.person,
                      color: colorScheme.onPrimary,
                      size: 18,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (Widget child, Animation<double> animation) {
                final offsetAnimation = Tween<Offset>(
                  begin: const Offset(0.0, 0.5),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  ),
                );
              },
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: <Widget>[
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              child: Text(
                '$currentGreeting, $displayName',
                key: ValueKey<String>(currentGreeting),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.headlineSmall.copyWith(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  fontFamilyFallback: const ['Roboto', 'Arial'],
                ),
              ),
            ),
          ),
        ],
      ),
      titleSpacing: AppSpacing.lg, // Use consistent spacing
      // 2. Action (Notification only)
      actions: [
        Consumer<NotificationProvider>(
          builder: (context, notificationProvider, child) {
            return Badge(
              isLabelVisible: notificationProvider.hasUnread,
              child: IconButton(
                icon: Icon(
                  Icons.notifications_none,
                  color: Colors.white, // Ensure icon is always visible
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ModernNotificationsScreen(),
                    ),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(width: AppSpacing.md), // Right padding
      ],
    );
  }

  String _formatTransactionDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
