import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/modern/modern_widgets.dart';
import '../../core/providers/account_provider.dart';
import 'modern_add_account_screen.dart';
import 'modern_account_detail_screen.dart';

/// Modern Accounts Screen - Revolut-inspired design
/// Features: Gradient background, modern cards, percentage bars, clean layout
class ModernAccountsScreen extends StatefulWidget {
  const ModernAccountsScreen({super.key});

  @override
  State<ModernAccountsScreen> createState() => _ModernAccountsScreenState();
}

class _ModernAccountsScreenState extends State<ModernAccountsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppColors.darkGradient,
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: Consumer<AccountProvider>(
              builder: (context, accountProvider, child) {
                if (accountProvider.isLoading && accountProvider.accounts.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (accountProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          accountProvider.error!,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ElevatedButton(
                          onPressed: () => accountProvider.loadAccounts(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                
                final accounts = accountProvider.accounts.where((a) => a.isActive).toList();
                final totalBalance = accounts.fold(0.0, (sum, account) => sum + account.balance);
                
                if (accounts.isEmpty) {
                  return _buildEmptyState();
                }
                
                return CustomScrollView(
                  slivers: [
                    // App Bar
                    SliverToBoxAdapter(
                      child: _buildAppBar(context),
                    ),
                    
                    // Total Balance Card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          AppSpacing.lg,
                          AppSpacing.xl,
                          AppSpacing.xl,
                        ),
                        child: ModernBalanceCard(
                          title: 'Total Balance',
                          amount: totalBalance,
                          currency: '₹',
                          subtitle: '${accounts.length} ${accounts.length == 1 ? 'account' : 'accounts'}',
                          gradientColors: AppColors.tealGradient,
                          trailing: GestureDetector(
                            onTap: () => _navigateToAddAccount(),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Accounts Section Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          AppSpacing.md,
                          AppSpacing.xl,
                          AppSpacing.md,
                        ),
                        child: Text(
                          'Your Accounts',
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    // Accounts List
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final account = accounts[index];
                            final percentage = totalBalance > 0 
                                ? (account.balance / totalBalance * 100) 
                                : 0.0;
                            
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index == accounts.length - 1 ? 120 : AppSpacing.md,
                              ),
                              child: ModernAccountTile(
                                name: account.name,
                                balance: '₹${account.balance.toStringAsFixed(2)}',
                                icon: account.icon,
                                iconColor: account.color,
                                percentage: '${percentage.toStringAsFixed(1)}% • ${account.typeDisplayName}',
                                onTap: () => _navigateToAccountDetail(account),
                              ),
                            );
                          },
                          childCount: accounts.length,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Accounts',
            style: AppTypography.displaySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.add,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () => _navigateToAddAccount(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl3),
              decoration: BoxDecoration(
                color: AppColors.cardDarkElevated,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 64,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'No Accounts Yet',
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Add your first account to start\ntracking your finances',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl2),
            ElevatedButton.icon(
              onPressed: () => _navigateToAddAccount(),
              icon: const Icon(Icons.add),
              label: const Text('Add Account'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl2,
                  vertical: AppSpacing.lg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddAccount() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ModernAddAccountScreen(),
      ),
    );
  }

  void _navigateToAccountDetail(account) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ModernAccountDetailScreen(account: account),
      ),
    );
  }
}
