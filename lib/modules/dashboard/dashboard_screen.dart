import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/transaction_provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/bike_provider.dart';
import '../../core/providers/budget_provider.dart';
import '../../core/providers/goal_provider.dart';
import '../../core/providers/debt_provider.dart';
import '../../core/providers/dashboard_preferences_provider.dart';
import '../../core/models/transaction.dart';
import '../../core/widgets/animated_list_item.dart';
import '../../core/widgets/nexus_button.dart';
import '../../core/widgets/nexus_card.dart';
import '../../core/widgets/total_balance_card.dart';

// Destination Screens
import '../bike/ui/bike_screen.dart';
import '../family/screens/expense_splitter_screen.dart';
import '../transactions/add_transaction_screen.dart';
import '../notifications/notifications_screen.dart';
import '../debts/screens/liabilities_screen.dart';
import '../budgets/budgets_screen.dart';
import '../goals/goals_screen.dart';
import 'widgets/home_money_pulse.dart';

class ModernDashboardScreen extends StatefulWidget {
  final void Function(int index)? onNavigate;
  final VoidCallback? onOpenAccountsHistory;

  const ModernDashboardScreen({
    super.key,
    this.onNavigate,
    this.onOpenAccountsHistory,
  });

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

    return ChangeNotifierProvider<DashboardPreferencesProvider>(
      create: (_) => DashboardPreferencesProvider()..loadPreferences(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Consumer<DashboardPreferencesProvider>(
          builder: (context, prefs, _) {
            final isVisible = prefs.isWidgetVisible;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── 1. APP BAR ───────────────────────────────────────────────
                const _DashboardAppBar(),

                // ── 2. BALANCE CARD ──────────────────────────────────────────
                if (isVisible('total_balance') || isVisible('net_worth'))
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

                // ── 3. ACTION BAR ────────────────────────────────────────────
                if (isVisible('quick_actions'))
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

                // ── 4. ASYMMETRICAL BENTO GRID ───────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.xl,
                      0,
                    ),
                    child: _DashboardBentoGrid(
                      onOpenGarage: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ModernBikeScreen(),
                        ),
                      ),
                      onOpenPayments: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LiabilitiesScreen(),
                        ),
                      ),
                      onOpenBudgets: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ModernBudgetsScreen(),
                        ),
                      ),
                      onOpenGoals: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ModernGoalsScreen(),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── 5. MONEY PULSE ───────────────────────────────────────────
                if (isVisible('month_pulse') || isVisible('monthly_spending'))
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.lg,
                        AppSpacing.xl,
                        0,
                      ),
                      child: HomeMoneyPulse(),
                    ),
                  ),

                // ── 6. RECENT ACTIVITY ───────────────────────────────────────
                if (isVisible('recent_activity') ||
                    isVisible('recent_transactions'))
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.lg,
                        AppSpacing.xl,
                        0,
                      ),
                      child: _RecentActivitySectionWrapper(
                        onViewAll: widget.onOpenAccountsHistory,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Asymmetrical Bento Grid
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardBentoGrid extends StatelessWidget {
  final VoidCallback onOpenGarage;
  final VoidCallback onOpenPayments;
  final VoidCallback onOpenBudgets;
  final VoidCallback onOpenGoals;

  const _DashboardBentoGrid({
    required this.onOpenGarage,
    required this.onOpenPayments,
    required this.onOpenBudgets,
    required this.onOpenGoals,
  });

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<DashboardPreferencesProvider>();

    final showGarage = prefs.isWidgetVisible('garage');
    final showPayments =
        prefs.isWidgetVisible('payments') ||
        prefs.isWidgetVisible('upcoming_bills');
    final showBudgets = prefs.isWidgetVisible('budgets');
    final showGoals =
        prefs.isWidgetVisible('goals') ||
        prefs.isWidgetVisible('goal_progress');

    if (!showGarage && !showPayments && !showBudgets && !showGoals) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // ── Row 1: Garage (flex: 3) + Payments (flex: 2) ─────────────────────
        if (showGarage || showPayments)
          Padding(
            padding: EdgeInsets.only(
              bottom: (showBudgets || showGoals) ? 12 : 0,
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showGarage)
                    Expanded(
                      flex: showPayments ? 3 : 1,
                      child: _BentoGarageCard(onTap: onOpenGarage),
                    ),
                  if (showGarage && showPayments) const SizedBox(width: 12),
                  if (showPayments)
                    Expanded(
                      flex: showGarage ? 2 : 1,
                      child: _BentoPaymentsCard(onTap: onOpenPayments),
                    ),
                ],
              ),
            ),
          ),

        // ── Row 2: Budgets (flex: 1) + Goals (flex: 1) ───────────────────────
        if (showBudgets || showGoals)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showBudgets)
                  Expanded(child: _BentoBudgetsCard(onTap: onOpenBudgets)),
                if (showBudgets && showGoals) const SizedBox(width: 12),
                if (showGoals)
                  Expanded(child: _BentoGoalsCard(onTap: onOpenGoals)),
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bento Cards (Entire Surface Clickable)
// ─────────────────────────────────────────────────────────────────────────────

