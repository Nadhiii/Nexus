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
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToScreen(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic, // Smoother, more fluid curve
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  List<Widget> get _screens => [
    ModernDashboardScreen(onNavigate: _navigateToScreen),
    const ModernFinanceScreen(), // Combined Accounts + Transactions
    const ModernInsightsScreen(), // Financial Planning & Analysis
    const ModernNBoxScreen(),
    const ModernMoreScreen(),
  ];

  // Custom compact navigation items
  List<Widget> _buildCustomNavItems() {
    final pending = context.watch<NBoxProvider>().pendingCount;

    final items = [
      {
        'icon': Icons.dashboard_outlined,
        'selectedIcon': Icons.dashboard,
        'index': 0,
      },
      {
        'icon': Icons.account_balance_wallet_outlined,
        'selectedIcon': Icons.account_balance_wallet,
        'index': 1,
        'label': 'Finance', // Combined Accounts + Transactions
      },
      {
        'icon': Icons.analytics_outlined,
        'selectedIcon': Icons.analytics,
        'index': 2,
      },
      {
        'icon': Icons.inbox_outlined,
        'selectedIcon': Icons.inbox,
        'index': 3,
        'hasBadge': true,
      },
      {
        'icon': Icons.more_horiz_outlined,
        'selectedIcon': Icons.more_horiz,
        'index': 4,
      },
    ];

    return items.map((item) {
      final index = item['index'] as int;
      final isSelected = _currentIndex == index;
      final hasBadge = item['hasBadge'] == true;

      return Expanded(
        child: GestureDetector(
          onTap: () {
            _navigateToScreen(index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            height: 70, // Match the container height
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withOpacity(0.3)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12), // More boxy design
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  child: Icon(
                    isSelected
                        ? item['selectedIcon'] as IconData
                        : item['icon'] as IconData,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                    size: 28, // Increased icon size for better visibility
                  ),
                ),
                if (hasBadge && pending > 0)
                  Positioned(
                    right: 18, // Adjusted for larger container
                    top: 12, // Adjusted for larger container
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        pending > 9 ? '9+' : '$pending',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // PageView for swipeable navigation with smooth built-in physics
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(), // Smooth iOS-style physics
            children: _screens,
          ),
          // Bottom navigation bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              height: 70, // Increased for better usability
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
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black.withOpacity(0.4)
                          : Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _buildCustomNavItems(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: null, // Finance screen has its own FAB
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
