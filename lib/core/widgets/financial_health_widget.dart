import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_animations.dart';
import '../services/financial_health_service.dart';
import '../providers/budget_provider.dart';
import '../providers/debt_provider.dart';
import '../providers/goal_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/investment_provider.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';

class FinancialHealthWidget extends StatefulWidget {
  final VoidCallback? onTap;

  const FinancialHealthWidget({super.key, this.onTap});

  @override
  State<FinancialHealthWidget> createState() => _FinancialHealthWidgetState();
}

class _FinancialHealthWidgetState extends State<FinancialHealthWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scoreAnimation;
  FinancialHealthReport? _report;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppAnimations.veryLong,
      vsync: this,
    );
    _scoreAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AppAnimations.standardCurve,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateHealth();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _calculateHealth() {
    final accountProvider = context.read<AccountProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    final debtProvider = context.read<DebtProvider>();
    final goalProvider = context.read<GoalProvider>();
    final subscriptionProvider = context.read<SubscriptionProvider>();
    final investmentProvider = context.read<InvestmentProvider>();

    // Calculate monthly income/expenses from transactions
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthTransactions = transactionProvider.transactions
        .where((t) => t.date.isAfter(monthStart))
        .toList();

    final monthlyIncome = monthTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final monthlyExpenses = monthTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    // Calculate totals
    final totalCash = accountProvider.accounts
        .where((a) => a.isActive)
        .fold(0.0, (sum, a) => sum + a.balance);
    final totalInvestments = investmentProvider.investments.fold(
      0.0,
      (sum, i) => sum + i.currentAmount,
    );
    final totalDebt = debtProvider.debts
        .where((d) => d.currentBalance > 0)
        .fold(0.0, (sum, d) => sum + d.currentBalance);

    final report = FinancialHealthService.calculateHealthScore(
      totalCash: totalCash,
      totalInvestments: totalInvestments,
      totalDebt: totalDebt,
      monthlyIncome: monthlyIncome > 0
          ? monthlyIncome
          : 50000, // Default if no data
      monthlyExpenses: monthlyExpenses > 0 ? monthlyExpenses : 40000,
      budgets: budgetProvider.budgets,
      debts: debtProvider.debts,
      goals: goalProvider.goals,
      subscriptions: subscriptionProvider.subscriptions,
      investments: investmentProvider.investments,
    );

    setState(() {
      _report = report;
    });
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    if (_report == null) {
      return _buildLoadingState();
    }

    return GestureDetector(
      onTap: () {
        setState(() => _isExpanded = !_isExpanded);
      },
      child: AnimatedContainer(
        duration: AppAnimations.slow,
        curve: AppAnimations.smoothCurve,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _report!.gradeColor.withOpacity(0.15),
              AppColors.cardSurface,
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _report!.gradeColor.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: _report!.gradeColor.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Animated Score Circle
                AnimatedBuilder(
                  animation: _scoreAnimation,
                  builder: (context, child) {
                    return _buildScoreCircle(
                      _report!.overallScore * _scoreAnimation.value,
                    );
                  },
                ),
                const SizedBox(width: 16),
                // Title & Grade
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Financial Health',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.titleMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _report!.gradeColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _report!.gradeLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _report!.gradeColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getHealthMessage(),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.textTertiary,
                ),
              ],
            ),

            // Category Breakdown (Expanded)
            if (_isExpanded) ...[
              const SizedBox(height: 20),
              Container(height: 1, color: Colors.white.withOpacity(0.05)),
              const SizedBox(height: 16),
              _buildCategoryBreakdown(),
              const SizedBox(height: 16),
              // Top Insights
              if (_report!.insights.isNotEmpty) ...[
                Text(
                  'INSIGHTS',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                ..._report!.insights.take(3).map(_buildInsightTile),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 180,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCircle(double score) {
    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        children: [
          // Background circle
          CustomPaint(
            size: const Size(70, 70),
            painter: _ScoreCirclePainter(
              progress: score / 100,
              color: _report!.gradeColor,
              backgroundColor: Colors.white.withOpacity(0.1),
            ),
          ),
          // Score text
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  score.toStringAsFixed(0),
                  style: TextStyle(
                    color: _report!.gradeColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '/100',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    final categories = [
      ('Budget', _report!.categoryScores['budget'] ?? 0, 25, Icons.pie_chart),
      ('Debt', _report!.categoryScores['debt'] ?? 0, 25, Icons.account_balance),
      ('Savings', _report!.categoryScores['savings'] ?? 0, 25, Icons.savings),
      (
        'Liquidity',
        _report!.categoryScores['liquidity'] ?? 0,
        25,
        Icons.water_drop,
      ),
    ];

    return Row(
      children: categories.map((cat) {
        final (name, score, max, icon) = cat;
        final percentage = (score / max * 100).clamp(0, 100);
        return Expanded(
          child: Column(
            children: [
              Icon(icon, color: AppColors.textTertiary, size: 16),
              const SizedBox(height: 6),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: TextStyle(color: AppColors.textTertiary, fontSize: 10),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInsightTile(HealthInsight insight) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: insight.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(insight.icon, color: insight.color, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  insight.message,
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (insight.action != null)
            Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 16),
        ],
      ),
    );
  }

  String _getHealthMessage() {
    switch (_report!.grade) {
      case HealthGrade.excellent:
        return 'Outstanding financial management!';
      case HealthGrade.good:
        return 'You\'re on the right track';
      case HealthGrade.fair:
        return 'Room for improvement';
      case HealthGrade.needsWork:
        return 'Let\'s work on your finances';
      case HealthGrade.critical:
        return 'Immediate attention needed';
    }
  }
}

class _ScoreCirclePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _ScoreCirclePainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;
    const strokeWidth = 6.0;

    // Background arc
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      2 * math.pi * progress, // Sweep angle
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ScoreCirclePainter oldDelegate) =>
      progress != oldDelegate.progress || color != oldDelegate.color;
}
