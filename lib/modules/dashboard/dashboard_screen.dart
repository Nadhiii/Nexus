import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_animations.dart';

// Providers
import '../../core/providers/notification_provider.dart';
import '../../core/providers/transaction_provider.dart';
import '../../core/providers/account_provider.dart';
import '../../core/providers/bike_provider.dart';

// Theme & Widgets
import '../../core/theme/app_typography.dart';
import '../../core/widgets/animated_number_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/account.dart';
import '../../core/models/transaction.dart';

// Screens
import '../transactions/add_transaction_screen.dart';
import '../notifications/notifications_screen.dart';

class ModernDashboardScreen extends StatefulWidget {
  final Function(int, {int? financeTab}) onNavigate;

  const ModernDashboardScreen({super.key, required this.onNavigate});

  @override
  State<ModernDashboardScreen> createState() => _ModernDashboardScreenState();
}

class _ModernDashboardScreenState extends State<ModernDashboardScreen> {
  bool _hasRecalculated = false;
  Timer? _recalcDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasRecalculated && mounted) {
        _recalculateAllBalances();
        _hasRecalculated = true;
      }
    });
  }

  void _scheduleRecalc() {
    _recalcDebounce?.cancel();
    _recalcDebounce = Timer(AppAnimations.verySlow, () {
      if (mounted) _recalculateAllBalances();
    });
  }

  Future<void> _recalculateAllBalances() async {
    try {
      final transactionProvider = context.read<TransactionProvider>();
      final accountProvider = context.read<AccountProvider>();
      if (accountProvider.accounts.isEmpty) return;
      for (final account in accountProvider.accounts) {
        await transactionProvider.recalculateAccountBalance(account.id);
      }
    } catch (e) {
      debugPrint('Error recalculating balances: $e');
    }
  }

  @override
  void dispose() {
    _recalcDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: RefreshIndicator(
        color: AppColors.primaryBlue,
        backgroundColor: AppColors.cardSurface,
        onRefresh: () async {
          _recalculateAllBalances();
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) setState(() {});
        },
        child: CustomScrollView(
          slivers: [
            // 1. HEADER
            _buildModernAppBar(context),

            // Recalc Listener (invisible)
            SliverToBoxAdapter(
              child: Consumer<TransactionProvider>(
                builder: (context, txProvider, _) {
                  _scheduleRecalc();
                  return const SizedBox.shrink();
                },
              ),
            ),

            // 2. COMPACT BALANCE CARD
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: StreamBuilder<List<Account>>(
                  stream: FirestoreService.getAccountsStream(),
                  builder: (context, snapshot) {
                    double totalBalance = 0.0;
                    if (snapshot.hasData && snapshot.data != null) {
                      final accounts = snapshot.data!
                          .where((a) => a.isActive)
                          .toList();
                      totalBalance = accounts.fold(
                        0.0,
                        (sum, account) => sum + account.balance,
                      );
                    }
                    return _buildCompactBalanceCard(totalBalance);
                  },
                ),
              ),
            ),

            // 3. STREAMLINED ACTION BAR
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: _buildActionBar(),
              ),
            ),

            // 4. GARAGE WIDGET
            SliverToBoxAdapter(
              child: Consumer<BikeProvider>(
                builder: (context, bikeProvider, _) {
                  if (bikeProvider.bikes.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 0,
                    ),
                    child: _buildGarageWidget(bikeProvider),
                  );
                },
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // 6. RECENT ACTIVITY
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("RECENT ACTIVITY", style: _headerStyle()),
                    GestureDetector(
                      onTap: () => widget.onNavigate(1, financeTab: 1),
                      child: Text(
                        "See All",
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            _buildCleanRecentList(),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────

  TextStyle _headerStyle() {
    return AppTypography.labelSmall.copyWith(
      color: AppColors.textTertiary,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.2,
    );
  }

  // ──────────────────────────────────────────────
  // 1. COMPACT BALANCE CARD
  // ──────────────────────────────────────────────

  Widget _buildCompactBalanceCard(double balance) {
    final isPositive = balance > 0;

    // Monthly cash flow
    final txProvider = context.watch<TransactionProvider>();
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthTxns = txProvider.transactions
        .where((t) => t.date.isAfter(monthStart))
        .toList();
    final monthIncome = monthTxns
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final monthExpense = monthTxns
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    final status = _resolveBalanceStatus(balance, monthExpense);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPositive
              ? AppColors.netWorthPositiveGradient
              : AppColors.netWorthNegativeGradient,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Label + Status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL BALANCE',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 10,
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
          const SizedBox(height: 8),

          // Balance amount
          AnimatedNumberText(
            number: balance,
            decimalPlaces: 2,
            prefix: '₹',
            style: AppTypography.currencyLarge,
          ),
          const SizedBox(height: 12),

          Text(
            status.message,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),

          // Cash flow row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Income
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_downward,
                          color: AppColors.success,
                          size: 10,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Income',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '₹${_formatCompactAmount(monthIncome)}',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.white.withOpacity(0.1),
                ),
                const SizedBox(width: 8),
                // Expense
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Expense',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '₹${_formatCompactAmount(monthExpense)}',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_upward,
                          color: AppColors.error,
                          size: 10,
                        ),
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

  // ──────────────────────────────────────────────
  // 2. STREAMLINED ACTION BAR
  // ──────────────────────────────────────────────

  Widget _buildActionBar() {
    return _buildActionIcon(
      Icons.add_rounded,
      'Add',
      AppColors.primaryBlue,
      () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const ModernAddTransactionScreen(),
        ),
      ),
    );
  }

  Widget _buildActionIcon(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // GARAGE WIDGET
  // ──────────────────────────────────────────────

  Widget _buildGarageWidget(BikeProvider bikeProvider) {
    final bike = bikeProvider.getDashboardBike() ?? bikeProvider.bikes.first;
    final mileage = bikeProvider.getReliableAverageMileage();
    final totalSpent = bikeProvider.getTotalFuelCost();
    final totalKm = bikeProvider.getKmTraveled();
    final fillups = bikeProvider.getTotalFillups();

    return GestureDetector(
      onTap: () => widget.onNavigate(3),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.two_wheeler,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bike.name,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '$fillups fill-ups · ${totalKm.toStringAsFixed(0)} km',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Stats row
            Row(
              children: [
                // Average Mileage
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.pastelTeal.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AVG MILEAGE',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              mileage > 0 ? mileage.toStringAsFixed(1) : '--',
                              style: TextStyle(
                                color: AppColors.pastelTeal,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(
                                'km/L',
                                style: TextStyle(
                                  color: AppColors.pastelTeal.withOpacity(0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Total Spent
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.pastelOrange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL SPENT',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          totalSpent > 0
                              ? '₹${_formatCompactAmount(totalSpent)}'
                              : '--',
                          style: TextStyle(
                            color: AppColors.pastelOrange,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // 4. CLEAN RECENT LIST (3 items, no timeline)
  // ──────────────────────────────────────────────

  Widget _buildCleanRecentList() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.transactions.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final recentTransactions = provider.transactions.take(3).toList();

        if (recentTransactions.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'No transactions yet',
                    style: TextStyle(color: AppColors.textTertiary),
                  ),
                ),
              ),
            ),
          );
        }

        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < recentTransactions.length; i++) ...[
                    _buildCleanTransactionItem(recentTransactions[i]),
                    if (i < recentTransactions.length - 1)
                      Divider(
                        height: 1,
                        color: Colors.white.withOpacity(0.05),
                        indent: 56,
                        endIndent: 16,
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCleanTransactionItem(Transaction t) {
    final isIncome = t.type == TransactionType.income;
    final isTransfer = t.type == TransactionType.transfer;

    final color = isTransfer
        ? AppColors.primaryBlue
        : (isIncome ? AppColors.pastelGreen : AppColors.error);

    final icon = isTransfer
        ? Icons.swap_horiz
        : (isIncome ? Icons.arrow_downward : Icons.arrow_upward);

    final sign = isIncome ? "+" : (isTransfer ? "" : "-");

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ModernAddTransactionScreen(transaction: t),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.description?.isNotEmpty == true
                        ? t.description!
                        : (isTransfer ? "Transfer" : "Transaction"),
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatPrettyDate(t.date),
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              "$sign₹${t.amount.toStringAsFixed(0)}",
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // APP BAR
  // ──────────────────────────────────────────────

  Widget _buildModernAppBar(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.split(' ').first ?? 'User';

    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: AppColors.backgroundBlack,
      surfaceTintColor: AppColors.backgroundBlack,
      elevation: 0,
      expandedHeight: 110,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 24),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Good ${DateTime.now().hour < 12
                  ? 'Morning'
                  : DateTime.now().hour < 17
                  ? 'Afternoon'
                  : 'Evening'},',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              displayName,
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20, top: 10),
          child: Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const ModernNotificationsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  if (notificationProvider.hasUnread)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.pastelPink,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  // FORMATTERS
  // ──────────────────────────────────────────────

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

  String _formatIndianNumber(double amount) {
    if (amount == 0) return '0.00';
    final isNegative = amount < 0;
    final abs = amount.abs();

    String formatted;
    if (abs >= 10000000) {
      formatted = '${(abs / 10000000).toStringAsFixed(2)} Cr';
    } else if (abs >= 100000) {
      formatted = '${(abs / 100000).toStringAsFixed(2)} L';
    } else {
      formatted = NumberFormat('#,##,##0.00', 'en_IN').format(abs);
    }
    return isNegative ? '-$formatted' : formatted;
  }

  String _formatCompactAmount(double amount) {
    if (amount.abs() >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount.abs() >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount.abs() >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  String _formatPrettyDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0 && now.day == date.day) return 'Today';
    if (difference.inDays == 1 ||
        (difference.inDays == 0 && now.day != date.day)) {
      return 'Yesterday';
    }

    String suffix = 'th';
    if (date.day % 10 == 1 && date.day != 11) {
      suffix = 'st';
    } else if (date.day % 10 == 2 && date.day != 12) {
      suffix = 'nd';
    } else if (date.day % 10 == 3 && date.day != 13) {
      suffix = 'rd';
    }

    return "${date.day}$suffix ${DateFormat('MMM').format(date)}";
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
