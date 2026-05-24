import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/models/notification.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class ModernNotificationsScreen extends StatefulWidget {
  const ModernNotificationsScreen({super.key});
  @override
  State<ModernNotificationsScreen> createState() =>
      _ModernNotificationsScreenState();
}

class _ModernNotificationsScreenState extends State<ModernNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: CustomScrollView(
        slivers: [
          // 1. STANDARD HEADER
          SliverAppBar(
            pinned: true,
            expandedHeight: AppSpacing.appBarExpandedHeight,
            backgroundColor: AppColors.backgroundBlack,
            surfaceTintColor: AppColors.backgroundBlack,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: AppSpacing.appBarTitlePadding,
              title: Text(
                'Notifications',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(
                  right: AppSpacing.md,
                  top: AppSpacing.md,
                ),
                child: TextButton(
                  onPressed: () => context
                      .read<NotificationProvider>()
                      .clearAllNotifications(),
                  child: Text(
                    'Clear All',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 2. LIST
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (provider.notifications.isEmpty) {
                return SliverFillRemaining(child: _buildEmptyState());
              }
              return _buildGroupedList(provider.notifications);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList(List<AppNotification> notifications) {
    final Map<String, List<AppNotification>> grouped = {};
    for (var n in notifications) {
      final key = _getDateHeader(n.createdAt);
      if (!grouped.containsKey(key)) { grouped[key] = []; }
      grouped[key]!.add(n);
    }

    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 40),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final dateKey = grouped.keys.elementAt(index);
          final items = grouped[dateKey]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(dateKey),
              ...items.map((n) => _buildNotificationTile(context, n)),
            ],
          );
        }, childCount: grouped.keys.length),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    AppNotification notification,
  ) {
    final style = _getNotificationStyle(notification.type);
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: AppColors.error.withValues(alpha: 0.2),
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      onDismissed: (_) {
        context.read<NotificationProvider>().deleteNotification(
          notification.id,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? Colors.white.withValues(alpha: 0.05)
                : AppColors.primaryBlue.withValues(alpha: 0.3),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: style.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(style.icon, color: style.color, size: 20),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                notification.title,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: notification.isRead
                      ? FontWeight.w600
                      : FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notification.message,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('hh:mm a').format(notification.createdAt),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          onTap: () {
            context.read<NotificationProvider>().markAsRead(notification.id);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 48,
              color: AppColors.textTertiary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'All Caught Up',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "No new notifications",
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return "Today";
    }
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return "Yesterday";
    }
    return DateFormat('MMM dd').format(date);
  }

  _NotifStyle _getNotificationStyle(NotificationType type) {
    switch (type) {
      case NotificationType.billReminder:
        return _NotifStyle(Icons.receipt_long_rounded, AppColors.error);
      case NotificationType.goalProgress:
        return _NotifStyle(Icons.trending_up_rounded, AppColors.pastelGreen);
      case NotificationType.goalAchievement:
        return _NotifStyle(Icons.emoji_events_rounded, Colors.amber);
      case NotificationType.transactionAlert:
        return _NotifStyle(Icons.paid_rounded, AppColors.primaryBlue);
      case NotificationType.unusualSpending:
        return _NotifStyle(Icons.warning_amber_rounded, Colors.orange);
      default:
        return _NotifStyle(
          Icons.notifications_rounded,
          AppColors.textSecondary,
        );
    }
  }
}

class _NotifStyle {
  final IconData icon;
  final Color color;
  _NotifStyle(this.icon, this.color);
}
