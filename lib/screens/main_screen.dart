import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui'; // Required for the blur effect (ImageFilter)

import '../core/providers/nbox_provider.dart';
import '../modules/dashboard/modern_dashboard_screen.dart';
import '../modules/finance/modern_finance_screen.dart';
import '../modules/insights/modern_insights_screen.dart';
import '../modules/more/modern_more_screen.dart';
import '../modern_nbox_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _financeScreenInitialTab = 0;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      if (_pageController.page?.round() != _currentIndex) {
        setState(() {
          _currentIndex = _pageController.page!.round();
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToScreen(int index, {int? financeTab}) {
    setState(() {
      _financeScreenInitialTab = financeTab ?? 0;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingNbox = context.watch<NBoxProvider>().pendingCount;

    final screens = [
      ModernDashboardScreen(onNavigate: _navigateToScreen),
      ModernFinanceScreen(initialTabIndex: _financeScreenInitialTab),
      const ModernInsightsScreen(),
      const ModernNBoxScreen(),
      const ModernMoreScreen(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // Disable swiping
            itemCount: screens.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double pageOffset = 0;
                  if (_pageController.position.hasContentDimensions) {
                    pageOffset = _pageController.page! - index;
                  }

                  double scale = 1.0 - (pageOffset.abs() * 0.1);
                  double opacity = 1.0 - pageOffset.abs().clamp(0.0, 1.0);

                  return Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity,
                      child: screens[index],
                    ),
                  );
                },
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNavBar(context, _pageController, pendingNbox),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context, PageController pageController, int pendingNbox) {
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
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(color: colorScheme.outline.withOpacity(0.2), width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _buildNavItems(context, pageController, pendingNbox),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNavItems(BuildContext context, PageController pageController, int pendingNbox) {
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
      final badgeCount = item['badgeCount'] as int? ?? 0;

      return Expanded(
        child: GestureDetector(
          onTap: () => _navigateToScreen(index),
          child: AnimatedBuilder(
            animation: pageController,
            builder: (context, child) {
              double selectedness = 1.0;
              if (pageController.page != null) {
                selectedness = 1.0 - (pageController.page! - index).abs().clamp(0.0, 1.0);
              }
              final isSelected = selectedness > 0.5;

              return Container(
                height: 70,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(isSelected ? 0.3 * selectedness : 0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scale: 1 + (selectedness * 0.1),
                      child: Icon(
                        isSelected ? item['selectedIcon'] as IconData : item['icon'] as IconData,
                        color: Color.lerp(colorScheme.onSurface.withOpacity(0.7), colorScheme.primary, selectedness),
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
                          child: Text('$badgeCount', style: TextStyle(fontSize: 10, color: colorScheme.onError, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }).toList();
  }
}