class _BentoGarageCard extends StatelessWidget {
  final VoidCallback onTap;

  const _BentoGarageCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<BikeProvider>(
      builder: (context, provider, _) {
        final bike = provider.dashboardDisplayBike;
        final mileage = provider.getDashboardReliableAverageMileage();

        return _BentoCardContainer(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.two_wheeler_rounded,
                      color: AppColors.primaryBlue,
                      size: 18,
                    ),
                  ),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GARAGE',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                      letterSpacing: 1.2,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    bike?.name ?? 'My Bike',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mileage > 0
                        ? '${mileage.toStringAsFixed(1)} km/L avg'
                        : 'Tap to view garage',
                    style: AppTypography.labelSmall.copyWith(
                      color: mileage > 0
                          ? AppColors.pastelGreen
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BentoPaymentsCard extends StatelessWidget {
  final VoidCallback onTap;

  const _BentoPaymentsCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<DebtProvider>(
      builder: (context, debt, _) {
        final count = debt.debts.length;

        return _BentoCardContainer(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.pastelOrange.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.schedule_rounded,
                      color: AppColors.pastelOrange,
                      size: 18,
                    ),
                  ),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PAYMENTS',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                      letterSpacing: 1.2,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    count > 0 ? '$count Due' : 'All Clear',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w900,
                      color: count > 0
                          ? AppColors.pastelOrange
                          : AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count > 0 ? 'Upcoming bills' : 'No dues',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BentoBudgetsCard extends StatelessWidget {
  final VoidCallback onTap;

  const _BentoBudgetsCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, budget, _) {
        final adherence =
            (budget.activeBudgets.isEmpty || budget.totalAllocated <= 0)
            ? 0.0
            : (budget.totalSpent / budget.totalAllocated).clamp(0.0, 1.0);
        final pct = (adherence * 100).toInt();

        return _BentoCardContainer(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.pastelPurple.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.pie_chart_outline_rounded,
                      color: AppColors.pastelPurple,
                      size: 18,
                    ),
                  ),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BUDGETS',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                      letterSpacing: 1.2,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    budget.activeBudgets.isEmpty ? 'Set Budget' : '$pct% Used',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w900,
                      color: adherence > 0.9
                          ? AppColors.error
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${budget.activeBudgets.length} active categories',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BentoGoalsCard extends StatelessWidget {
  final VoidCallback onTap;

  const _BentoGoalsCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<GoalProvider>(
      builder: (context, goal, _) {
        final activeGoals = goal.goals.where((g) => !g.isCompleted).toList();
        final count = activeGoals.length;

        return _BentoCardContainer(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.pastelPink.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.flag_rounded,
                      color: AppColors.pastelPink,
                      size: 18,
                    ),
                  ),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GOALS',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                      letterSpacing: 1.2,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    count > 0 ? '$count Active' : 'No Goals',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.pastelPink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count > 0 ? 'Keep saving' : 'Tap to create',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BentoCardContainer extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _BentoCardContainer({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        splashColor: AppColors.primaryBlue.withValues(alpha: 0.1),
        highlightColor: Colors.white.withValues(alpha: 0.05),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App Bar with Card Customization Button
// ─────────────────────────────────────────────────────────────────────────────

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
        IconButton(
          onPressed: () => _showCardCustomizerSheet(context),
          tooltip: 'Customize Home Cards',
          icon: Icon(
            Icons.tune_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
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

  void _showCardCustomizerSheet(BuildContext context) {
    final prefs = context.read<DashboardPreferencesProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return ChangeNotifierProvider.value(
          value: prefs,
          child: Consumer<DashboardPreferencesProvider>(
            builder: (ctx, p, _) {
              final widgets = p.allWidgets;

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Customize Home',
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Choose visible cards & layout elements',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () => p.resetToDefault(),
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: widgets.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                          itemBuilder: (c, index) {
                            final item = widgets[index];
                            return SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              activeThumbColor: AppColors.primaryBlue,
                              secondary: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  item.icon,
                                  size: 18,
                                  color: Colors.white70,
                                ),
                              ),
                              title: Text(
                                item.title,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              value: item.isVisible,
                              onChanged: (_) =>
                                  p.toggleWidgetVisibility(item.id),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Greeting
// ─────────────────────────────────────────────────────────────────────────────

class _GreetingTitle extends StatelessWidget {
  const _GreetingTitle();

  String _greetingByTime() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'GOOD MORNING';
    if (hour < 17) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
  }

  @override
  Widget build(BuildContext context) {
    final providerName = context.select<UserProvider, String>(
      (p) => p.user?.displayName ?? '',
    );
    final authName = FirebaseAuth.instance.currentUser?.displayName ?? '';
    final candidate = providerName.trim().isNotEmpty
        ? providerName.trim()
        : authName.trim();
    final rawName = candidate.isNotEmpty ? candidate : 'Guest';
    final firstName = rawName.split(' ').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _greetingByTime(),
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: firstName,
                style: AppTypography.displayMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              TextSpan(
                text: '.',
                style: AppTypography.displayMedium.copyWith(
                  color: const Color(
                    0xFFFF6D3B,
                  ), // Coral accent matching the reference dot
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
            ],
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
  const _ActionBar();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: NexusButton(
                onPressed: () => ModernAddTransactionScreen.show(context),
                variant: NexusButtonVariant.primary,
                emphasizedPrimary: true,
                icon: const Icon(Icons.add_rounded),
                label: 'Add Transaction',
              ),
            ),
            const SizedBox(width: AppSpacing.controlGap),
            Expanded(
              flex: 2,
              child: NexusButton(
                onPressed: () => ModernAddTransactionScreen.show(
                  context,
                  initialType: TransactionType.transfer,
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

// ─────────────────────────────────────────────────────────────────────────────
// Recent Activity
// ─────────────────────────────────────────────────────────────────────────────

class _RecentActivitySectionWrapper extends StatelessWidget {
  final VoidCallback? onViewAll;
  const _RecentActivitySectionWrapper({this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, txProvider, _) {
        final recent = txProvider.transactions.take(5).toList();
        return _RecentActivitySection(
          recentTransactions: recent,
          onViewAll: onViewAll,
        );
      },
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  final List<Transaction> recentTransactions;
  final VoidCallback? onViewAll;
  const _RecentActivitySection({
    required this.recentTransactions,
    this.onViewAll,
  });

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
              onTap: onViewAll,
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
            Text('No transactions yet', style: AppTypography.bodySmall),
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
      case TransactionType.adjustment:
        return AppColors.textSecondary;
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
      case TransactionType.adjustment:
        return '±';
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
          Text(
            '${_sign()}₹${NumberFormat('#,##,###').format(transaction.amount)}',
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
