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
import '../../core/widgets/nexus_button.dart';
import '../../core/widgets/nexus_card.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ΓöÇΓöÇ 1. APP BAR ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
          const _DashboardAppBar(),

          // ΓöÇΓöÇ 2. BALANCE CARD ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                0,
              ),
              child: TotalBalanceCard(),
            ),
          ),

          // ΓöÇΓöÇ 3. ACTION BAR ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                0,
              ),
              child: _ActionBar(),
            ),
          ),

          // ΓöÇΓöÇ 4. UPCOMING WEEK ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
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

          // ΓöÇΓöÇ 5. GARAGE WIDGET ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                0,
              ),
              child: GarageDashboardWidget(
                onOpenGarage: () => widget.onNavigate?.call(3),
              ),
            ),
          ),

          // ΓöÇΓöÇ 6. RECENT ACTIVITY ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                0,
              ),
              child: _RecentActivitySectionWrapper(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

// ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
// App Bar
// ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

class _DashboardAppBar extends StatelessWidget {
  const _DashboardAppBar();

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: const _GreetingTitle(),
      actions: [
        Consumer<NotificationProvider>(
          builder: (context, notifProvider, _) {
            final unread = notifProvider.unreadCount;
            return IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ModernNotificationsScreen(),
                ),
              ),
              tooltip: 'Notifications',
              padding: const EdgeInsets.all(AppSpacing.sm),
              icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    if (unread > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 14,
                          height: 14,
                            decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              unread > 9 ? '9+' : '$unread',
                              style: AppTypography.labelSmall.copyWith(
                                color: Theme.of(context).colorScheme.onError,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
            );
          },
        ),
      ],
    );
  }
}

// ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
// Greeting
// ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

class _GreetingTitle extends StatelessWidget {
  const _GreetingTitle();

  String _greetingByTime() {
    final hour = DateTime.now().hour;
    return hour < 12 ? 'Good morning,' : 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    // Only rebuilds if displayName specifically changes
    final providerName = context.select<UserProvider, String>(
      (p) => p.user?.displayName ?? '',
    );
    final authName = FirebaseAuth.instance.currentUser?.displayName ?? '';
    final candidate = providerName.trim().isNotEmpty
        ? providerName.trim()
        : authName.trim();
    final userName = candidate.isNotEmpty ? candidate : 'User';

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

// ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
// Action Bar
// ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

class _ActionBar extends StatelessWidget {
  const _ActionBar();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            // Primary: Add Transaction
            Expanded(
              flex: 3,
                child: NexusButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ModernAddTransactionScreen(),
                  ),
                ),
                variant: NexusButtonVariant.primary,
                emphasizedPrimary: true,
                icon: const Icon(Icons.add_rounded),
                label: 'Add Transaction',
              ),
            ),
            const SizedBox(width: AppSpacing.controlGap),
            // Secondary: Transfer
            Expanded(
              flex: 2,
              child: NexusButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ModernAddTransactionScreen(
                      initialType: TransactionType.transfer,
                    ),
                  ),
                ),
                variant: NexusButtonVariant.secondary,
                icon: const Icon(Icons.swap_horiz_rounded),
                label: 'Transfer',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.controlGap),
        NexusButton(
          width: double.infinity,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ExpenseSplitterScreen()),
          ),
          variant: NexusButtonVariant.tertiary,
          icon: const Icon(Icons.call_split_rounded),
          label: 'Quick Split (No Save)',
        ),
      ],
    );
  }
}

// ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
// Recent Activity
// ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

class _RecentActivitySectionWrapper extends StatelessWidget {
  const _RecentActivitySectionWrapper();

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, txProvider, _) {
        final recent = txProvider.transactions.take(5).toList();
        return _RecentActivitySection(recentTransactions: recent);
      },
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  final List<Transaction> recentTransactions;
  const _RecentActivitySection({required this.recentTransactions});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RECENT ACTIVITY',
              style: AppTypography.labelSmall.copyWith(letterSpacing: 1.2),
            ),
            GestureDetector(
              onTap: () {
                // Navigate to full transactions screen via bottom nav
                // handled by parent scaffold tab switching
              },
              child: Text(
                'View all',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primaryBlue,
                ),
              
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.contentGap),
        if (recentTransactions.isEmpty)
          const _EmptyState()
        else
          NexusCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: recentTransactions.asMap().entries.map((entry) {
                final i = entry.key;
                final tx = entry.value;
                return Column(
                  children: [
                    AnimatedListItem(
                      delay: Duration(milliseconds: 60 * i),
                      child: _TransactionTile(transaction: tx),
                    ),
                    if (i < recentTransactions.length - 1)
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
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl2),
      child: const Center(
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              color: AppColors.textTertiary,
              size: 32,
            ),
            SizedBox(height: AppSpacing.contentGap),
            Text(
              'No transactions yet',
              style: AppTypography.bodySmall,
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
        return 'Γåö';
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
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Center(
              child: Text(
                _categoryEmoji(transaction.categoryId),
                style: AppTypography.titleMedium,
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
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd MMM').format(transaction.date),
                  style: AppTypography.labelSmall,
                ),
              ],
            ),
          ),
          // Amount
          Text(
            '${_sign()}Γé╣${NumberFormat('#,##,###').format(transaction.amount)}',
            style: TextStyle(
              color: color,
              fontSize: AppTypography.labelLarge.fontSize,
              fontWeight: AppTypography.labelLarge.fontWeight,
            ),
          ),
        ],
      ),
    );
  }

  String _categoryEmoji(String? categoryId) {
    switch (categoryId) {
      case 'food':
        return '≡ƒìö';
      case 'groceries':
        return '≡ƒ¢Æ';
      case 'transport':
        return '≡ƒÜî';
      case 'garage':
        return 'Γ¢╜';
      case 'bills':
        return '≡ƒÅª';
      case 'entertainment':
        return '≡ƒÄ¼';
      case 'health':
        return '≡ƒÆè';
      case 'education':
        return '≡ƒôÜ';
      case 'shopping':
        return '≡ƒ¢ì∩╕Å';
      case 'investment':
        return '≡ƒôê';
      case 'salary':
        return '≡ƒÆ░';
      case 'travel':
        return 'Γ£ê∩╕Å';
      case 'transfer':
        return 'Γåö∩╕Å';
      case 'shared':
        return '≡ƒæÑ';
      default:
        return '≡ƒÆ╕';
    }
  }
}
