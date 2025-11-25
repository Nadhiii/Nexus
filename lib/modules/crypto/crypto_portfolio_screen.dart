import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/providers/crypto_provider.dart';
import '../../core/models/crypto.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import 'add_crypto_screen.dart';
import 'edit_crypto_screen.dart';

class CryptoPortfolioScreen extends StatelessWidget {
  const CryptoPortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkGradient.first,
      appBar: AppBar(
        title: Text(
          'Crypto Portfolio',
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
                final provider = Provider.of<CryptoProvider>(
                  context,
                  listen: false,
                );
                provider.loadCryptos(user.uid);
              }
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<CryptoProvider>(
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
                        provider.loadCryptos(user.uid);
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentTeal,
                    ),
                  ),
                ],
              ),
            );
          }

          if (provider.cryptos.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await provider.loadCryptos(user.uid);
              }
            },
            child: _buildCryptoList(context, provider.cryptos),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCryptoScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Crypto'),
        backgroundColor: AppColors.accentTeal,
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
              Icons.currency_bitcoin,
              size: 100,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'No Crypto Holdings Yet',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Start tracking your cryptocurrency investments',
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
                    builder: (context) => const AddCryptoScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Crypto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentTeal,
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

  Widget _buildCryptoList(BuildContext context, List<Crypto> cryptos) {
    final totalCurrentValue = cryptos.fold<double>(
      0,
      (sum, crypto) => sum + (crypto.currentValue ?? 0),
    );

    final totalInvested = cryptos.fold<double>(
      0,
      (sum, crypto) => sum + (crypto.investedAmount ?? 0),
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
                AppColors.accentTeal,
                AppColors.accentTeal.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentTeal.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Portfolio Value',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '\$${NumberFormat('#,##0.00').format(totalCurrentValue)}',
                style: AppTypography.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 36,
                ),
              ),
              if (totalGainLoss.abs() >= 0.01 &&
                  totalGainLossPercent.isFinite) ...[
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
                      '${totalGainLoss >= 0 ? '+' : ''}\$${NumberFormat('#,##0.00').format(totalGainLoss)} (${totalGainLossPercent >= 0 ? '+' : ''}${totalGainLossPercent.toStringAsFixed(2)}%)',
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
                    'Total Holdings',
                    '${cryptos.where((c) => c.isActive).length}',
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  _buildStat(
                    'Invested',
                    '\$${NumberFormat('#,##0').format(totalInvested)}',
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.lg,
              bottom: 100, // Extra space for FAB
            ),
            itemCount: cryptos.length,
            itemBuilder: (context, index) {
              final crypto = cryptos[index];
              return _buildCryptoCard(context, crypto);
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

  Widget _buildCryptoCard(BuildContext context, Crypto crypto) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      color: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: InkWell(
        onTap: () {
          _showCryptoDetails(context, crypto);
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
                      color: crypto.isActive
                          ? AppColors.accentTeal.withOpacity(0.2)
                          : AppColors.textSecondary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      Icons.currency_bitcoin,
                      color: crypto.isActive
                          ? AppColors.accentTeal
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
                          crypto.name,
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          crypto.symbol.toUpperCase(),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
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
                      color: crypto.isActive
                          ? AppColors.success.withOpacity(0.2)
                          : AppColors.warning.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      crypto.isActive ? 'Active' : 'Inactive',
                      style: AppTypography.bodySmall.copyWith(
                        color: crypto.isActive
                            ? AppColors.success
                            : AppColors.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (crypto.currentValue != null) ...[
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
                          '\$${NumberFormat('#,##0.00').format(crypto.currentValue)}',
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (crypto.gainLoss != null &&
                        crypto.gainLossPercentage != null &&
                        crypto.gainLossPercentage!.abs() >= 0.01 &&
                        crypto.gainLossPercentage!.isFinite)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (crypto.gainLoss! >= 0
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
                              '${crypto.gainLoss! >= 0 ? '+' : ''}\$${NumberFormat('#,##0.00').format(crypto.gainLoss)}',
                              style: AppTypography.titleSmall.copyWith(
                                color: crypto.gainLoss! >= 0
                                    ? AppColors.success
                                    : AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${crypto.gainLossPercentage! >= 0 ? '+' : ''}${crypto.gainLossPercentage!.toStringAsFixed(2)}%',
                              style: AppTypography.bodySmall.copyWith(
                                color: crypto.gainLoss! >= 0
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
                      'Amount',
                      '${crypto.amount.toStringAsFixed(8)} ${crypto.symbol.toUpperCase()}',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoColumn(
                      'Purchase Price',
                      '\$${crypto.purchasePrice.toStringAsFixed(2)}',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoColumn(
                      crypto.currentPrice != null
                          ? 'Current Price'
                          : 'Purchase Date',
                      crypto.currentPrice != null
                          ? '\$${crypto.currentPrice!.toStringAsFixed(2)}'
                          : DateFormat('MMM yyyy').format(crypto.purchaseDate),
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _showCryptoDetails(BuildContext context, Crypto crypto) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              crypto.name,
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (crypto.notes != null && crypto.notes!.isNotEmpty) ...[
              Text(
                crypto.notes!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditCryptoScreen(crypto: crypto),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentTeal,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDelete(context, crypto);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error),
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

  void _confirmDelete(BuildContext context, Crypto crypto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text(
          'Delete Crypto',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete ${crypto.name}?',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<CryptoProvider>(
                context,
                listen: false,
              ).deleteCrypto(crypto.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Crypto deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
