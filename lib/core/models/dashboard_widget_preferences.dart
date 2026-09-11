import 'package:flutter/material.dart';

enum DashboardWidgetType {
  netWorth,
  quickActions,
  monthPulse,
  garage,
  payments,
  goals,
  budgets,
  recentActivity,
}

enum DashboardWidgetSize {
  small, // 1/2 width or compact
  medium, // full width or flexible
  large, // full width, prominent
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
      icon: IconData(map['icon'] ?? 0xe871, fontFamily: 'MaterialIcons'),
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
        id: 'total_balance',
        type: DashboardWidgetType.netWorth,
        title: 'Total Balance',
        icon: Icons.account_balance_wallet_rounded,
        size: DashboardWidgetSize.large,
        order: 0,
      ),
      const DashboardWidget(
        id: 'quick_actions',
        type: DashboardWidgetType.quickActions,
        title: 'Quick Actions',
        icon: Icons.flash_on_rounded,
        size: DashboardWidgetSize.medium,
        order: 1,
      ),
      const DashboardWidget(
        id: 'month_pulse',
        type: DashboardWidgetType.monthPulse,
        title: 'Monthly Spending Pulse',
        icon: Icons.insights_rounded,
        size: DashboardWidgetSize.large,
        order: 2,
      ),
      const DashboardWidget(
        id: 'garage',
        type: DashboardWidgetType.garage,
        title: 'Garage',
        icon: Icons.two_wheeler_rounded,
        size: DashboardWidgetSize.medium,
        order: 3,
      ),
      const DashboardWidget(
        id: 'payments',
        type: DashboardWidgetType.payments,
        title: 'Upcoming Payments',
        icon: Icons.schedule_rounded,
        size: DashboardWidgetSize.small,
        order: 4,
      ),
      const DashboardWidget(
        id: 'budgets',
        type: DashboardWidgetType.budgets,
        title: 'Budgets Overview',
        icon: Icons.pie_chart_outline_rounded,
        size: DashboardWidgetSize.small,
        order: 5,
      ),
      const DashboardWidget(
        id: 'goals',
        type: DashboardWidgetType.goals,
        title: 'Savings Goals',
        icon: Icons.flag_rounded,
        size: DashboardWidgetSize.small,
        order: 6,
      ),
      const DashboardWidget(
        id: 'recent_activity',
        type: DashboardWidgetType.recentActivity,
        title: 'Recent Activity',
        icon: Icons.receipt_long_rounded,
        size: DashboardWidgetSize.large,
        order: 7,
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
