import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui'; // Required for the blur effect (ImageFilter)
import 'package:animations/animations.dart'; // Required for PageTransitionSwitcher

import '../core/providers/is_popup_active_provider.dart';
import '../core/providers/new_nbox_provider.dart';
import '../modules/dashboard/modern_dashboard_screen.dart';
import '../modules/finance/modern_finance_screen.dart';
import '../modules/insights/modern_insights_screen.dart';
import '../modules/more/modern_more_screen.dart';
import 'new_modern_nbox_screen.dart';

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
    final nbox = context.watch<NewNboxProvider>();
    final pendingNbox = nbox.pendingSms.length + nbox.pendingEmails.length;

    final screens = [
      ModernDashboardScreen(onNavigate: _navigateToScreen),
      ModernFinanceScreen(initialTabIndex: _financeScreenInitialTab),
      const ModernInsightsScreen(),
      NewModernNBoxScreen(),
      const ModernMoreScreen(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          PageTransitionSwitcher(
            transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
              return FadeThroughTransition(
                animation: primaryAnimation,
                secondaryAnimation: secondaryAnimation,
                child: child,
              );
            },
            child: screens[_currentIndex],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNavBar(context, _currentIndex, pendingNbox),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context, int currentIndex, int pendingNbox) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: ValueListenableBuilder<bool>(
          valueListenable: isPopupActiveNotifier,
          builder: (context, isPopupActive, child) {
            return BackdropFilter(
              filter: isPopupActive ? ImageFilter.blur() : ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: child,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(color: colorScheme.outline.withOpacity(0.2), width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _buildNavItems(context, currentIndex, pendingNbox),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNavItems(BuildContext context, int currentIndex, int pendingNbox) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final items = [
      {'icon': Icons.dashboard_outlined, 'selectedIcon': Icons.dashboard, 'index': 0},
      {'icon': Icons.account_balance_wallet_outlined, 'selectedIcon': Icons.account_balance_wallet, 'index': 1},
      {'icon': Icons.analytics_outlined, 'selectedIcon': Icons.analytics, 'index': 2},
      {'icon': Icons.inbox_outlined, 'selectedIcon': Icons.inbox, 'index': 3, 'badgeCount': pendingNbox},
      {'icon': Icons.more_horiz_outlined, 'selectedIcon': Icons.more_horiz, 'index': 4},
    ];

    return items.map((item) {
      final index = item['index'] as int;
      final isSelected = currentIndex == index;
      final badgeCount = item['badgeCount'] as int? ?? 0;

      return Expanded(
        child: GestureDetector(
          onTap: () => _navigateToScreen(index),
          child: Container(
            height: 70,
            color: Colors.transparent, // Make the container tappable
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.fastOutSlowIn,
                  child: Icon(
                    isSelected ? item['selectedIcon'] as IconData : item['icon'] as IconData,
                    color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.7),
                    size: 28,
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: 18,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(color: colorScheme.error, borderRadius: BorderRadius.circular(8)),
                      child: Text('$badgeCount', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}
