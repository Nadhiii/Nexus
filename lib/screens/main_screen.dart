import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for Haptics
import 'package:flutter/physics.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:animations/animations.dart';

import '../core/providers/is_popup_active_provider.dart';
import '../core/providers/new_nbox_provider.dart';
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
import '../modules/nbox/new_modern_nbox_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _financeScreenInitialTab = 0;
  final bool _aiInitialized = false;
  AnimationController? _navAnimationController;
  Animation<double>? _navAnimation;
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
    _navAnimation = CurvedAnimation(
      parent: _navAnimationController!,
      curve: AppAnimations.standardCurve,
    );

    _intentSub = IntentNavigationService.tabStream.listen((tabIndex) {
      if (!mounted) { return; }
      _navigateToScreen(tabIndex);
    });

    _approvalSub = NotificationService().approvalRequestStream.listen((event) {
      if (!mounted) {
        return;
      }
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
    if (index == _currentIndex) { return; }

    // Light haptic feedback for a tactile feel
    HapticFeedback.selectionClick();

    setState(() {
      _previousIndex = _currentIndex;
      _financeScreenInitialTab = financeTab ?? 0;
      _currentIndex = index;
    });
    _navAnimationController?.duration = const Duration(milliseconds: 400);
    final spring = SpringDescription(
      mass: 1.0,
      stiffness: 200.0,
      damping: 22.0,
    );
    final simulation = SpringSimulation(spring, 0.0, 1.0, 4.0);
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

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      // Extends body under the floating nav bar for true translucency
      extendBody: true,
      body: PageTransitionSwitcher(
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
      bottomNavigationBar: _buildFloatingNavBar(context, _currentIndex),
    );
  }

  Widget _buildFloatingNavBar(BuildContext context, int currentIndex) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: ValueListenableBuilder<bool>(
          valueListenable: isPopupActiveNotifier,
          builder: (context, isPopupActive, child) {
            return BackdropFilter(
              filter: isPopupActive
                  ? ImageFilter.blur(sigmaX: 0, sigmaY: 0)
                  : ImageFilter.blur(sigmaX: 20, sigmaY: 20), // Stronger blur
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white12,
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(
                    color: AppColors.white12,
                    width: 0.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _buildNavItems(currentIndex),
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
      final label = item['label'] as String;

      return GestureDetector(
        onTap: () => _navigateToScreen(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _navAnimation ?? const AlwaysStoppedAnimation(1.0),
          builder: (context, child) {
            double selectionProgress = isSelected
                ? (_navAnimation?.value ?? 1.0)
                : (wasSelected ? 1.0 - (_navAnimation?.value ?? 0.0) : 0.0);

            selectionProgress = selectionProgress.clamp(0.0, 1.0);

            if (!(_navAnimationController?.isAnimating ?? false)) {
              selectionProgress = isSelected ? 1.0 : 0.0;
            }

            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: 12 + (4 * selectionProgress),
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 
                  0.15 * selectionProgress,
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
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
                    size: 22,
                  ),
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
                              fontSize: 12,
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
