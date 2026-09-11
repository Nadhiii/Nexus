import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';

import '../core/providers/nbox_provider.dart';
import '../core/theme/app_animations.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';

// Screens
import '../modules/dashboard/dashboard_screen.dart';
import '../modules/Wallet/accounts_detail_screen.dart';
import '../modules/insights/insights_screen.dart';
import '../modules/more/more_screen.dart';
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
  StreamSubscription<int>? _intentSub;
  StreamSubscription<DetectionApprovalRequest>? _approvalSub;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      ModernDashboardScreen(
        key: const ValueKey('main-dashboard'),
        onNavigate: _navigateToScreen,
        onOpenAccountsHistory: _openAccountsHistory,
      ),
      const ModernInsightsScreen(key: ValueKey('main-insights')),
      const AccountsDetailScreen(
        key: ValueKey('main-accounts'),
        initialTabIndex: 0,
      ),
      const NewModernNBoxScreen(key: ValueKey('main-nbox')),
      const ModernMoreScreen(key: ValueKey('main-more')),
    ];

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
      _navigateToScreen(3);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final nbox = context.read<NewNboxProvider>();
      await nbox.restorePendingApprovalRequest();
      if (mounted && nbox.hasPendingApprovalRequest) {
        _navigateToScreen(3);
      }
    });
  }

  @override
  void dispose() {
    _intentSub?.cancel();
    _approvalSub?.cancel();
    super.dispose();
  }

  void _navigateToScreen(int index) {
    if (index == _currentIndex) return;

    HapticFeedback.selectionClick();

    setState(() {
      _currentIndex = index;
    });
  }

  void _openAccountsHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AccountsDetailScreen(initialTabIndex: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBody: true,
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 260),
        reverse: false,
        transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
          return SharedAxisTransition(
            animation: primaryAnimation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal,
            fillColor: theme.scaffoldBackgroundColor,
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: _buildKuveraFloatingDock(context, _currentIndex),
    );
  }

  Widget _buildKuveraFloatingDock(BuildContext context, int currentIndex) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl3 - AppSpacing.xs,
      ),
      height: 68,
      child: Row(
        children: [
          // Main Floating Pill Navigation Bar (Zero white border)
          Expanded(
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.96,
                      )
                    : colorScheme.surface.withValues(alpha: 0.96),
                borderRadius: AppSpacing.borderRadiusFull,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 6,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _buildDockNavItems(context, currentIndex, isDark),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.controlGap),
          // Detached Quick Action Button (Zero white border)
          Semantics(
            button: true,
            label: 'Open Inbox',
            child: Tooltip(
              message: 'Inbox',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _navigateToScreen(3),
                  borderRadius: AppSpacing.borderRadiusFull,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.inbox_rounded,
                      color: colorScheme.surface,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDockNavItems(
    BuildContext context,
    int currentIndex,
    bool isDark,
  ) {
    final items = [
      {
        'icon': Icons.home_outlined,
        'selectedIcon': Icons.home_rounded,
        'label': 'Home',
        'index': 0,
      },
      {
        'icon': Icons.account_balance_wallet_outlined,
        'selectedIcon': Icons.account_balance_wallet_rounded,
        'label': 'Accounts',
        'index': 2,
      },
      {
        'icon': Icons.pie_chart_outline,
        'selectedIcon': Icons.pie_chart_rounded,
        'label': 'Wealth',
        'index': 1,
      },
      {
        'icon': Icons.more_horiz_outlined,
        'selectedIcon': Icons.more_horiz_rounded,
        'label': 'More',
        'index': 4,
      },
    ];

    return items.map((item) {
      final index = item['index'] as int;
      final isSelected = currentIndex == index;
      final label = item['label'] as String;
      final scheme = Theme.of(context).colorScheme;
      final activeColor = scheme.primary;
      final inactiveColor = scheme.onSurfaceVariant.withValues(alpha: 0.7);

      return Expanded(
        child: Semantics(
          label: label,
          button: true,
          selected: isSelected,
          child: GestureDetector(
            onTap: () => _navigateToScreen(index),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: AppAnimations.interactionDuration,
              curve: AppAnimations.interactionCurve,
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected
                        ? item['selectedIcon'] as IconData
                        : item['icon'] as IconData,
                    color: isSelected ? activeColor : inactiveColor,
                    size: 22,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTypography.bodyFont,
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected ? activeColor : inactiveColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}
