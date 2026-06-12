import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/transaction_provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/models/transaction.dart';
import '../../core/widgets/animated_list_item.dart';
import '../../core/widgets/spring_tap.dart';
import '../../core/widgets/total_balance_card.dart';
import '../../core/widgets/upcoming_week_widget.dart';
import '../../core/providers/user_provider.dart';
import '../bike/widgets/garage_dashboard_widget.dart';
import '../family/screens/expense_splitter_screen.dart';
import '../transactions/add_transaction_screen.dart';
import '../notifications/notifications_screen.dart';

class ModernDashboardScreen extends StatefulWidget {
  final void Function(int index, {int? financeTab})? onNavigate;

  const ModernDashboardScreen({super.key, this.onNavigate});

  @override
  State<ModernDashboardScreen> createState() => _ModernDashboardScreenState();
}

class _ModernDashboardScreenState extends State<ModernDashboardScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── 1. APP BAR ─────────────────────────────────────────────────
          _buildAppBar(),

          // ── 2. BALANCE CARD ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                0,
              ),
              child: const TotalBalanceCard(),
            ),
          ),

          // ── 3. ACTION BAR ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                0,
              ),
              child: _ActionBar(),
            ),
          ),

          // ── 4. UPCOMING WEEK ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                0,
              ),
              child: UpcomingWeekWidget(
                onViewAll: () {
                  // TODO: navigate to full bills/obligations screen
                },
              ),
            ),
          ),

          // ── 5. GARAGE WIDGET ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                0,
              ),
              child: GarageDashboardWidget(
                // Switch to the Garage tab (index 2 — adjust if different in your app)
                onOpenGarage: () => widget.onNavigate?.call(2), 
              ),
            ),
          ),

          // ── 6. RECENT ACTIVITY ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                0,
              ),
              child: _RecentActivitySection(),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.backgroundBlack,
      surfaceTintColor: AppColors.backgroundBlack,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: _GreetingTitle(),
      actions: [
        Consumer<NotificationProvider>(
          builder: (context, notifProvider, _) {
            final unread = notifProvider.unreadCount;
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ModernNotificationsScreen(),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.only(right: 20),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.white12,
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    if (unread > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              unread > 9 ? '9+' : '$unread',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Greeting
// ─────────────────────────────────────────────────────────────────────────────

class _GreetingTitle extends StatelessWidget {
  String _greetingByTime() {
    final hour = DateTime.now().hour;
    return hour < 12 ? 'Good morning,' : 'Good evening,';
  }

  String _resolveUserName(BuildContext context) {
    final providerName = context.watch<UserProvider>().user?.displayName ?? '';
    final authName = FirebaseAuth.instance.currentUser?.displayName ?? '';
    final candidate = providerName.trim().isNotEmpty
        ? providerName.trim()
        : authName.trim();
    return candidate.isNotEmpty ? candidate : 'User';
  }

  @override
  Widget build(BuildContext context) {
    final userName = _resolveUserName(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _greetingByTime(),
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        Text(
          userName,
          style: AppTypography.displayMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Bar
// ─────────────────────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            // Primary: Add Transaction
            Expanded(
              flex: 3,
              child: SpringTap(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ModernAddTransactionScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Add Transaction',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Secondary: Transfer
            Expanded(
              flex: 2,
              child: SpringTap(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ModernAddTransactionScreen(
                      initialType: TransactionType.transfer,
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.swap_horiz_rounded,
                          color: AppColors.textSecondary, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Transfer',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SpringTap(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ExpenseSplitterScreen()),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.call_split_rounded, color: AppColors.success, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Quick Split (No Save)',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent Activity
// ─────────────────────────────────────────────────────────────────────────────

class _RecentActivitySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, txProvider, _) {
        final recent = txProvider.transactions.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RECENT ACTIVITY',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Navigate to full transactions screen via bottom nav
                    // handled by parent scaffold tab switching
                  },
                  child: Text(
                    'View all',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (recent.isEmpty)
              _buildEmptyState()
            else
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  children: recent.asMap().entries.map((entry) {
                    final i = entry.key;
                    final tx = entry.value;
                    return Column(
                      children: [
                        AnimatedListItem(
                          delay: Duration(milliseconds: 60 * i),
                          child: _TransactionTile(transaction: tx),
                        ),
                        if (i < recent.length - 1)
                          Divider(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.04),
                            indent: 60,
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined,
                color: AppColors.textTertiary, size: 32),
            const SizedBox(height: 12),
            Text(
              'No transactions yet',
              style: TextStyle(
                  color: AppColors.textTertiary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  const _TransactionTile({required this.transaction});

  Color _typeColor() {
    switch (transaction.type) {
      case TransactionType.income:
        return AppColors.pastelGreen;
      case TransactionType.expense:
        return AppColors.error;
      case TransactionType.transfer:
        return AppColors.primaryBlue;
    }
  }

  String _sign() {
    switch (transaction.type) {
      case TransactionType.income:
        return '+';
      case TransactionType.expense:
        return '-';
      case TransactionType.transfer:
        return '↔';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor();
    final description = transaction.description;
    final title = (description != null && description.isNotEmpty)
        ? description
        : (transaction.categoryId ?? 'Uncategorized');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _categoryEmoji(transaction.categoryId),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd MMM').format(transaction.date),
                  style: TextStyle(
                      color: AppColors.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
          // Amount
          Text(
            '${_sign()}₹${NumberFormat('#,##,###').format(transaction.amount)}',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _categoryEmoji(String? categoryId) {
    switch (categoryId) {
      case 'food':
        return '🍔';
      case 'groceries':
        return '🛒';
      case 'transport':
        return '🚌';
      case 'garage':
        return '⛽';
      case 'bills':
        return '🏦';
      case 'entertainment':
        return '🎬';
      case 'health':
        return '💊';
      case 'education':
        return '📚';
      case 'shopping':
        return '🛍️';
      case 'investment':
        return '📈';
      case 'salary':
        return '💰';
      case 'travel':
        return '✈️';
      case 'transfer':
        return '↔️';
      case 'shared':
        return '👥';
      default:
        return '💸';
    }
  }
}
