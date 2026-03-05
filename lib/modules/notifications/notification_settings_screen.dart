import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/top_snackbar.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.backgroundBlack,
        elevation: 0,
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSectionHeader('Alerts'),
              _buildCard([
                _buildSwitch(
                  'Budget Alerts',
                  'Notify when approaching limits',
                  provider.budgetAlertsEnabled,
                  (v) => provider.updateNotificationSetting(
                    'notifications_budget_alerts',
                    v,
                  ),
                ),
                _divider(),
                _buildSwitch(
                  'Subscription Reminders',
                  'Alerts for upcoming bills',
                  provider.subscriptionRemindersEnabled,
                  (v) => provider.updateNotificationSetting(
                    'notifications_subscription_reminders',
                    v,
                  ),
                ),
              ]),

              const SizedBox(height: 24),
              _buildSectionHeader('Security'),
              _buildCard([
                _buildSwitch(
                  'Large Transactions',
                  'Alerts for spends over ₹10,000',
                  provider.largeTransactionAlertsEnabled,
                  (v) => provider.updateNotificationSetting(
                    'notifications_large_transactions',
                    v,
                  ),
                ),
              ]),

              const SizedBox(height: 24),
              _buildSectionHeader('Garage'),
              _buildCard([
                _buildSwitch(
                  'Fuel Log Notifications',
                  'Alerts when fuel is logged and mileage calculated',
                  provider.fuelNotificationsEnabled,
                  (v) => provider.updateNotificationSetting(
                    'notifications_fuel_logged',
                    v,
                  ),
                ),
              ]),

              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () {
                  provider.sendTestNotification();
                  showTopSnackBar(context, 'Test notification sent!');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: BorderSide(
                    color: AppColors.textTertiary.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text("Send Test Notification"),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitch(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primaryBlue,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _divider() => Divider(
    height: 1,
    color: Colors.white.withValues(alpha: 0.05),
    indent: 16,
    endIndent: 16,
  );
}
