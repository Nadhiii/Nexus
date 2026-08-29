import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:animations/animations.dart';

import '../core/providers/is_popup_active_provider.dart';
import '../core/providers/nbox_provider.dart';
import '../core/theme/app_animations.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';

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
  int _previousIndex = 0;
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
      ),
      const ModernFinanceScreen(key: ValueKey('main-finance')),
      const ModernInsightsScreen(key: ValueKey('main-insights')),
      const ModernBikeScreen(key: ValueKey('main-bike')),
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
      _navigateToScreen(4);
    });

    // A local-notification launch can happen before this screen has had a
    // chance to subscribe to the in-memory stream. Recover its durable handoff.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final nbox = context.read<NewNboxProvider>();
      await nbox.restorePendingApprovalRequest();
      if (mounted && nbox.hasPendingApprovalRequest) {
        _navigateToScreen(4);
      }
    });
  }

  @override
  void dispose() {
    _intentSub?.cancel();
    _approvalSub?.cancel();
    super.dispose();
  }

  void _navigateToScreen(int index, {int? financeTab}) {
    if (index == _currentIndex) return;

    HapticFeedback.selectionClick();

    setState(() {
      if (index == 1 && financeTab != null) {
        _screens[1] = ModernFinanceScreen(
          key: const ValueKey('main-finance'),
          initialTabIndex: financeTab,
        );
      }
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBody: true,
      body: PageTransitionSwitcher(
        duration: AppAnimations.pageTransitionDuration,
        transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
          return FadeThroughTransition(
            animation: primaryAnimation,
            secondaryAnimation: secondaryAnimation,
            fillColor: theme.scaffoldBackgroundColor,
            child: child,
          );
        },
        child: _screens[_currentIndex],
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
      height: 64,
      child: Row(
        children: [
          // Main Floating Pill Navigation Bar
          Expanded(
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.95)
                    : colorScheme.surface.withValues(alpha: 0.95),
                borderRadius: AppSpacing.borderRadiusFull,
                border: Border.all(
                  color: isDark
                      ? colorScheme.outlineVariant
                      : colorScheme.outlineVariant,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: isDark ? 0.4 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs + 2,
                vertical: AppSpacing.xs + 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _buildDockNavItems(context, currentIndex, isDark),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.controlGap),
          // Detached Quick Action Button
          Semantics(
            button: true,
            label: 'Open NBox',
            child: Tooltip(
              message: 'NBox',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _navigateToScreen(4), // Quick Jump to NBox
                  borderRadius: AppSpacing.borderRadiusFull,
                  child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.12),
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
        'label': 'Wallet',
        'index': 1,
      },
      {
        'icon': Icons.pie_chart_outline,
        'selectedIcon': Icons.pie_chart_rounded,
        'label': 'Holdings',
        'index': 2,
      },
      {
        'icon': Icons.two_wheeler_outlined,
        'selectedIcon': Icons.two_wheeler_rounded,
        'label': 'Garage',
        'index': 3,
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
      final label = item['label'] as String;

      final scheme = Theme.of(context).colorScheme;
      final activeBg = scheme.onSurface;
      final activeFg = scheme.surface;
      final inactiveFg = scheme.onSurfaceVariant;

      return Semantics(
        label: label,
        button: true,
        selected: isSelected,
        child: GestureDetector(
          onTap: () => _navigateToScreen(index),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: AnimatedContainer(
              duration: AppAnimations.interactionDuration,
              curve: AppAnimations.interactionCurve,
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? AppSpacing.lg : AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected ? activeBg : Colors.transparent,
                borderRadius: AppSpacing.borderRadiusFull,
              ),
              child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected
                    ? item['selectedIcon'] as IconData
                    : item['icon'] as IconData,
                color: isSelected ? activeFg : inactiveFg,
                size: 20,
              ),
              if (isSelected) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(color: activeFg),
                ),
              ],
              ],
            ),
            ),
          ),
          ),
        ),
      );
    }).toList();
  }
}
