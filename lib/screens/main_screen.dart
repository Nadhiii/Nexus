import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui'; // Required for ImageFilter
import 'package:animations/animations.dart'; // Required for PageTransitionSwitcher

import '../core/providers/is_popup_active_provider.dart';
import '../core/providers/new_nbox_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart'; // Using the new Spacing file

// Screens
import '../modules/dashboard/modern_dashboard_screen.dart';
import '../modules/finance/modern_finance_screen.dart';
import '../modules/insights/modern_insights_screen.dart';
import '../modules/more/modern_more_screen.dart';
import '../modules/bike/ui/modern_bike_screen_ui.dart';
import '../modules/nbox/new_modern_nbox_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _financeScreenInitialTab = 0;

  void _navigateToScreen(int index, {int? financeTab}) {
    setState(() {
      _financeScreenInitialTab = financeTab ?? 0;
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch NBox for notifications
    final nbox = context.watch<NewNboxProvider>();
    final pendingNbox = nbox.pendingSms.length + nbox.pendingEmails.length;

    // Screen List
    final screens = [
      ModernDashboardScreen(onNavigate: _navigateToScreen),
      ModernFinanceScreen(initialTabIndex: _financeScreenInitialTab),
      const ModernInsightsScreen(),
      const ModernBikeScreen(),
      NewModernNBoxScreen(),
      const ModernMoreScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack, // Match the global theme
      body: Stack(
        children: [
          // 1. Main Content with Fade Transition
          PageTransitionSwitcher(
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

          // 2. Floating Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildFloatingNavBar(context, _currentIndex, pendingNbox),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingNavBar(
    BuildContext context,
    int currentIndex,
    int pendingNbox,
  ) {
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _buildNavItems(currentIndex, pendingNbox),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildNavItems(int currentIndex, int pendingNbox) {
    final items = [
      {
        'icon': Icons.dashboard_outlined,
        'selectedIcon': Icons.dashboard_rounded,
        'index': 0,
      },
      {
        'icon': Icons.account_balance_wallet_outlined,
        'selectedIcon': Icons.account_balance_wallet_rounded,
        'index': 1,
      },
      {
        'icon': Icons.pie_chart_outline, // Cleaner Icon for Insights
        'selectedIcon': Icons.pie_chart_rounded,
        'index': 2,
      },
      {
        'icon': Icons.two_wheeler_outlined,
        'selectedIcon': Icons.two_wheeler_rounded,
        'index': 3,
      },
      {
        'icon': Icons.inbox_outlined,
        'selectedIcon': Icons.inbox_rounded,
        'index': 4,
        'badgeCount': pendingNbox,
      },
      {
        'icon': Icons.more_horiz_outlined,
        'selectedIcon': Icons.more_horiz_rounded,
        'index': 5,
      },
    ];

    return items.map((item) {
      final index = item['index'] as int;
      final isSelected = currentIndex == index;
      final badgeCount = item['badgeCount'] as int? ?? 0;

      return Expanded(
        child: GestureDetector(
          onTap: () => _navigateToScreen(index),
          behavior:
              HitTestBehavior.opaque, // Ensures the whole area is tappable
          child: SizedBox(
            height: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Icon Animation
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: isSelected ? 1.0 : 0.0),
                  duration: const Duration(milliseconds: 200),
                  builder: (context, value, child) {
                    return Icon(
                      isSelected
                          ? item['selectedIcon'] as IconData
                          : item['icon'] as IconData,
                      color: isSelected
                          ? AppColors
                                .primaryBlue // Active: Blue
                          : AppColors.textTertiary, // Inactive: Grey
                      size: isSelected ? 28 : 24, // Subtle size change
                    );
                  },
                ),

                // Notification Badge
                if (badgeCount > 0)
                  Positioned(
                    right: 12,
                    top: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error, // Pastel Pink/Red
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusFull,
                        ),
                        border: Border.all(
                          color: AppColors.cardSurface,
                          width: 1.5,
                        ), // Cutout effect
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Optional: Active Indicator Dot (Uncomment if you want a dot below active icon)
                /*
                if (isSelected)
                  Positioned(
                    bottom: 12,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                */
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}
