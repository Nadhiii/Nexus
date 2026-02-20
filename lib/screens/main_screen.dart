import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'dart:ui'; // Required for ImageFilter
import 'package:animations/animations.dart'; // Required for PageTransitionSwitcher

import '../core/providers/is_popup_active_provider.dart';
import '../core/providers/new_nbox_provider.dart';
import '../core/providers/account_provider.dart';
import '../core/providers/debt_provider.dart';
import '../core/providers/investment_provider.dart';
import '../core/providers/subscription_provider.dart';
import '../core/providers/transaction_provider.dart';
import '../core/providers/budget_provider.dart';
import '../core/providers/goal_provider.dart';
import '../core/providers/bike_provider.dart';
import '../core/providers/pdf_import_provider.dart';
import '../core/providers/shared_expense_provider.dart';
import '../core/providers/category_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_animations.dart';
import '../modules/Nex/providers/Nex_assistant_provider.dart';

// Screens
import '../modules/dashboard/modern_dashboard_screen.dart';
import '../modules/finance/modern_finance_screen.dart';
import '../modules/insights/modern_insights_screen.dart';
import '../modules/more/modern_more_screen.dart';
import '../modules/bike/ui/modern_bike_screen_ui.dart';
import '../modules/nbox/new_modern_nbox_screen.dart';
import '../core/services/intent_navigation_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _financeScreenInitialTab = 0;
  bool _aiInitialized = false;
  AnimationController? _navAnimationController;
  Animation<double>? _navAnimation;
  int _previousIndex = 0;
  StreamSubscription<int>? _intentSub;

  @override
  void initState() {
    super.initState();
    _navAnimationController = AnimationController(
      duration: AppAnimations.navDuration,
      vsync: this,
    );
    _navAnimation = CurvedAnimation(
      parent: _navAnimationController!,
      curve: AppAnimations.standardCurve,
    );

    _intentSub = IntentNavigationService.tabStream.listen((tabIndex) {
      if (!mounted) return;
      _navigateToScreen(tabIndex);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeAI(context);
  }

  @override
  void dispose() {
    _navAnimationController?.dispose();
    _intentSub?.cancel();
    super.dispose();
  }

  void _navigateToScreen(int index, {int? financeTab}) {
    if (index == _currentIndex) return;
    setState(() {
      _previousIndex = _currentIndex;
      _financeScreenInitialTab = financeTab ?? 0;
      _currentIndex = index;
    });
    _navAnimationController?.forward(from: 0);
  }

  void _initializeAI(BuildContext context) {
    if (_aiInitialized) return;
    _aiInitialized = true;

    final aiProvider = context.read<AIAssistantProvider>();
    aiProvider.initialize();
    aiProvider.setContextProviders(
      accountProvider: context.read<AccountProvider>(),
      debtProvider: context.read<DebtProvider>(),
      investmentProvider: context.read<InvestmentProvider>(),
      subscriptionProvider: context.read<SubscriptionProvider>(),
      transactionProvider: context.read<TransactionProvider>(),
      budgetProvider: context.read<BudgetProvider>(),
      goalProvider: context.read<GoalProvider>(),
      bikeProvider: context.read<BikeProvider>(),
      nboxProvider: context.read<NewNboxProvider>(),
      pdfImportProvider: context.read<PDFImportProvider>(),
      sharedExpenseProvider: context.read<SharedExpenseProvider>(),
      categoryProvider: context.read<CategoryProvider>(),
    );

    // Share Gemini API key with PDF parser
    if (aiProvider.settings.hasGeminiKey &&
        aiProvider.settings.geminiApiKey != null) {
      context.read<PDFImportProvider>().setGeminiApiKeyForPDF(
        aiProvider.settings.geminiApiKey!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Screen List (Nex moved to More screen)
    final screens = [
      ModernDashboardScreen(onNavigate: _navigateToScreen),
      ModernFinanceScreen(initialTabIndex: _financeScreenInitialTab),
      const ModernInsightsScreen(),
      const ModernBikeScreen(),
      const NewModernNBoxScreen(),
      const ModernMoreScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: Stack(
        children: [
          // 1. Main Content with Fade Transition
          PageTransitionSwitcher(
            duration: AppAnimations.pageTransitionDuration,
            transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
              return FadeThroughTransition(
                animation: primaryAnimation,
                secondaryAnimation: secondaryAnimation,
                fillColor: AppColors.backgroundBlack,
                child: child,
              );
            },
            child: screens[_currentIndex],
          ),
        ],
      ),
      // 2. Floating Navigation Bar (outside body to prevent keyboard overlap)
      bottomNavigationBar: _buildFloatingNavBar(context, _currentIndex),
    );
  }

  Widget _buildFloatingNavBar(BuildContext context, int currentIndex) {
    // "Floating Pill" Container
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      height: 72, // Slightly taller for better touch targets
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        boxShadow: [
          // Deep soft shadow for "Floating" effect
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: ValueListenableBuilder<bool>(
          valueListenable: isPopupActiveNotifier,
          builder: (context, isPopupActive, child) {
            return BackdropFilter(
              filter: isPopupActive
                  ? ImageFilter.blur(
                      sigmaX: 0,
                      sigmaY: 0,
                    ) // No Blur if popup (optimization)
                  : ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Frosted Glass
              child: Container(
                decoration: BoxDecoration(
                  // Dark Slate with Opacity
                  color: AppColors.cardSurface.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1), // Subtle white border
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _buildNavItems(currentIndex),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildNavItems(int currentIndex) {
    final items = [
      {
        'icon': Icons.dashboard_outlined,
        'selectedIcon': Icons.dashboard_rounded,
        'label': 'Home',
        'index': 0,
      },
      {
        'icon': Icons.account_balance_wallet_outlined,
        'selectedIcon': Icons.account_balance_wallet_rounded,
        'label': 'Wallet',
        'index': 1,
      },
      {
        'icon': Icons.pie_chart_outline,
        'selectedIcon': Icons.pie_chart_rounded,
        'label': 'Wealth',
        'index': 2,
      },
      {
        'icon': Icons.two_wheeler_outlined,
        'selectedIcon': Icons.two_wheeler_rounded,
        'label': 'Garage',
        'index': 3,
      },
      {
        'icon': Icons.inbox_outlined,
        'selectedIcon': Icons.inbox_rounded,
        'label': 'NBox',
        'index': 4,
      },
      {
        'icon': Icons.more_horiz_outlined,
        'selectedIcon': Icons.more_horiz_rounded,
        'label': 'More',
        'index': 5,
      },
    ];

    return items.map((item) {
      final index = item['index'] as int;
      final isSelected = currentIndex == index;
      final wasSelected = _previousIndex == index;
      final badgeCount = item['badgeCount'] as int? ?? 0;
      final label = item['label'] as String;

      return GestureDetector(
        onTap: () => _navigateToScreen(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _navAnimation ?? const AlwaysStoppedAnimation(1.0),
          builder: (context, child) {
            // Calculate interpolated selection state
            double selectionProgress;
            final animValue = _navAnimation?.value ?? 1.0;
            final isAnimating = _navAnimationController?.isAnimating ?? false;

            if (isSelected) {
              selectionProgress = animValue;
            } else if (wasSelected) {
              selectionProgress = 1.0 - animValue;
            } else {
              selectionProgress = 0.0;
            }

            // If animation is complete, use final state
            if (!isAnimating) {
              selectionProgress = isSelected ? 1.0 : 0.0;
            }

            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: 12 + (4 * selectionProgress),
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(
                  0.15 * selectionProgress,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        selectionProgress > 0.5
                            ? item['selectedIcon'] as IconData
                            : item['icon'] as IconData,
                        color: Color.lerp(
                          AppColors.textTertiary,
                          AppColors.primaryBlue,
                          selectionProgress,
                        ),
                        size: 22 + (2 * selectionProgress),
                      ),
                      // Badge
                      if (badgeCount > 0)
                        Positioned(
                          right: -6,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.cardSurface,
                                width: 1.5,
                              ),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 14,
                              minHeight: 14,
                            ),
                            child: Text(
                              '$badgeCount',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 8,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Animated label
                  ClipRect(
                    child: AnimatedAlign(
                      duration: AppAnimations.navDuration,
                      curve: AppAnimations.standardCurve,
                      alignment: Alignment.centerLeft,
                      widthFactor: selectionProgress,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Opacity(
                          opacity: selectionProgress,
                          child: Text(
                            label,
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }).toList();
  }
}
