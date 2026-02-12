import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Providers
import '../../core/providers/notification_provider.dart';
import '../../core/providers/transaction_provider.dart';
import '../../core/providers/account_provider.dart';
import '../../core/providers/bike_provider.dart';

// Theme & Widgets
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/swipe_to_delete.dart';
import '../../core/widgets/financial_health_widget.dart';
import '../../core/widgets/upcoming_week_widget.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/account.dart';
import '../../core/models/transaction.dart';

// Screens & Components
import '../transactions/modern_add_transaction_screen.dart';
import '../notifications/modern_notifications_screen.dart';

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
    _recalcDebounce = Timer(const Duration(milliseconds: 500), () {
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
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) setState(() {});
        },
        child: CustomScrollView(
          slivers: [
            // 1. GOLDEN HEADER
            _buildModernAppBar(context),

            // Recalc Listener (Invisible)
            SliverToBoxAdapter(
              child: Consumer<TransactionProvider>(
                builder: (context, txProvider, _) {
                  _scheduleRecalc();
                  return const SizedBox.shrink();
                },
              ),
            ),

            // 2. TOTAL BALANCE CARD
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
                    return _buildPremiumBalanceCard(totalBalance);
                  },
                ),
              ),
            ),

            // 3. QUICK ACTIONS
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionBtn(
                        Icons.add,
                        'Add',
                        AppColors.primaryBlue,
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const ModernAddTransactionScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionBtn(
                        Icons.account_balance_wallet_outlined,
                        'Accounts',
                        AppColors.pastelPurple,
                        () => widget.onNavigate(1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionBtn(
                        Icons.history,
                        'History',
                        AppColors.pastelTeal,
                        () => widget.onNavigate(1, financeTab: 1),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. FINANCIAL HEALTH SCORE
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: FinancialHealthWidget(
                  onTap: () => widget.onNavigate(1, financeTab: 2),
                ),
              ),
            ),

            // 4b. UPCOMING WEEK PREVIEW
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: UpcomingWeekWidget(
                  onViewAll: () => widget.onNavigate(1, financeTab: 2),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // 5. GARAGE SECTION (New "Status" Card)
            SliverToBoxAdapter(
              child: Consumer<BikeProvider>(
                builder: (context, bikeProvider, _) {
                  if (bikeProvider.bikes.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final bike =
                      bikeProvider.getDashboardBike() ??
                      bikeProvider.bikes.first;
                  final mileage = bikeProvider.getReliableAverageMileage();

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("MY VEHICLE", style: _headerStyle()),
                        const SizedBox(height: 12),
                        _buildVehicleStatusCard(bike, mileage),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // 6. RECENT ACTIVITY HEADER
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

            // 6. TRANSACTION STREAM
            _buildRecentTransactionsList(),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  TextStyle _headerStyle() {
    return AppTypography.labelSmall.copyWith(
      color: AppColors.textTertiary,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.2,
    );
  }

  Widget _buildPremiumBalanceCard(double balance) {
    final isPositive = balance > 0; // Only positive if actually has money
    final isEmpty = balance == 0;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPositive
              ? AppColors.netWorthPositiveGradient
              : AppColors.netWorthNegativeGradient,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
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
                'TOTAL BALANCE',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isEmpty
                          ? Icons.remove
                          : (isPositive
                                ? Icons.trending_up
                                : Icons.trending_down),
                      color: isEmpty
                          ? Colors.white54
                          : (isPositive ? AppColors.success : AppColors.error),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isEmpty ? 'Empty' : (isPositive ? 'Healthy' : 'Low'),
                      style: TextStyle(
                        color: isEmpty
                            ? Colors.white54
                            : (isPositive
                                  ? AppColors.success
                                  : AppColors.error),
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
            '₹${balance.toStringAsFixed(2)}',
            style: AppTypography.displaySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 36,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Available across all accounts',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Sleek Vehicle Status Card (Replaces heavy RC Card)
  Widget _buildVehicleStatusCard(dynamic bike, double mileage) {
    return GestureDetector(
      onTap: () => widget.onNavigate(3), // Navigate to Garage Tab
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryBlue.withOpacity(0.15),
              AppColors.cardSurface,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon / Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryBlue.withOpacity(0.3),
                    AppColors.primaryBlue.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryBlue.withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.two_wheeler,
                color: AppColors.primaryBlue,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bike.name,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.success.withOpacity(0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Active",
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Mileage Stat
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.pastelTeal.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    mileage.toStringAsFixed(1),
                    style: TextStyle(
                      color: AppColors.pastelTeal,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    "km/L",
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.15), AppColors.cardSurface],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsList() {
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

        final recentTransactions = provider.transactions.take(5).toList();

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

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final transaction = recentTransactions[index];
            final isLast = index == recentTransactions.length - 1;
            return _buildTimelineItem(transaction, isLast);
          }, childCount: recentTransactions.length),
        );
      },
    );
  }

  // --- NBOX STYLE STREAM ITEM ---
  Widget _buildTimelineItem(Transaction t, bool isLast) {
    final isIncome = t.type == TransactionType.income;
    final isTransfer = t.type == TransactionType.transfer;

    final color = isTransfer
        ? AppColors.primaryBlue
        : (isIncome ? AppColors.pastelGreen : AppColors.error);

    final icon = isTransfer
        ? Icons.swap_horiz
        : (isIncome ? Icons.arrow_downward : Icons.arrow_upward);

    final sign = isIncome ? "+" : (isTransfer ? "" : "-");

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A. Timeline Graphic
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 16),
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundBlack,
                    border: Border.all(color: color, width: 2),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : AppColors.cardSurface,
                  ),
                ),
              ],
            ),
          ),

          // B. Content Bubble
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24, right: 20),
              child: SwipeToDelete(
                itemKey: ValueKey(t.id),
                itemId: t.id,
                itemName: "Transaction",
                onDelete: () =>
                    context.read<TransactionProvider>().deleteTransaction(t.id),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            ModernAddTransactionScreen(transaction: t),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              // Glass Icon
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: color, size: 16),
                              ),
                              const SizedBox(width: 12),
                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.description?.isNotEmpty == true
                                          ? t.description!
                                          : (isTransfer
                                                ? "Transfer"
                                                : "Transaction"),
                                      style: AppTypography.bodyLarge.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    // NEW: Pretty Date Format
                                    Text(
                                      _formatPrettyDate(t.date),
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Amount
                        Text(
                          "$sign₹${t.amount.toStringAsFixed(0)}",
                          style: AppTypography.titleMedium.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.split(' ').first ?? 'User';

    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: AppColors.backgroundBlack,
      surfaceTintColor: AppColors.backgroundBlack,
      elevation: 0,
      expandedHeight: 110, // STANDARD HEIGHT
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(
          left: 20,
          bottom: 24,
        ), // STANDARD PADDING
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

  // NEW: Smart Date Formatter (4th Dec, 1st Jan)
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
    } else if (date.day % 10 == 2 && date.day != 12)
      suffix = 'nd';
    else if (date.day % 10 == 3 && date.day != 13)
      suffix = 'rd';

    return "${date.day}$suffix ${DateFormat('MMM').format(date)}";
  }
}
