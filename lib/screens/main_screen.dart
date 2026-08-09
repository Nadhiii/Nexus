import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/physics.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:animations/animations.dart';

import '../core/providers/is_popup_active_provider.dart';
import '../core/providers/nbox_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_animations.dart';

// Screens
import '../modules/dashboard/dashboard_screen.dart';
import '../modules/Wallet/wallet_screen.dart';
import '../modules/insights/insights_screen.dart';
import '../modules/more/more_screen.dart';
import '../modules/bike/ui/bike_screen.dart';
import '../core/services/intent_navigation_service.dart';
import '../core/services/notification_service.dart';
import '../modules/nbox/nbox_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _financeScreenInitialTab = 0;
  AnimationController? _navAnimationController;
  int _previousIndex = 0;
  StreamSubscription<int>? _intentSub;
  StreamSubscription<DetectionApprovalRequest>? _approvalSub;

  @override
  void initState() {
    super.initState();
    _navAnimationController = AnimationController(
      vsync: this,
      lowerBound: 0.0,
      upperBound: 1.0,
    );

    _intentSub = IntentNavigationService.tabStream.listen((tabIndex) {
      if (!mounted) return;
      _navigateToScreen(tabIndex);
    });

    _approvalSub = NotificationService().approvalRequestStream.listen((event) {
      if (!mounted) return;
      context.read<NewNboxProvider>().queueApprovalRequestFromNotification(
        transactionId: event.transactionId,
        source: event.source,
      );
      _navigateToScreen(4);
    });
  }

  @override
  void dispose() {
    _navAnimationController?.dispose();
    _intentSub?.cancel();
    _approvalSub?.cancel();
    super.dispose();
  }

  void _navigateToScreen(int index, {int? financeTab}) {
    if (index == _currentIndex) return;

    HapticFeedback.selectionClick();

    setState(() {
      _previousIndex = _currentIndex;
      _financeScreenInitialTab = financeTab ?? 0;
      _currentIndex = index;
    });

    _navAnimationController?.duration = const Duration(milliseconds: 350);
    final spring = SpringDescription(
      mass: 1.0,
      stiffness: 220.0,
      damping: 24.0,
    );
    final simulation = SpringSimulation(spring, 0.0, 1.0, 3.5);
    _navAnimationController?.animateWith(simulation);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ModernDashboardScreen(onNavigate: _navigateToScreen),
      ModernFinanceScreen(initialTabIndex: _financeScreenInitialTab),
      const ModernInsightsScreen(),
      const ModernBikeScreen(),
      const NewModernNBoxScreen(),
      const ModernMoreScreen(),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundBlack : AppColors.kuveraBgLight,
      extendBody: true,
      body: PageTransitionSwitcher(
        duration: AppAnimations.pageTransitionDuration,
        transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
          return FadeThroughTransition(
            animation: primaryAnimation,
            secondaryAnimation: secondaryAnimation,
            fillColor: isDark ? AppColors.backgroundBlack : AppColors.kuveraBgLight,
            child: child,
          );
        },
        child: screens[_currentIndex],
      ),
      bottomNavigationBar: _buildKuveraFloatingDock(context, _currentIndex),
    );
  }

  Widget _buildKuveraFloatingDock(BuildContext context, int currentIndex) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      height: 64,
      child: Row(
        children: [
          // Main Floating Pill Navigation Bar
          Expanded(
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: isDark 
                    ? AppColors.cardSurface.withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                  color: isDark ? AppColors.white12 : AppColors.kuveraBorderLight,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _buildDockNavItems(currentIndex, isDark),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Detached Quick Action Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigateToScreen(4), // Quick Jump to NBox
              borderRadius: BorderRadius.circular(32),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.white : AppColors.black,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.search,
                  color: isDark ? AppColors.black : AppColors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDockNavItems(int currentIndex, bool isDark) {
    final items = [
      {'icon': Icons.home_outlined, 'selectedIcon': Icons.home_rounded, 'label': 'Home', 'index': 0},
      {'icon': Icons.account_balance_wallet_outlined, 'selectedIcon': Icons.account_balance_wallet_rounded, 'label': 'Wallet', 'index': 1},
      {'icon': Icons.pie_chart_outline, 'selectedIcon': Icons.pie_chart_rounded, 'label': 'Holdings', 'index': 2},
      {'icon': Icons.two_wheeler_outlined, 'selectedIcon': Icons.two_wheeler_rounded, 'label': 'Garage', 'index': 3},
      {'icon': Icons.more_horiz_outlined, 'selectedIcon': Icons.more_horiz_rounded, 'label': 'More', 'index': 5},
    ];

    return items.map((item) {
      final index = item['index'] as int;
      final isSelected = currentIndex == index;
      final label = item['label'] as String;

      final activeBg = isDark ? AppColors.white : AppColors.black;
      final activeFg = isDark ? AppColors.black : AppColors.white;
      final inactiveFg = isDark ? AppColors.textSecondary : AppColors.kuveraTextSecondaryLight;

      return GestureDetector(
        onTap: () => _navigateToScreen(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 16 : 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? item['selectedIcon'] as IconData : item['icon'] as IconData,
                color: isSelected ? activeFg : inactiveFg,
                size: 20,
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: activeFg,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }
}