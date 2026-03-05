import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/transaction.dart';
import '../../../core/theme/app_colors.dart';

class CashFlowHeroCard extends StatelessWidget {
  final List<Transaction> transactions;

  const CashFlowHeroCard({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    double totalIncome = 0;
    double totalExpense = 0;

    for (var tx in transactions) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        totalExpense += tx.amount;
      }
    }

    final netSavings = totalIncome - totalExpense;
    final isPositive = netSavings >= 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E293B), // Slate 800
            const Color(0xFF0F172A), // Slate 900
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
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
                'NET SAVINGS',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPositive ? AppColors.success : AppColors.error)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPositive ? 'PROFIT' : 'LOSS',
                  style: TextStyle(
                    color: isPositive ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${isPositive ? '+' : ''}₹${NumberFormat('#,##,###').format(netSavings)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  label: "Income",
                  value: totalIncome,
                  color: AppColors.success,
                  icon: Icons.arrow_downward,
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              Expanded(
                child: _buildStatItem(
                  label: "Expense",
                  value: totalExpense,
                  color: AppColors.error,
                  icon: Icons.arrow_upward,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required double value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '₹${NumberFormat.compact().format(value)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
