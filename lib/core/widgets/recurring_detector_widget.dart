import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../services/transaction_match_service.dart';
import '../providers/transaction_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/debt_provider.dart';
import '../models/subscription.dart';

/// A widget that detects and displays potential recurring payments from transaction history.
/// Users can convert detected patterns into tracked subscriptions with one tap.
class RecurringDetectorWidget extends StatefulWidget {
  final VoidCallback? onViewAll;
  final Function(DetectedRecurring)? onCreateSubscription;

  const RecurringDetectorWidget({
    super.key,
    this.onViewAll,
    this.onCreateSubscription,
  });

  @override
  State<RecurringDetectorWidget> createState() =>
      _RecurringDetectorWidgetState();
}

class _RecurringDetectorWidgetState extends State<RecurringDetectorWidget> {
  List<DetectedRecurring>? _detectedPatterns;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _detectPatterns();
    });
  }

  void _detectPatterns() {
    final transactionProvider = context.read<TransactionProvider>();
    final subscriptionProvider = context.read<SubscriptionProvider>();
    final debtProvider = context.read<DebtProvider>();

    final patterns = TransactionMatchService.detectRecurringPatterns(
      transactions: transactionProvider.transactions,
      existingSubscriptions: subscriptionProvider.subscriptions,
      existingDebts: debtProvider.debts,
    );

    setState(() {
      _detectedPatterns = patterns;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_detectedPatterns == null || _detectedPatterns!.isEmpty) {
      return const SizedBox.shrink(); // Don't show if nothing detected
    }

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
                  color: AppColors.pastelPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: AppColors.pastelPurple,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Insights',
                      style: AppTypography.titleSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${_detectedPatterns!.length} potential recurring payment${_detectedPatterns!.length != 1 ? 's' : ''} found',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Detected patterns (show top 3)
          ..._detectedPatterns!.take(3).map(_buildPatternTile),

          // View All link
          if (_detectedPatterns!.length > 3) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: widget.onViewAll,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View all detected patterns',
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
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            'Analyzing transactions...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternTile(DetectedRecurring pattern) {
    final confidencePercent = (pattern.confidence * 100).toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: pattern.isDueInNextWeek
            ? Border.all(color: AppColors.pastelOrange.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          // Confidence indicator
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getConfidenceColor(
                    pattern.confidence,
                  ).withValues(alpha: 0.2),
                  _getConfidenceColor(
                    pattern.confidence,
                  ).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '$confidencePercent%',
                style: TextStyle(
                  color: _getConfidenceColor(pattern.confidence),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pattern.suggestedName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (pattern.isDueInNextWeek)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.pastelOrange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Due soon',
                          style: TextStyle(
                            color: AppColors.pastelOrange,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '₹${NumberFormat('#,##0').format(pattern.amount)}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      ' • ${pattern.frequencyLabel} • ${pattern.occurrences} times',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Add button
          GestureDetector(
            onTap: () => _showAddSubscriptionDialog(pattern),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.add, color: AppColors.primaryBlue, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) {
      return AppColors.green;
    }
    if (confidence >= 0.6) {
      return AppColors.pastelOrange;
    }
    return AppColors.textTertiary;
  }

  void _showAddSubscriptionDialog(DetectedRecurring pattern) {
    if (widget.onCreateSubscription != null) {
      widget.onCreateSubscription!(pattern);
    } else {
      // Default behavior - show a dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Track as Subscription?',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We detected "${pattern.suggestedName}" as a recurring payment.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              _buildDialogDetailRow(
                'Amount',
                '₹${NumberFormat('#,##0').format(pattern.amount)}',
              ),
              _buildDialogDetailRow('Frequency', pattern.frequencyLabel),
              _buildDialogDetailRow(
                'Next expected',
                DateFormat('MMM d, y').format(pattern.nextPredictedDate),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Maybe later',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _createSubscription(pattern);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Track it'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDialogDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _createSubscription(DetectedRecurring pattern) async {
    final subscriptionProvider = context.read<SubscriptionProvider>();

    try {
      final newSubscription = Subscription(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '', // Will be set by provider
        name: pattern.suggestedName,
        amount: pattern.amount,
        frequency: pattern.frequency,
        nextDueDate: pattern.nextPredictedDate,
        categoryId: 'bills', // Default category
        accountId: '', // Will need to be selected
        isActive: true,
        color: AppColors.primaryBlue.toARGB32().toRadixString(16),
        createdAt: DateTime.now(),
      );

      await subscriptionProvider.addSubscription(newSubscription);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subscription "${pattern.suggestedName}" added'),
            backgroundColor: AppColors.green,
          ),
        );

        // Refresh patterns
        _detectPatterns();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red),
        );
      }
    }
  }
}
