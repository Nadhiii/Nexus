import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class TotalBalanceCard extends StatelessWidget {
  const TotalBalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AccountProvider, TransactionProvider>(
      builder: (context, accounts, transactions, _) {
        final totalBalance = accounts.accounts
            .where((a) => a.isActive)
            .fold(0.0, (sum, a) => sum + a.balance);

        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);
        final monthTxns = transactions.transactions
            .where((t) => t.date.isAfter(monthStart))
            .toList();

        final monthIncome = monthTxns
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (sum, t) => sum + t.amount);
        final monthExpense = monthTxns
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (sum, t) => sum + t.amount);
        final balanceAccent = totalBalance >= 0
            ? AppColors.success
            : AppColors.error;

        final runway = monthExpense > 0
            ? (totalBalance / (monthExpense / now.day * 30)).floor()
            : null;

        String runwayMsg;
        Color runwayColor;
        if (runway == null) {
          runwayMsg = 'No expenses this month';
          runwayColor = AppColors.textTertiary;
        } else if (runway >= 90) {
          runwayMsg = 'Runway: 3+ months 🟢';
          runwayColor = AppColors.pastelGreen;
        } else if (runway >= 30) {
          runwayMsg = 'Runway: ~$runway days';
          runwayColor = AppColors.pastelOrange;
        } else {
          runwayMsg = 'Runway: $runway days ⚠';
          runwayColor = AppColors.error;
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                balanceAccent.withValues(alpha: 0.24),
                AppColors.cardSurface,
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: balanceAccent.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL BALANCE',
                style: TextStyle(
                  color: balanceAccent.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '₹${NumberFormat('#,##,###').format(totalBalance)}',
                style: AppTypography.currencyLarge.copyWith(
                  color: balanceAccent,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                runwayMsg,
                style: TextStyle(color: runwayColor, fontSize: 12),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'Income',
                      value: monthIncome,
                      color: AppColors.pastelGreen,
                      icon: Icons.arrow_downward_rounded,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  Expanded(
                    child: _MiniStat(
                      label: 'Spent',
                      value: monthExpense,
                      color: AppColors.error,
                      icon: Icons.arrow_upward_rounded,
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

class _MiniStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: AppColors.textTertiary, fontSize: 10),
              ),
              Text(
                '₹${NumberFormat.compact().format(value)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
