import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/models/notification.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';

class ModernNotificationsScreen extends StatefulWidget {
  const ModernNotificationsScreen({super.key});

  @override
  State<ModernNotificationsScreen> createState() => _ModernNotificationsScreenState();
}

class _ModernNotificationsScreenState extends State<ModernNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Mark all notifications as read when the screen is opened.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications', style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.background,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: TextButton(
              onPressed: () {
                context.read<NotificationProvider>().clearAllNotifications();
              },
              child: Text('Clear All', style: AppTypography.bodyMedium.copyWith(color: colorScheme.primary)),
            ),
          ),
        ],
      ),
      backgroundColor: colorScheme.background,
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notifications.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: provider.notifications.length,
            itemBuilder: (context, index) {
              final notification = provider.notifications[index];
              return _buildNotificationCard(context, notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, AppNotification notification) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = _getIconForNotificationType(notification.type, colorScheme);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.5), width: 1),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: icon.backgroundColor,
          foregroundColor: icon.iconColor,
          child: Icon(icon.icon, size: 24),
        ),
        title: Text(notification.title, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text(notification.message, style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface.withOpacity(0.7))),
        isThreeLine: true,
        trailing: notification.isRead ? null : const Icon(Icons.circle, color: Colors.blue, size: 12),
        onTap: () {
          // Handle notification tap, e.g., navigate to a specific screen
          // For now, just mark as read.
          context.read<NotificationProvider>().markAsRead(notification.id);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: colorScheme.onSurface.withOpacity(0.4)),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No Notifications',
            style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'You're all caught up!',
            style: AppTypography.bodyLarge.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  _NotificationIcon _getIconForNotificationType(NotificationType type, ColorScheme colorScheme) {
    switch (type) {
      case NotificationType.billReminder:
        return _NotificationIcon(Icons.receipt_long, colorScheme.error, colorScheme.onError);
      case NotificationType.goalProgress:
        return _NotificationIcon(Icons.trending_up, Colors.green, Colors.white);
      case NotificationType.goalAchievement:
        return _NotificationIcon(Icons.star, Colors.amber, Colors.white);
      case NotificationType.transactionAlert:
        return _NotificationIcon(Icons.paid, Colors.blue, Colors.white);
      case NotificationType.unusualSpending:
        return _NotificationIcon(Icons.warning_amber_rounded, colorScheme.error, colorScheme.onError);
      case NotificationType.systemUpdate:
      default:
        return _NotificationIcon(Icons.notifications, colorScheme.primary, colorScheme.onPrimary);
    }
  }
}

class _NotificationIcon {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  _NotificationIcon(this.icon, this.backgroundColor, this.iconColor);
}
