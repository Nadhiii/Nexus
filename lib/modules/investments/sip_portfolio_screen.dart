import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/providers/investment_provider.dart';
import '../../core/models/investment.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/top_snackbar.dart';
import 'add_investment_screen.dart';
import 'edit_investment_screen.dart';

class SipPortfolioScreen extends StatelessWidget {
  const SipPortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: Text(
          'My SIPs',
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final provider = Provider.of<InvestmentProvider>(
                  context,
                  listen: false,
                );
                provider.loadInvestments(user.uid);
              }
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<InvestmentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    provider.error!,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton.icon(
                    onPressed: () {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        provider.loadInvestments(user.uid);
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            );
          }

          if (provider.investments.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await provider.loadInvestments(user.uid);
              }
            },
            child: _buildSipList(context, provider.investments),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddInvestmentScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add SIP'),
        backgroundColor: AppColors.primaryBlue,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              size: 100,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'No SIPs Yet',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Start your investment journey by adding your first SIP',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl2),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddInvestmentScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Your First SIP'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSipList(BuildContext context, List<Investment> sips) {
    final totalMonthly = sips.fold<double>(
      0,
      (sum, sip) => sum + (sip.isActive ? sip.sipAmount : 0),
    );

    final totalCurrentValue = sips.fold<double>(
      0,
      (sum, sip) => sum + (sip.currentValue ?? 0),
    );

    final totalInvested = sips.fold<double>(
      0,
      (sum, sip) => sum + (sip.investedAmount ?? 0),
    );

    final totalGainLoss = totalCurrentValue - totalInvested;
    final totalGainLossPercent = totalInvested > 0
        ? (totalGainLoss / totalInvested) * 100
        : 0.0;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(AppSpacing.lg),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryBlue,
                AppColors.primaryBlue.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Portfolio Value',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                totalCurrentValue > 0
                    ? '₹${NumberFormat('#,##,###.00').format(totalCurrentValue)}'
                    : '₹${NumberFormat('#,##,###').format(totalMonthly)}',
                style: AppTypography.displayMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (totalGainLoss != 0) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      totalGainLoss >= 0
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${totalGainLoss >= 0 ? '+' : ''}₹${NumberFormat('#,##,###.00').format(totalGainLoss)} (${totalGainLossPercent >= 0 ? '+' : ''}${totalGainLossPercent.toStringAsFixed(2)}%)',
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _buildStat(
                    'Active SIPs',
                    '${sips.where((s) => s.isActive).length}',
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  _buildStat(
                    'Monthly',
                    '₹${NumberFormat('#,##,###').format(totalMonthly)}',
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: sips.length,
            itemBuilder: (context, index) {
              final sip = sips[index];
              return _buildSipCard(context, sip);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSipCard(BuildContext context, Investment sip) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      color: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: InkWell(
        onTap: () {
          _showSipDetails(context, sip);
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: sip.isActive
                          ? AppColors.success.withOpacity(0.2)
                          : AppColors.textSecondary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      Icons.trending_up,
                      color: sip.isActive
                          ? AppColors.success
                          : AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sip.name,
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          sip.mutualFundSchemeName,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: sip.isActive
                          ? AppColors.success.withOpacity(0.2)
                          : AppColors.warning.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      sip.isActive ? 'Active' : 'Paused',
                      style: AppTypography.bodySmall.copyWith(
                        color: sip.isActive
                            ? AppColors.success
                            : AppColors.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (sip.currentValue != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Value',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '₹${NumberFormat('#,##,###.00').format(sip.currentValue)}',
                          style: AppTypography.headlineSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (sip.gainLoss != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (sip.gainLoss! >= 0
                                      ? AppColors.success
                                      : AppColors.error)
                                  .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${sip.gainLoss! >= 0 ? '+' : ''}₹${NumberFormat('#,##,###.00').format(sip.gainLoss)}',
                              style: AppTypography.titleSmall.copyWith(
                                color: sip.gainLoss! >= 0
                                    ? AppColors.success
                                    : AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${sip.gainLossPercentage! >= 0 ? '+' : ''}${sip.gainLossPercentage!.toStringAsFixed(2)}%',
                              style: AppTypography.bodySmall.copyWith(
                                color: sip.gainLoss! >= 0
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Divider(color: AppColors.textSecondary.withOpacity(0.2)),
                const SizedBox(height: AppSpacing.md),
              ],
              Row(
                children: [
                  Expanded(
                    child: _buildInfoColumn(
                      'Monthly SIP',
                      '₹${NumberFormat('#,##,###').format(sip.sipAmount)}',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoColumn(
                      'Invested',
                      sip.investedAmount != null
                          ? '₹${NumberFormat('#,##,###').format(sip.investedAmount)}'
                          : '-',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoColumn(
                      sip.currentNav != null ? 'Current NAV' : 'Started',
                      sip.currentNav != null
                          ? '₹${sip.currentNav!.toStringAsFixed(4)}'
                          : DateFormat('MMM yyyy').format(sip.startDate),
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

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showSipDetails(BuildContext context, Investment sip) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFF0A0E21),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.md),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      sip.name,
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _buildDetailRow('Fund Name', sip.mutualFundSchemeName),
                  _buildDetailRow('Scheme Code', sip.mutualFundSchemeCode),
                  _buildDetailRow(
                    'Monthly Amount',
                    '₹${NumberFormat('#,##,###').format(sip.sipAmount)}',
                  ),
                  _buildDetailRow('SIP Date', '${sip.sipDay} of every month'),
                  _buildDetailRow(
                    'Start Date',
                    DateFormat('dd MMM yyyy').format(sip.startDate),
                  ),
                  _buildDetailRow('Status', sip.isActive ? 'Active' : 'Paused'),
                  if (sip.notes != null && sip.notes!.isNotEmpty)
                    _buildDetailRow('Notes', sip.notes!),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _toggleSipStatus(context, sip);
                          },
                          icon: Icon(
                            sip.isActive ? Icons.pause : Icons.play_arrow,
                          ),
                          label: Text(sip.isActive ? 'Pause' : 'Resume'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: BorderSide(
                              color: AppColors.textSecondary.withOpacity(0.3),
                            ),
                            padding: const EdgeInsets.all(AppSpacing.md),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _editSip(context, sip);
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            padding: const EdgeInsets.all(AppSpacing.md),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteSip(context, sip);
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete Investment'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.all(AppSpacing.md),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editSip(BuildContext context, Investment sip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditInvestmentScreen(investment: sip),
      ),
    );
  }

  void _toggleSipStatus(BuildContext context, Investment sip) {
    final provider = context.read<InvestmentProvider>();
    provider.updateInvestment(
      sip.copyWith(isActive: !sip.isActive, updatedAt: DateTime.now()),
    );
    showTopSnackBar(
      context,
      sip.isActive ? 'SIP paused successfully' : 'SIP resumed successfully',
    );
  }

  void _deleteSip(BuildContext context, Investment sip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text(
          'Delete SIP',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${sip.name}"? This action cannot be undone.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<InvestmentProvider>().deleteInvestment(sip.id);
              showTopSnackBar(context, 'SIP deleted successfully');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
