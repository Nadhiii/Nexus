import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/modern/modern_widgets.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/account.dart';
import '../../core/models/transaction.dart';
import '../transactions/modern_add_transaction_screen.dart';

/// Modern Dashboard Screen - Revolut-inspired design
/// Features: Gradient background, modern balance card, quick actions, clean layout
class ModernDashboardScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const ModernDashboardScreen({super.key, this.onNavigate});

  @override
  State<ModernDashboardScreen> createState() => _ModernDashboardScreenState();
}

class _ModernDashboardScreenState extends State<ModernDashboardScreen> {
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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
            child: RefreshIndicator(
              onRefresh: () async {
                // TODO: Refresh dashboard data
                await Future.delayed(const Duration(seconds: 1));
              },
              child: CustomScrollView(
                slivers: [
                  // Modern App Bar
                  SliverToBoxAdapter(child: _buildModernAppBar(context)),

                  // Balance Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.xl,
                        AppSpacing.xl,
                        AppSpacing.lg,
                      ),
                      child: StreamBuilder<List<Account>>(
                        stream: FirestoreService.getAccountsStream(),
                        builder: (context, snapshot) {
                          double totalBalance = 0.0;
                          int accountCount = 0;

                          if (snapshot.hasData && snapshot.data != null) {
                            final accounts = snapshot.data!
                                .where((a) => a.isActive)
                                .toList();
                            totalBalance = accounts.fold(
                              0.0,
                              (sum, account) => sum + account.balance,
                            );
                            accountCount = accounts.length;
                          }

                          return ModernBalanceCard(
                            title: 'Total Balance',
                            amount: totalBalance,
                            currency: '₹',
                            subtitle:
                                'Personal · $accountCount ${accountCount == 1 ? 'account' : 'accounts'}',
                            gradientColors: AppColors.blueGradient,
                            trailing: GestureDetector(
                              onTap: () {
                                // Navigate to accounts screen (index 1)
                                if (widget.onNavigate != null) {
                                  widget.onNavigate!(1);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusFull,
                                  ),
                                ),
                                child: const Text(
                                  'Accounts',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Quick Actions
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ModernActionButton(
                            icon: Icons.add_circle_outline,
                            label: 'Add\nTransaction',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ModernAddTransactionScreen(),
                                ),
                              );
                            },
                            backgroundColor: AppColors.cardDarkElevated,
                          ),
                          ModernActionButton(
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'Accounts',
                            onTap: () {
                              if (widget.onNavigate != null) {
                                widget.onNavigate!(
                                  1,
                                ); // Navigate to Accounts screen
                              }
                            },
                            backgroundColor: AppColors.cardDarkElevated,
                          ),
                          ModernActionButton(
                            icon: Icons.trending_up_outlined,
                            label: 'Analytics',
                            onTap: () {
                              if (widget.onNavigate != null) {
                                widget.onNavigate!(
                                  2,
                                ); // Navigate to Finance Hub
                              }
                            },
                            backgroundColor: AppColors.cardDarkElevated,
                          ),
                          ModernActionButton(
                            icon: Icons.receipt_long_outlined,
                            label: 'Transactions',
                            onTap: () {
                              if (widget.onNavigate != null) {
                                widget.onNavigate!(
                                  4,
                                ); // Navigate to Transactions screen
                              }
                            },
                            backgroundColor: AppColors.cardDarkElevated,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xl2),
                  ),

                  // Recent Transactions Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.xl,
                        AppSpacing.xl,
                        AppSpacing.md,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Transactions',
                            style: AppTypography.titleLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (widget.onNavigate != null) {
                                widget.onNavigate!(
                                  4,
                                ); // Navigate to Transactions screen
                              }
                            },
                            child: Text(
                              'View All',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Recent Transactions List
                  StreamBuilder<List<Transaction>>(
                    stream: FirestoreService.getTransactionsStream(limit: 5),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.xl),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                            ),
                            padding: AppSpacing.cardPaddingLg,
                            decoration: BoxDecoration(
                              color: AppColors.cardDarkElevated,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusLg,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 48,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'No transactions yet',
                                    style: AppTypography.bodyLarge.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'Add your first transaction to get started',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      return SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final transaction = snapshot.data![index];
                          final isIncome =
                              transaction.type == TransactionType.income;
                          final amountText =
                              '₹${transaction.amount.toStringAsFixed(2)}';

                          return Padding(
                            padding: EdgeInsets.only(
                              left: AppSpacing.xl,
                              right: AppSpacing.xl,
                              bottom: index == snapshot.data!.length - 1
                                  ? 0
                                  : AppSpacing.sm,
                            ),
                            child: ModernTransactionTile(
                              title: transaction.description ?? 'Transaction',
                              subtitle: _formatTransactionDate(
                                transaction.date,
                              ),
                              amount: amountText,
                              isIncome: isIncome,
                              icon: isIncome
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              onTap: () {
                                // TODO: Show transaction details
                              },
                            ),
                          );
                        }, childCount: snapshot.data!.length),
                      );
                    },
                  ),

                  // Bottom Padding (for floating nav bar)
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Icons Row - slides off screen when search expands
          AnimatedPositioned(
            duration: const Duration(milliseconds: 450),
            curve: Curves.fastEaseInToSlowEaseOut,
            left: _isSearchExpanded ? -80 : 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Profile Avatar
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  opacity: _isSearchExpanded ? 0 : 1,
                  child: IgnorePointer(
                    ignoring: _isSearchExpanded,
                    child: GestureDetector(
                      onTap: () {
                        if (widget.onNavigate != null) {
                          widget.onNavigate!(
                            5,
                          ); // Navigate to More/Settings screen
                        }
                      },
                      child: Builder(
                        builder: (context) {
                          final user = FirebaseAuth.instance.currentUser;
                          return Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.accentPurple,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 2,
                              ),
                              image: user?.photoURL != null
                                  ? DecorationImage(
                                      image: NetworkImage(user!.photoURL!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: user?.photoURL == null
                                ? Icon(
                                    user?.isAnonymous == true
                                        ? Icons.person_off
                                        : Icons.person,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : null,
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Stats Icon
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  opacity: _isSearchExpanded ? 0 : 1,
                  child: IgnorePointer(
                    ignoring: _isSearchExpanded,
                    child: GestureDetector(
                      onTap: () {
                        if (widget.onNavigate != null) {
                          widget.onNavigate!(
                            2,
                          ); // Navigate to Finance Hub/Analytics screen
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        child: const Icon(
                          Icons.bar_chart,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: AppSpacing.sm),

                // Menu Icon
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  opacity: _isSearchExpanded ? 0 : 1,
                  child: IgnorePointer(
                    ignoring: _isSearchExpanded,
                    child: Consumer<NotificationProvider>(
                      builder: (context, notificationProvider, child) {
                        return Stack(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.menu,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () {
                                  // Handle menu press
                                },
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            if (notificationProvider.hasUnread)
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.neutral900,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar - Expands to cover whole app bar
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 400),
            curve: _isSearchExpanded ? Curves.easeOutCubic : Curves.easeInCubic,
            tween: Tween<double>(begin: 0, end: _isSearchExpanded ? 1 : 0),
            builder: (context, value, child) {
              return Container(
                margin: EdgeInsets.only(
                  left: 56 - (56 * value),
                  right: 96 - (96 * value),
                ),
                child: child,
              );
            },
            child: GestureDetector(
              onTap: () {
                if (!_isSearchExpanded) {
                  setState(() {
                    _isSearchExpanded = true;
                  });
                  Future.delayed(const Duration(milliseconds: 100), () {
                    _searchFocusNode.requestFocus();
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(
                    _isSearchExpanded ? 0.15 : 0.1,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Row(
                  children: [
                    // Back button (when expanded) or Search icon (when collapsed)
                    _isSearchExpanded
                        ? IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                _isSearchExpanded = false;
                                _searchController.clear();
                              });
                              _searchFocusNode.unfocus();
                            },
                          )
                        : Icon(
                            Icons.search,
                            color: Colors.white.withOpacity(0.6),
                            size: 20,
                          ),
                    const SizedBox(width: AppSpacing.sm),
                    // TextField (when expanded) or placeholder text (when collapsed)
                    Expanded(
                      child: _isSearchExpanded
                          ? Theme(
                              data: Theme.of(context).copyWith(
                                inputDecorationTheme:
                                    const InputDecorationTheme(
                                      filled: false,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      focusedErrorBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                              ),
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search anything...',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  focusedErrorBorder: InputBorder.none,
                                  filled: false,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 14,
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() {});
                                },
                              ),
                            )
                          : Text(
                              'Search...',
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                    ),
                    // Clear button (only when expanded and has text)
                    if (_isSearchExpanded && _searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: Colors.white,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTransactionDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
