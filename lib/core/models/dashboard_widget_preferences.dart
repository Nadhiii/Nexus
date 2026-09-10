import 'package:flutter/material.dart';

enum DashboardWidgetType {
  netWorth,
  quickActions,
  upcomingBills,
  goalProgress,
  recentTransactions,
  monthlySpending,
  investments,
  cashFlow,
}

enum DashboardWidgetSize {
  small, // 1/2 width
  medium, // full width, compact height
  large, // full width, expanded height
}

class DashboardWidget {
  final String id;
  final DashboardWidgetType type;
  final String title;
  final IconData icon;
  final DashboardWidgetSize size;
  final bool isVisible;
  final int order;

  const DashboardWidget({
    required this.id,
    required this.type,
    required this.title,
    required this.icon,
    this.size = DashboardWidgetSize.medium,
    this.isVisible = true,
    required this.order,
  });

  DashboardWidget copyWith({
    String? id,
    DashboardWidgetType? type,
    String? title,
    IconData? icon,
    DashboardWidgetSize? size,
    bool? isVisible,
    int? order,
  }) {
    return DashboardWidget(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      size: size ?? this.size,
      isVisible: isVisible ?? this.isVisible,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'icon': icon.codePoint,
      'size': size.name,
      'isVisible': isVisible,
      'order': order,
    };
  }

  factory DashboardWidget.fromMap(Map<String, dynamic> map) {
    return DashboardWidget(
      id: map['id'] ?? '',
      type: DashboardWidgetType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => DashboardWidgetType.netWorth,
      ),
      title: map['title'] ?? '',
      icon: IconData(
        map['icon'] ?? Icons.dashboard.codePoint,
        fontFamily: 'MaterialIcons',
      ),
      size: DashboardWidgetSize.values.firstWhere(
        (e) => e.name == map['size'],
        orElse: () => DashboardWidgetSize.medium,
      ),
      isVisible: map['isVisible'] ?? true,
      order: map['order'] ?? 0,
    );
  }
}

class DashboardPreferences {
  final List<DashboardWidget> widgets;
  final bool showWelcomeMessage;
  final String greetingName;

  const DashboardPreferences({
    required this.widgets,
    this.showWelcomeMessage = true,
    this.greetingName = '',
  });

  static List<DashboardWidget> getDefaultWidgets() {
    return [
      const DashboardWidget(
        id: 'net_worth',
        type: DashboardWidgetType.netWorth,
        title: 'Net Worth',
        icon: Icons.account_balance_wallet,
        size: DashboardWidgetSize.large,
        order: 0,
      ),
      const DashboardWidget(
        id: 'quick_actions',
        type: DashboardWidgetType.quickActions,
        title: 'Quick Actions',
        icon: Icons.flash_on,
        size: DashboardWidgetSize.medium,
        order: 1,
      ),
      const DashboardWidget(
        id: 'recent_transactions',
        type: DashboardWidgetType.recentTransactions,
        title: 'Recent Transactions',
        icon: Icons.receipt_long,
        size: DashboardWidgetSize.medium,
        order: 2,
      ),
      const DashboardWidget(
        id: 'upcoming_bills',
        type: DashboardWidgetType.upcomingBills,
        title: 'Upcoming Bills',
        icon: Icons.schedule,
        size: DashboardWidgetSize.small,
        order: 3,
      ),
      const DashboardWidget(
        id: 'goal_progress',
        type: DashboardWidgetType.goalProgress,
        title: 'Goal Progress',
        icon: Icons.flag,
        size: DashboardWidgetSize.small,
        order: 4,
      ),
      const DashboardWidget(
        id: 'monthly_spending',
        type: DashboardWidgetType.monthlySpending,
        title: 'Monthly Spending',
        icon: Icons.pie_chart,
        size: DashboardWidgetSize.medium,
        order: 5,
      ),
      const DashboardWidget(
        id: 'investments',
        type: DashboardWidgetType.investments,
        title: 'Investments',
        icon: Icons.trending_up,
        size: DashboardWidgetSize.medium,
        order: 6,
        isVisible: false, // Hidden by default
      ),
      const DashboardWidget(
        id: 'cash_flow',
        type: DashboardWidgetType.cashFlow,
        title: 'Cash Flow',
        icon: Icons.waterfall_chart,
        size: DashboardWidgetSize.large,
        order: 7,
        isVisible: false, // Hidden by default
      ),
    ];
  }

  DashboardPreferences copyWith({
    List<DashboardWidget>? widgets,
    bool? showWelcomeMessage,
    String? greetingName,
  }) {
    return DashboardPreferences(
      widgets: widgets ?? this.widgets,
      showWelcomeMessage: showWelcomeMessage ?? this.showWelcomeMessage,
      greetingName: greetingName ?? this.greetingName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'widgets': widgets.map((w) => w.toMap()).toList(),
      'showWelcomeMessage': showWelcomeMessage,
      'greetingName': greetingName,
    };
  }

  factory DashboardPreferences.fromMap(Map<String, dynamic> map) {
    return DashboardPreferences(
      widgets:
          (map['widgets'] as List<dynamic>?)
              ?.map((w) => DashboardWidget.fromMap(w as Map<String, dynamic>))
              .toList() ??
          getDefaultWidgets(),
      showWelcomeMessage: map['showWelcomeMessage'] ?? true,
      greetingName: map['greetingName'] ?? '',
    );
  }

  static DashboardPreferences getDefault() {
    return DashboardPreferences(widgets: getDefaultWidgets());
  }
}
