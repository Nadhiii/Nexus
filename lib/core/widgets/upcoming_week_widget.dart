import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../services/financial_health_service.dart';
import '../providers/debt_provider.dart';
import '../providers/subscription_provider.dart';

/// A compact dashboard widget showing all upcoming financial obligations
/// for the next 7 days across subscriptions, EMIs, goals, and SIPs.
class UpcomingWeekWidget extends StatefulWidget {
  final VoidCallback? onViewAll;

  const UpcomingWeekWidget({super.key, this.onViewAll});

  @override
  State<UpcomingWeekWidget> createState() => _UpcomingWeekWidgetState();
}

class _UpcomingWeekWidgetState extends State<UpcomingWeekWidget> {
  UpcomingObligations? _obligations;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateUpcoming();
    });
  }

  void _calculateUpcoming() {
    final debtProvider = context.read<DebtProvider>();
    final subscriptionProvider = context.read<SubscriptionProvider>();

    final obligations = UpcomingObligations.calculate(
      debts: debtProvider.debts,
      subscriptions: subscriptionProvider.subscriptions,
      daysAhead: 7,
    );

    setState(() {
      _obligations = obligations;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_obligations == null) {
      return _buildLoadingState();
    }

    final upcomingPayments =
        _obligations!.payments
            .where(
              (p) => p.dueDate.isBefore(
                DateTime.now().add(const Duration(days: 7)),
              ),
            )
            .toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    if (upcomingPayments.isEmpty) {
      return _buildEmptyState();
    }

    final totalDue = upcomingPayments.fold(0.0, (sum, p) => sum + p.amount);
    final groupedByDay = _groupByDay(upcomingPayments);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.pastelOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: AppColors.pastelOrange,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next 7 Days',
                      style: AppTypography.titleSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${upcomingPayments.length} payment${upcomingPayments.length != 1 ? 's' : ''} due',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '₹${_formatAmount(totalDue)}',
                  style: TextStyle(
                    color: AppColors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Day-by-day breakdown
          ...groupedByDay.entries
              .take(4)
              .map((entry) => _buildDaySection(entry.key, entry.value)),

          // View All link
          if (upcomingPayments.length > 4 || groupedByDay.length > 4) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: widget.onViewAll,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View all upcoming',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    color: AppColors.primaryBlue,
                    size: 14,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 150,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.check_circle_outline,
              color: AppColors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All caught up!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'No payments due in the next 7 days',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySection(String dayLabel, List<UpcomingPayment> payments) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dayLabel,
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          ...payments.map((payment) => _buildPaymentTile(payment)),
        ],
      ),
    );
  }

  Widget _buildPaymentTile(UpcomingPayment payment) {
    final typeColor = _getPaymentTypeColor(payment.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(payment.icon, style: const TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _getPaymentSubtitle(payment),
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 10),
                ),
              ],
            ),
          ),
          Text(
            '₹${_formatAmount(payment.amount)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPaymentTypeColor(PaymentType type) {
    switch (type) {
      case PaymentType.emi:
        return AppColors.pastelPurple;
      case PaymentType.subscription:
        return AppColors.primaryBlue;
      case PaymentType.bill:
        return AppColors.pastelOrange;
      case PaymentType.goal:
        return AppColors.pastelGreen;
    }
  }

  String _getPaymentSubtitle(UpcomingPayment payment) {
    final typeLabel = payment.type.name.toUpperCase();
    if (payment.isDueToday) {
      return '$typeLabel • Due today';
    } else if (payment.isDueTomorrow) {
      return '$typeLabel • Due tomorrow';
    } else {
      return '$typeLabel • ${DateFormat('MMM d').format(payment.dueDate)}';
    }
  }

  Map<String, List<UpcomingPayment>> _groupByDay(
    List<UpcomingPayment> payments,
  ) {
    final grouped = <String, List<UpcomingPayment>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    for (final payment in payments) {
      final paymentDate = DateTime(
        payment.dueDate.year,
        payment.dueDate.month,
        payment.dueDate.day,
      );

      String label;
      if (paymentDate == today) {
        label = 'TODAY';
      } else if (paymentDate == tomorrow) {
        label = 'TOMORROW';
      } else {
        label = DateFormat('EEEE, MMM d').format(payment.dueDate).toUpperCase();
      }

      grouped.putIfAbsent(label, () => []).add(payment);
    }

    return grouped;
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}K';
    }
    return NumberFormat('#,##0').format(amount);
  }
}
