import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/models/subscription.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import 'widgets/add_subscription_modal.dart';

class ModernSubscriptionScreen extends StatefulWidget {
  const ModernSubscriptionScreen({super.key});

  @override
  State<ModernSubscriptionScreen> createState() => _ModernSubscriptionScreenState();
}

class _ModernSubscriptionScreenState extends State<ModernSubscriptionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkGradient.first,
      body: Consumer<SubscriptionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.subscriptions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return _buildErrorState(context, provider);
          }

          if (provider.subscriptions.isEmpty) {
            return _buildEmptyState(context);
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCard(provider),
                      const SizedBox(height: AppSpacing.lg),
                      _buildFilterChips(provider),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Your Subscriptions',
                        style: AppTypography.titleLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
              _buildSubscriptionsList(context, provider),
              const SliverToBoxAdapter(
                child: SizedBox(height: 140),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          onPressed: () => showAddSubscriptionModal(context),
          backgroundColor: AppColors.accentOrange,
          icon: const Icon(Icons.add),
          label: const Text('Add Subscription'),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.darkGradient.first,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Subscriptions',
          style: AppTypography.titleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
    );
  }

  Widget _buildSummaryCard(SubscriptionProvider provider) {
    return Container(
      padding: AppSpacing.cardPaddingXl,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF9500),
            Color(0xFFFF8000),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentOrange.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Total',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '₹',
                style: AppTypography.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  provider.totalMonthlyCost.toStringAsFixed(2),
                  style: AppTypography.currencyLarge.copyWith(
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${provider.activeSubscriptionCount} active • ${provider.totalSubscriptionCount} total • Yearly ₹${(provider.totalYearlyCost / 1000).toStringAsFixed(1)}K',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(SubscriptionProvider provider) {
    final filters = ['all', 'monthly', 'yearly', 'weekly', 'daily'];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = provider.filterFrequency == filter;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.cardDarkElevated
                    : AppColors.cardDark,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: InkWell(
                onTap: () => provider.setFrequencyFilter(filter),
                child: Center(
                  child: Text(
                    filter[0].toUpperCase() + filter.substring(1),
                    style: AppTypography.bodyMedium.copyWith(
                      color: isSelected
                          ? AppColors.accentOrange
                          : Colors.white.withOpacity(0.6),
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubscriptionsList(BuildContext context, SubscriptionProvider provider) {
    final subscriptions = provider.filteredSubscriptions;

    if (subscriptions.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: Column(
            children: [
              Icon(
                Icons.filter_list_off,
                size: 64,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'No subscriptions found',
                style: AppTypography.bodyLarge.copyWith(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final subscription = subscriptions[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _buildSubscriptionCard(context, subscription, provider),
            );
          },
          childCount: subscriptions.length,
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(
    BuildContext context,
    Subscription subscription,
    SubscriptionProvider provider,
  ) {
    final isOverdue = subscription.isOverdue;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardDarkElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: isOverdue
            ? Border.all(color: AppColors.error.withOpacity(0.3), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Center(
                  child: Text(
                    subscription.name.substring(0, 1).toUpperCase(),
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.accentOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.name,
                      style: AppTypography.titleSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${subscription.frequency.toUpperCase()} • Next: ${DateFormat('MMM dd').format(subscription.nextDueDate)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${subscription.amount.toStringAsFixed(2)}',
                    style: AppTypography.titleSmall.copyWith(
                      color: isOverdue ? AppColors.error : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: subscription.isActive
                          ? Colors.green.withOpacity(0.15)
                          : Colors.grey.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      subscription.isActive ? 'Active' : 'Paused',
                      style: AppTypography.bodySmall.copyWith(
                        color: subscription.isActive ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (subscription.description?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              subscription.description!,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.5),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
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
              Icons.subscriptions_outlined,
              size: 120,
              color: AppColors.accentOrange.withOpacity(0.3),
            ),
            const SizedBox(height: AppSpacing.xl2),
            Text(
              'No Subscriptions Yet',
              style: AppTypography.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Add your first subscription to track your recurring expenses',
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.xl2),
            ElevatedButton.icon(
              onPressed: () => showAddSubscriptionModal(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentOrange,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl2,
                  vertical: AppSpacing.lg,
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Subscription'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, SubscriptionProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error.withOpacity(0.7),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              provider.error!,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () => provider.initialize(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentOrange,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
