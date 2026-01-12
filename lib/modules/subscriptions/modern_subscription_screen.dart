import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/models/subscription.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/swipe_to_delete.dart';
import 'widgets/add_subscription_modal.dart';
import 'widgets/log_subscription_payment_modal.dart';

// Matches Debt Filter Logic
enum SubscriptionFilter { active, history }

class ModernSubscriptionScreen extends StatefulWidget {
  const ModernSubscriptionScreen({super.key});

  @override
  State<ModernSubscriptionScreen> createState() =>
      _ModernSubscriptionScreenState();
}

class _ModernSubscriptionScreenState extends State<ModernSubscriptionScreen> {
  SubscriptionFilter _filter = SubscriptionFilter.active;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: Consumer<SubscriptionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.subscriptions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final allSubs = provider.subscriptions;
          final activeSubs = allSubs.where((s) => s.isActive).toList();
          final historySubs = allSubs.where((s) => !s.isActive).toList();

          final displaySubs = _filter == SubscriptionFilter.active
              ? activeSubs
              : historySubs;

          return CustomScrollView(
            slivers: [
              _buildAppBar(context),

              // Hero Summary (Active only)
              if (_filter == SubscriptionFilter.active && activeSubs.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: _buildSmartSummaryCard(context, activeSubs),
                  ),
                ),

              // Filter Pills
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: _buildFilterPills(
                    activeSubs.length,
                    historySubs.length,
                  ),
                ),
              ),

              // List
              if (displaySubs.isEmpty)
                SliverFillRemaining(child: _buildEmptyState(context))
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final subscription = displaySubs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SwipeToDelete(
                          itemKey: ValueKey(subscription.id),
                          itemId: subscription.id,
                          itemName: subscription.name,
                          onDelete: () =>
                              provider.deleteSubscription(subscription.id),
                          child: _buildSubscriptionCard(context, subscription),
                        ),
                      );
                    }, childCount: displaySubs.length),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: FloatingActionButton.extended(
          onPressed: () => showAddSubscriptionModal(context),
          backgroundColor: AppColors.accentOrange,
          elevation: 4,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'New Sub',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 110,
      backgroundColor: AppColors.backgroundBlack,
      surfaceTintColor: AppColors.backgroundBlack,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 24),
        title: Text(
          'Subscriptions',
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPills(int activeCount, int historyCount) {
    return Row(
      children: [
        _buildPill("Active ($activeCount)", SubscriptionFilter.active),
        const SizedBox(width: 12),
        _buildPill("Inactive / History", SubscriptionFilter.history),
      ],
    );
  }

  Widget _buildPill(String label, SubscriptionFilter value) {
    final isSelected = _filter == value;
    final color = isSelected ? AppColors.accentOrange : AppColors.cardSurface;
    final textColor = isSelected ? Colors.white : AppColors.textSecondary;

    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: color,
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
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSmartSummaryCard(
    BuildContext context,
    List<Subscription> activeSubs,
  ) {
    double monthlyTotal = 0.0;
    double yearlyTotal = 0.0;
    Subscription? upcomingBigBill;
    int daysUntilBill = 999;

    // 1. Calculate Totals & Find Spikes
    for (var sub in activeSubs) {
      // Monthly Calc
      if (sub.frequency.toLowerCase() == 'monthly') {
        monthlyTotal += sub.amount;
        yearlyTotal += sub.amount * 12;
      } else if (sub.frequency.toLowerCase() == 'yearly') {
        monthlyTotal += sub.amount / 12;
        yearlyTotal += sub.amount;

        // Smart Alert: Check if an annual bill is due in < 30 days
        final days = sub.nextDueDate.difference(DateTime.now()).inDays;
        if (days >= 0 && days < 30 && days < daysUntilBill) {
          daysUntilBill = days;
          upcomingBigBill = sub;
        }
      } else if (sub.frequency.toLowerCase() == 'weekly') {
        monthlyTotal += sub.amount * 4.33;
        yearlyTotal += sub.amount * 52;
      }
    }

    final dailyCost = monthlyTotal / 30;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEA580C), // Orange 600
            Color(0xFF9A3412), // Orange 800
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
          // HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MONTHLY BURN',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '~₹${dailyCost.toStringAsFixed(0)} / day',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${activeSubs.length} Active',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // BIG AMOUNT
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                monthlyTotal.toStringAsFixed(0),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 12),

          // FOOTER: Yearly + Alerts
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yearly Impact',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '₹${(yearlyTotal / 1000).toStringAsFixed(1)}K',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // SMART ALERT (Only shows if an annual bill is near)
              if (upcomingBigBill != null)
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.warning,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Upcoming Spike",
                                style: TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "${upcomingBigBill.name} due in $daysUntilBill days",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
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
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, Subscription sub) {
    final daysLeft = sub.nextDueDate.difference(DateTime.now()).inDays;
    final isDueSoon = daysLeft >= 0 && daysLeft <= 3;
    final isOverdue = daysLeft < 0;

    final cardOpacity = sub.isActive ? 1.0 : 0.6;

    return Opacity(
      opacity: cardOpacity,
      child: GestureDetector(
        onTap: () => showAddSubscriptionModal(context, subscriptionToEdit: sub),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isOverdue && sub.isActive
                  ? AppColors.error.withOpacity(0.5)
                  : Colors.white.withOpacity(0.05),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        sub.name.isNotEmpty ? sub.name[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          color: AppColors.accentOrange,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sub.name,
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildSmallPill(
                              sub.frequency.toUpperCase(),
                              AppColors.textTertiary,
                            ),
                            const SizedBox(width: 8),
                            if (sub.isActive)
                              Text(
                                isOverdue
                                    ? 'Overdue!'
                                    : (daysLeft == 0
                                          ? 'Due Today'
                                          : 'In $daysLeft days'),
                                style: TextStyle(
                                  color: isOverdue
                                      ? AppColors.error
                                      : (isDueSoon
                                            ? AppColors.warning
                                            : AppColors.textTertiary),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            else
                              const Text(
                                "Cancelled",
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${sub.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),

              // Pay Button (Only if Active)
              if (sub.isActive) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        showLogSubscriptionPaymentModal(context, sub),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text("Log Renewal Payment"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentOrange,
                      side: BorderSide(
                        color: AppColors.accentOrange.withOpacity(0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isHistory = _filter == SubscriptionFilter.history;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isHistory ? Icons.history : Icons.subscriptions_outlined,
            size: 64,
            color: AppColors.textTertiary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            isHistory ? "No History" : "No Subscriptions",
            style: TextStyle(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 8),
          Text(
            isHistory
                ? "Cancelled items appear here"
                : "Add your recurring bills",
            style: TextStyle(
              color: AppColors.textTertiary.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
