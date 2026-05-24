import 'package:flutter/material.dart';
import '../../core/widgets/collapsible_fab.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/budget_provider.dart';
import 'widgets/add_budget.dart';

class ModernBudgetsScreen extends StatefulWidget {
  const ModernBudgetsScreen({super.key});

  @override
  State<ModernBudgetsScreen> createState() => _ModernBudgetsScreenState();
}

class _ModernBudgetsScreenState extends State<ModernBudgetsScreen> {
  bool _didInitProvider = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didInitProvider) {
        return;
      }
      _didInitProvider = true;
      context.read<BudgetProvider>().initialize();
    });
  }

  void _showDeleteConfirmation(BuildContext context, Budget budget) {
    showDialog(
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
                'Delete Budget',
                style: AppTypography.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete "${budget.categoryName}" budget?',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Provider.of<BudgetProvider>(
                            context,
                            listen: false,
                          ).deleteBudget(budget.id);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: Consumer<BudgetProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final budgets = provider.budgets;

          return CustomScrollView(
            slivers: [
              // 1. GOLDEN HEADER
              SliverAppBar(
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
                    'Budgets',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0, top: 10),
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_fix_high,
                          color: AppColors.accentPurple,
                          size: 20,
                        ),
                      ),
                      tooltip: "Auto Setup",
                      onPressed: () => showQuickSetupModal(context),
                    ),
                  ),
                ],
              ),

              // 2. HERO OVERVIEW (Monthly Cap)
              if (budgets.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: _buildOverviewCard(context, provider),
                  ),
                ),

              // 3. BUDGET BENTO GRID
              if (budgets.isEmpty)
                SliverFillRemaining(child: _buildEmptyState(context))
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    child: _buildBentoBudgetGrid(context, budgets),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: CollapsibleFab(
        backgroundColor: AppColors.cardSurface,
        foregroundColor: AppColors.accentPurple,
        icon: Icon(Icons.add, color: AppColors.accentPurple),
        label: 'New Budget',
        onPressed: () => showAddBudgetModal(context),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildOverviewCard(BuildContext context, BudgetProvider provider) {
    final totalAllocated = provider.totalAllocated;
    final totalSpent = provider.totalSpent;
    final totalRemaining = provider.totalRemaining;
    final percentSpent = totalAllocated > 0
        ? (totalSpent / totalAllocated)
        : 0.0;

    // Color logic
    final isOver = totalSpent > totalAllocated;
    final statusColor = isOver
        ? AppColors.error
        : (percentSpent > 0.8 ? AppColors.warning : AppColors.success);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentPurple.withValues(alpha: 0.25),
            AppColors.accentPurple.withValues(alpha: 0.08),
            AppColors.cardSurface,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.accentPurple.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPurple.withValues(alpha: 0.15),
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
                'BUDGET REMAINING',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOver
                          ? Icons.warning_amber
                          : (percentSpent > 0.8
                                ? Icons.info
                                : Icons.check_circle),
                      color: statusColor,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${(percentSpent * 100).clamp(0, 999).toStringAsFixed(0)}% Used',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '₹${_formatAmount(totalRemaining.abs())}',
            style: AppTypography.currencyLarge.copyWith(
              color: isOver ? AppColors.error : Colors.white,
            ),
          ),
          if (isOver)
            Text(
              'Over Budget',
              style: TextStyle(
                color: AppColors.error.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 20),
          // Premium Neon Progress Bar
          Stack(
            children: [
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    height: 10,
                    width: constraints.maxWidth * percentSpent.clamp(0.0, 1.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isOver
                            ? [AppColors.error, AppColors.error]
                            : [AppColors.accentPurple, statusColor],
                      ),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.6),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  'Spent',
                  '₹${_formatAmount(totalSpent)}',
                  AppColors.error.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat(
                  'Total Cap',
                  '₹${_formatAmount(totalAllocated)}',
                  AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat(
                  'Budgets',
                  '${provider.budgets.length}',
                  AppColors.accentPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ========== BENTO GRID LAYOUT ==========
  Widget _buildBentoBudgetGrid(BuildContext context, List<Budget> budgets) {
    final sorted = List<Budget>.from(budgets)
      ..sort(
        (a, b) => _budgetPriorityScore(b).compareTo(_budgetPriorityScore(a)),
      );

    final List<Widget> rows = [];
    int index = 0;

    while (index < sorted.length) {
      final remaining = sorted.length - index;
      final first = sorted[index];
      final firstPriority = _isPriorityBudget(first);

      if (remaining == 1) {
        rows.add(_buildBentoTile(context, first, isWide: true));
        index++;
      } else if (remaining == 2) {
        final second = sorted[index + 1];
        final useLarge = firstPriority || _isPriorityBudget(second);
        rows.add(
          Row(
            children: [
              Expanded(
                child: _buildBentoTile(
                  context,
                  first,
                  isLarge: useLarge,
                  isCompact: !useLarge,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBentoTile(
                  context,
                  second,
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
                Expanded(child: _buildBentoTile(context, first, isLarge: true)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: _buildBentoTile(
                          context,
                          sorted[index + 1],
                          isCompact: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _buildBentoTile(
                          context,
                          sorted[index + 2],
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
                  child: _buildBentoTile(context, first, isWide: true),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(
                        child: _buildBentoTile(
                          context,
                          sorted[index + 1],
                          isCompact: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _buildBentoTile(
                          context,
                          sorted[index + 2],
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

      rows.add(const SizedBox(height: 12));
    }

    return Column(children: rows);
  }

  double _budgetPriorityScore(Budget budget) {
    final overspentWeight = budget.isOverspent ? 100.0 : 0.0;
    final nearLimitWeight =
        (!budget.isOverspent && budget.spentPercentage >= 0.85) ? 45.0 : 0.0;
    final projectedOverWeight =
        budget.projectedSpending > budget.allocatedAmount ? 20.0 : 0.0;
    final amountWeight = budget.allocatedAmount / 15000;
    return overspentWeight +
        nearLimitWeight +
        projectedOverWeight +
        amountWeight;
  }

  bool _isPriorityBudget(Budget budget) => _budgetPriorityScore(budget) >= 45;

  Widget _buildBentoTile(
    BuildContext context,
    Budget budget, {
    bool isLarge = false,
    bool isWide = false,
    bool isCompact = false,
  }) {
    final progress = budget.progress;
    final isOverspent = budget.isOverspent;
    final statusColor = isOverspent
        ? AppColors.error
        : (progress > 0.85 ? AppColors.warning : AppColors.success);
    final categoryColor = _getCategoryColor(budget.categoryId);

    if (isLarge) {
      // Large square tile (like subscription large tile)
      return GestureDetector(
        onTap: () => showAddBudgetModal(context, budget: budget),
        onLongPress: () => _showDeleteConfirmation(context, budget),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  categoryColor.withValues(alpha: 0.2),
                  AppColors.cardSurface,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: categoryColor.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: categoryColor.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCategoryIcon(budget.categoryId),
                        color: categoryColor,
                        size: 18,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${(progress * 100).clamp(0, 999).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  budget.categoryName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '₹${_formatAmount(budget.allocatedAmount)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Progress bar
                Stack(
                  children: [
                    Container(
                      height: 5,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [categoryColor, statusColor],
                          ),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isOverspent
                      ? 'Over by ₹${_formatAmount(budget.spentAmount - budget.allocatedAmount)}'
                      : '₹${_formatAmount(budget.remainingAmount)} left',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (isWide) {
      // Wide horizontal tile
      return GestureDetector(
        onTap: () => showAddBudgetModal(context, budget: budget),
        onLongPress: () => _showDeleteConfirmation(context, budget),
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                categoryColor.withValues(alpha: 0.15),
                AppColors.cardSurface,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: categoryColor.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getCategoryIcon(budget.categoryId),
                  color: categoryColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      budget.categoryName,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Progress bar
                    Stack(
                      children: [
                        Container(
                          height: 6,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [categoryColor, statusColor],
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isOverspent
                          ? 'Over by ₹${_formatAmount(budget.spentAmount - budget.allocatedAmount)}'
                          : '₹${_formatAmount(budget.remainingAmount)} of ₹${_formatAmount(budget.allocatedAmount)} left',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(progress * 100).clamp(0, 999).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    budget.period.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      // Compact tile
      return GestureDetector(
        onTap: () => showAddBudgetModal(context, budget: budget),
        onLongPress: () => _showDeleteConfirmation(context, budget),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: categoryColor.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getCategoryIcon(budget.categoryId),
                    color: categoryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      budget.categoryName,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Progress bar
              Stack(
                children: [
                  Container(
                    height: 4,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${_formatAmount(budget.allocatedAmount)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(progress * 100).clamp(0, 999).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
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
  }

  Color _getCategoryColor(String categoryId) {
    final colors = {
      'housing': Colors.blue,
      'food': Colors.orange,
      'transportation': Colors.purple,
      'savings': AppColors.success,
      'investments': Colors.teal,
      'entertainment': Colors.pink,
      'shopping': Colors.amber,
      'health': Colors.red,
      'personal': Colors.indigo,
      'education': Colors.cyan,
      'miscellaneous': Colors.grey,
    };
    return colors[categoryId] ?? AppColors.accentPurple;
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated gradient container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.accentPurple.withValues(alpha: 0.2),
                    AppColors.accentPurple.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: AppColors.accentPurple.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(
                Icons.pie_chart_outline_rounded,
                size: 56,
                color: AppColors.accentPurple.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "No Budgets Yet",
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Set spending limits for categories\nand take control of your finances",
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Auto Setup Button
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accentPurple,
                        AppColors.accentPurple.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentPurple.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => showQuickSetupModal(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_fix_high,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Auto Setup',
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Manual Add Button
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.accentPurple.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => showAddBudgetModal(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add,
                              color: AppColors.accentPurple,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Add',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.accentPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  IconData _getCategoryIcon(String categoryId) {
    final icons = {
      'housing': Icons.home,
      'food': Icons.restaurant,
      'transportation': Icons.directions_car,
      'savings': Icons.savings,
      'investments': Icons.trending_up,
      'entertainment': Icons.movie,
      'shopping': Icons.shopping_bag,
      'health': Icons.local_hospital,
      'personal': Icons.face,
      'education': Icons.school,
      'miscellaneous': Icons.more_horiz,
    };
    return icons[categoryId] ?? Icons.category;
  }
}
