import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/providers/transaction_provider.dart';
import '../../core/models/subscription.dart';
import '../../core/models/transaction.dart' as txn;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_animations.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/swipe_to_delete.dart';
import '../../core/widgets/collapsible_fab.dart';
import '../../core/widgets/nexus_card.dart';
import '../../core/utils/logo_utils.dart';
import 'widgets/add_subscription.dart';

enum SubscriptionFilter { active, history }

class ModernSubscriptionScreen extends StatefulWidget {
  const ModernSubscriptionScreen({super.key});

  @override
  State<ModernSubscriptionScreen> createState() =>
      _ModernSubscriptionScreenState();
}

class _ModernSubscriptionScreenState extends State<ModernSubscriptionScreen> {
  SubscriptionFilter _filter = SubscriptionFilter.active;

  // Zombie detection: subscriptions without matching transactions in 60 days
  Set<String> _zombieSubIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().initialize();
      _detectZombieSubscriptions();
    });
  }

  /// Detect subscriptions that haven't had matching transactions recently
  Future<void> _detectZombieSubscriptions() async {
    try {
      final subProvider = context.read<SubscriptionProvider>();
      final txnProvider = context.read<TransactionProvider>();

      final activeSubs = subProvider.subscriptions
          .where((s) => s.isActive)
          .toList();
      final recentTransactions = txnProvider.transactions.where((t) {
        final sixtyDaysAgo = DateTime.now().subtract(const Duration(days: 60));
        return t.date.isAfter(sixtyDaysAgo) &&
            t.type == txn.TransactionType.expense;
      }).toList();

      final zombies = <String>{};

      for (final sub in activeSubs) {
        // Check if any transaction matches this subscription (by name similarity)
        final hasMatchingTxn = recentTransactions.any((t) {
          final desc = (t.description ?? '').toLowerCase();
          final subName = sub.name.toLowerCase();
          // Match if description contains subscription name or vice versa
          return desc.contains(subName) ||
              subName.contains(desc) ||
              _fuzzyMatch(desc, subName);
        });

        if (!hasMatchingTxn) {
          zombies.add(sub.id);
        }
      }

      if (mounted) {
        setState(() => _zombieSubIds = zombies);
      }
    } catch (e) {
      debugPrint('Zombie detection error: $e');
    }
  }

  /// Simple fuzzy matching for subscription names
  bool _fuzzyMatch(String a, String b) {
    // Common abbreviations
    final abbrevMap = {
      'netflix': ['nflx', 'netflix'],
      'spotify': ['spotify', 'spot'],
      'amazon': ['amzn', 'amazon', 'prime'],
      'youtube': ['yt', 'youtube', 'ytube'],
      'disney': ['disney', 'hotstar', 'd+'],
      'apple': ['apple', 'icloud'],
      'google': ['google', 'goog'],
      'microsoft': ['msft', 'microsoft', 'office', '365'],
    };

    for (final entry in abbrevMap.entries) {
      if (entry.value.any((v) => a.contains(v)) &&
          entry.value.any((v) => b.contains(v))) {
        return true;
      }
    }
    return false;
  }

  /// Calculate days until due
  int _daysUntilDue(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.difference(today).inDays;
  }

  /// Get due status info
  ({String text, Color color, bool urgent})? _getDueStatus(Subscription sub) {
    final days = _daysUntilDue(sub.nextDueDate);

    if (days < 0) {
      return (text: 'Overdue', color: AppColors.error, urgent: true);
    } else if (days == 0) {
      return (text: 'Today', color: AppColors.error, urgent: true);
    } else if (days == 1) {
      return (text: 'Tomorrow', color: AppColors.pastelOrange, urgent: true);
    } else if (days <= 3) {
      return (text: '${days}d', color: AppColors.pastelOrange, urgent: false);
    } else if (days <= 7) {
      return (
        text: '${days}d',
        color: AppColors.pastelYellow,
        urgent: false,
      ); // Amber/Yellow
    }
    return null; // Don't show badge for > 7 days
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

          // Sort Active by Amount (High to Low) for the Bento Grid hierarchy
          activeSubs.sort((a, b) => b.amount.compareTo(a.amount));

          final historySubs = allSubs.where((s) => !s.isActive).toList();

          return CustomScrollView(
            slivers: [
              _buildAppBar(context, activeSubs.length),

              // Filter Pills
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: _buildFilterPills(
                    activeSubs.length,
                    historySubs.length,
                  ),
                ),
              ),

              // --- BODY CONTENT ---
              if (_filter == SubscriptionFilter.active)
                ..._buildActiveBentoView(context, provider, activeSubs)
              else
                _buildHistoryListView(context, provider, historySubs),

              // Bottom Padding for FAB
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      floatingActionButton: CollapsibleFab(
        onPressed: () => ModernAddSubscriptionScreen.show(context),
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: 'New Sub',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ================= ACTIVE VIEW (BENTO GRID) =================

  List<Widget> _buildActiveBentoView(
    BuildContext context,
    SubscriptionProvider provider,
    List<Subscription> subs,
  ) {
    if (subs.isEmpty) {
      return [SliverFillRemaining(child: _buildEmptyState(context))];
    }

    final totalMonthly = provider.totalMonthlyCost;
    final totalYearly = provider.totalYearlyCost;

    // Collect alerts
    final overdueSubs = subs.where((s) => s.isOverdue).toList();
    final dueSoonSubs = subs.where((s) {
      final days = _daysUntilDue(s.nextDueDate);
      return days >= 0 && days <= 3 && !s.isOverdue;
    }).toList();
    final zombieSubs = subs.where((s) => _zombieSubIds.contains(s.id)).toList();

    final hasAlerts =
        overdueSubs.isNotEmpty ||
        dueSoonSubs.isNotEmpty ||
        zombieSubs.isNotEmpty;
    final rankedSubs = List<Subscription>.from(subs)
      ..sort(
        (a, b) => _subscriptionPriorityScore(
          b,
        ).compareTo(_subscriptionPriorityScore(a)),
      );
    final bentoRows = _buildDynamicSubscriptionRows(
      context,
      rankedSubs,
      totalMonthly,
    );

    return [
      // 0. TOTAL SUMMARY CARD (At Top) - Dark Theme
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: _buildTotalSummaryCard(totalMonthly, totalYearly),
        ),
      ),

      // 1. ALERTS BANNER (if any)
      if (hasAlerts)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: _buildAlertsBanner(overdueSubs, dueSoonSubs, zombieSubs),
          ),
        ),

      // 2. DYNAMIC BENTO ROWS
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: bentoRows),
        ),
      ),
    ];
  }

  List<Widget> _buildDynamicSubscriptionRows(
    BuildContext context,
    List<Subscription> subs,
    double totalMonthly,
  ) {
    final rows = <Widget>[];
    int index = 0;

    while (index < subs.length) {
      final remaining = subs.length - index;
      final first = subs[index];
      final firstPriority = _isPrioritySubscription(first);

      if (remaining == 1) {
        rows.add(_buildBentoTile(context, first, totalMonthly, isWide: true));
        index++;
      } else if (remaining == 2) {
        final second = subs[index + 1];
        final useLarge = firstPriority || _isPrioritySubscription(second);
        rows.add(
          Row(
            children: [
              Expanded(
                child: _buildBentoTile(
                  context,
                  first,
                  totalMonthly,
                  isLarge: useLarge,
                  isCompact: !useLarge,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBentoTile(
                  context,
                  second,
                  totalMonthly,
                  isLarge: useLarge,
                  isCompact: !useLarge,
                ),
              ),
            ],
          ),
        );
        index += 2;
      } else if (firstPriority) {
        rows.add(
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildBentoTile(
                    context,
                    first,
                    totalMonthly,
                    isLarge: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: _buildBentoTile(
                          context,
                          subs[index + 1],
                          totalMonthly,
                          isCompact: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _buildBentoTile(
                          context,
                          subs[index + 2],
                          totalMonthly,
                          isCompact: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        index += 3;
      } else {
        rows.add(
          SizedBox(
            height: 168,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildBentoTile(
                    context,
                    first,
                    totalMonthly,
                    isWide: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(
                        child: _buildBentoTile(
                          context,
                          subs[index + 1],
                          totalMonthly,
                          isCompact: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _buildBentoTile(
                          context,
                          subs[index + 2],
                          totalMonthly,
                          isCompact: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        index += 3;
      }

      if (index < subs.length) {
        rows.add(const SizedBox(height: 12));
      }
    }
    return rows;
  }

  double _subscriptionPriorityScore(Subscription sub) {
    final daysUntilDue = _daysUntilDue(sub.nextDueDate);
    final overdueWeight = sub.isOverdue ? 100.0 : 0.0;
    final dueSoonWeight = (!sub.isOverdue && daysUntilDue <= 3) ? 55.0 : 0.0;
    final zombieWeight = _zombieSubIds.contains(sub.id) ? 40.0 : 0.0;
    final amountWeight = sub.amount / 2500;
    return overdueWeight + dueSoonWeight + zombieWeight + amountWeight;
  }

  bool _isPrioritySubscription(Subscription sub) =>
      _subscriptionPriorityScore(sub) >= 55;

  // ================= HISTORY VIEW (LIST) =================

  Widget _buildHistoryListView(
    BuildContext context,
    SubscriptionProvider provider,
    List<Subscription> subs,
  ) {
    if (subs.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyState(context));
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final subscription = subs[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SwipeToDelete(
              itemKey: ValueKey(subscription.id),
              itemId: subscription.id,
              itemName: subscription.name,
              onDelete: () => provider.deleteSubscription(subscription.id),
              child: _buildHistoryCard(context, subscription),
            ),
          );
        }, childCount: subs.length),
      ),
    );
  }

  // ================= WIDGETS =================

  Widget _buildBentoTile(
    BuildContext context,
    Subscription? sub,
    double totalMonthly, {
    bool isLarge = false,
    bool isWide = false,
    bool isCompact = false,
  }) {
    if (sub == null) {
      return const SizedBox.shrink();
    }

    final logoPath = LogoUtils.subscriptionLogoFor(sub.name);

    Color brandColor = AppColors.pastelOrange;
    try {
      if (sub.color.startsWith('#')) {
        brandColor = Color(int.parse(sub.color.replaceFirst('#', '0xFF')));
      }
    } catch (_) {}

    final percentage = totalMonthly > 0
        ? (sub.amount / totalMonthly * 100).toStringAsFixed(0)
        : '0';

    final bgLogoSize = isLarge ? 140.0 : (isCompact ? 70.0 : 100.0);

    // Due status for badge
    final dueStatus = _getDueStatus(sub);
    final isZombie = _zombieSubIds.contains(sub.id);

    return GestureDetector(
      onTap: () =>
          ModernAddSubscriptionScreen.show(context, subscriptionToEdit: sub),
      child: Container(
        height: isLarge
            ? 180
            : (isWide ? null : null), // Let Expanded handle compact height
        constraints: isCompact ? const BoxConstraints(minHeight: 70) : null,
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(isCompact ? 20 : 32),
          border: Border.all(
            color: dueStatus?.urgent == true
                ? dueStatus!.color.withValues(alpha: 0.5)
                : isZombie
                ? Colors.grey.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.05),
            width: dueStatus?.urgent == true ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: dueStatus?.urgent == true
                  ? dueStatus!.color.withValues(alpha: 0.15)
                  : brandColor.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // Blurred logo background (inside Container so it renders on top of cardSurface)
            if (logoPath != null)
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Opacity(
                    opacity: 0.25,
                    child: Center(
                      child: LogoUtils.buildLogo(logoPath, size: bgLogoSize),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(isCompact ? 10 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: isCompact
                    ? MainAxisAlignment.center
                    : (isLarge
                          ? MainAxisAlignment.spaceBetween
                          : MainAxisAlignment.start),
                mainAxisSize: (isWide || isCompact)
                    ? MainAxisSize.min
                    : MainAxisSize.max,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isZombie && !isCompact)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundBlack,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            size: 12,
                            color: Colors.grey,
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      // Right side: percentage or due badge
                      if (!isCompact)
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Due Soon Badge
                              if (dueStatus != null) ...[
                                Tooltip(
                                  message: dueStatus.text,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: dueStatus.color.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: dueStatus.color.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: Icon(
                                      dueStatus.urgent
                                          ? Icons.notifications_active
                                          : Icons.schedule,
                                      size: 12,
                                      color: dueStatus.color,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              // Percentage badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundBlack,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "$percentage%",
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (dueStatus != null)
                        // Compact due badge
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: dueStatus.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              dueStatus.text,
                              style: AppTypography.labelSmall.copyWith(
                                color: dueStatus.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),

                  if (isLarge) const Spacer(),
                  if (!isLarge && !isCompact) const SizedBox(height: 6),
                  if (isWide) const SizedBox(height: 4),

                  Flexible(
                    fit: FlexFit.loose,
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isCompact) ...[
                            Text(
                              sub.name,
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                          ],
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Flexible(
                                child: Text(
                                  "₹${sub.amount.toStringAsFixed(0)}",
                                  style: isCompact
                                      ? AppTypography.titleMedium.copyWith(
                                          color: AppColors.textPrimary,
                                        )
                                      : AppTypography.headlineMedium.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!isCompact)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Text(
                                    "/${sub.frequency == 'monthly' ? 'mo' : 'yr'}",
                                    style: AppTypography.bodySmall,
                                  ),
                                ),
                            ],
                          ),
                          if (isLarge)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "~₹${(sub.amount * (sub.frequency == 'monthly' ? 12 : 1)).toStringAsFixed(0)}/yr",
                                style: AppTypography.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          // Zombie warning text for large tiles
                          if (isZombie && isLarge)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "⚠️ No matching payments in 60 days",
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Pulsing indicator for urgent due
            if (dueStatus?.urgent == true)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dueStatus!.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: dueStatus.color.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Subscription sub) {
    final logoPath = LogoUtils.subscriptionLogoFor(sub.name);
    return Opacity(
      opacity: 0.6,
      child: NexusCard(
        color: AppColors.cardSurface,
        padding: AppSpacing.cardPaddingMd,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: logoPath != null
                    ? LogoUtils.buildLogo(logoPath, size: 22)
                    : const Icon(Icons.history, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sub.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyLarge.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text("Cancelled", style: AppTypography.bodySmall),
                ],
              ),
            ),
            Flexible(
              child: Text(
                "₹${sub.amount.toStringAsFixed(0)}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= ALERTS BANNER =================

  Widget _buildAlertsBanner(
    List<Subscription> overdue,
    List<Subscription> dueSoon,
    List<Subscription> zombies,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardSurface,
            AppColors.cardSurface.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: overdue.isNotEmpty
              ? AppColors.error.withValues(alpha: 0.3)
              : dueSoon.isNotEmpty
              ? AppColors.pastelOrange.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                overdue.isNotEmpty
                    ? Icons.warning_rounded
                    : dueSoon.isNotEmpty
                    ? Icons.notifications_active
                    : Icons.info_outline,
                color: overdue.isNotEmpty
                    ? AppColors.error
                    : dueSoon.isNotEmpty
                    ? AppColors.pastelOrange
                    : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                overdue.isNotEmpty
                    ? "Action Required"
                    : dueSoon.isNotEmpty
                    ? "Coming Up"
                    : "Heads Up",
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Alert Items
          if (overdue.isNotEmpty)
            _buildAlertItem(
              icon: Icons.error_outline,
              color: AppColors.error,
              text:
                  "${overdue.length} subscription${overdue.length > 1 ? 's' : ''} overdue",
              detail: overdue.map((s) => s.name).join(', '),
            ),

          if (dueSoon.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: overdue.isNotEmpty ? 8 : 0),
              child: _buildAlertItem(
                icon: Icons.schedule,
                color: AppColors.pastelOrange,
                text: "${dueSoon.length} due in next 3 days",
                detail: dueSoon.map((s) => s.name).join(', '),
              ),
            ),

          if (zombies.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: (overdue.isNotEmpty || dueSoon.isNotEmpty) ? 8 : 0,
              ),
              child: _buildAlertItem(
                icon: Icons.warning_amber_rounded,
                color: Colors.grey,
                text:
                    "${zombies.length} unused subscription${zombies.length > 1 ? 's' : ''}",
                detail: "No matching payments in 60 days",
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlertItem({
    required IconData icon,
    required Color color,
    required String text,
    required String detail,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                detail,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalSummaryCard(double monthly, double yearly) {
    return NexusCard(
      variant: NexusCardVariant.hero,
      padding: AppSpacing.cardPaddingLg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "TOTAL / MONTH",
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "₹${monthly.toStringAsFixed(0)}",
                style: AppTypography.currencyLarge.copyWith(
                  color: AppColors.textPrimary, // White text
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "YEARLY",
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "₹${yearly.toStringAsFixed(0)}",
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.pastelTeal, // Subtle pop of color
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, int count) {
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
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPills(int activeCount, int historyCount) {
    return Row(
      children: [
        _buildPill("Active", SubscriptionFilter.active),
        const SizedBox(width: 12),
        _buildPill("History", SubscriptionFilter.history),
      ],
    );
  }

  Widget _buildPill(String label, SubscriptionFilter value) {
    final isSelected = _filter == value;
    final color = isSelected ? AppColors.primaryBlue : AppColors.cardSurface;
    final textColor = isSelected ? Colors.white : AppColors.textSecondary;

    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: AppAnimations.standard,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelLarge.copyWith(color: textColor),
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
            color: AppColors.textTertiary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            isHistory ? "No History" : "No Subscriptions",
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isHistory
                ? "Cancelled items appear here"
                : "Add your recurring bills",
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}

// Helper Extension
extension ListExtension<T> on List<T> {
  T? elementAtOrNull(int index) {
    return index < length ? this[index] : null;
  }
}
