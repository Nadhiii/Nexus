import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Settings', style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.background,
        elevation: 0,
      ),
      backgroundColor: colorScheme.background,
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _buildSectionHeader(context, 'General'),
              _buildSettingsCard(context, [
                _buildSwitchTile(
                  context,
                  title: 'Budget Alerts',
                  subtitle: 'Notify when you approach a budget limit',
                  value: provider.budgetAlertsEnabled,
                  onChanged: (value) => provider.updateNotificationSetting('notifications_budget_alerts', value),
                ),
                _buildSwitchTile(
                  context,
                  title: 'Subscription Reminders',
                  subtitle: 'Get reminders for upcoming subscriptions',
                  value: provider.subscriptionRemindersEnabled,
                  onChanged: (value) => provider.updateNotificationSetting('notifications_subscription_reminders', value),
                ),
                _buildSwitchTile(
                  context,
                  title: 'Large Transaction Alerts',
                  subtitle: 'Receive alerts for transactions over ₹10,000',
                  value: provider.largeTransactionAlertsEnabled,
                  onChanged: (value) => provider.updateNotificationSetting('notifications_large_transactions', value),
                ),
              ]),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionHeader(context, 'Testing'),
              _buildSettingsCard(context, [
                ListTile(
                  title: const Text('Send Test Notification', style: AppTypography.bodyLarge),
                  subtitle: Text('Check if your notifications are working', style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface.withOpacity(0.7))),
                  trailing: const Icon(Icons.send_outlined),
                  onTap: () {
                    provider.sendTestNotification();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Test notification sent!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ]),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelMedium.copyWith(color: Theme.of(context).colorScheme.primary, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.5), width: 1),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return SwitchListTile(
      title: Text(title, style: AppTypography.bodyLarge),
      subtitle: Text(subtitle, style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface.withOpacity(0.7))),
      value: value,
      onChanged: onChanged,
      activeColor: colorScheme.primary,
    );
  }
}
