import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/gmail_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/top_snackbar.dart';

class GmailSettingsScreen extends StatelessWidget {
  const GmailSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GmailProvider>();
    final isLinked = provider.isLinked;

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        title: const Text('Gmail Sync'),
        backgroundColor: AppColors.backgroundBlack,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. Status Hero
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              width: double.infinity,
              decoration: BoxDecoration(
                color: (isLinked ? AppColors.success : AppColors.textTertiary)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: (isLinked ? AppColors.success : AppColors.textTertiary)
                      .withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    isLinked
                        ? Icons.check_circle_rounded
                        : Icons.link_off_rounded,
                    size: 64,
                    color: isLinked
                        ? AppColors.success
                        : AppColors.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isLinked ? "Account Linked" : "Not Linked",
                    style: AppTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLinked
                        ? (provider.currentUser?.email ?? "Connected")
                        : "Connect Gmail to auto-track spend",
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. Action Area
            if (isLinked) ...[
              _buildActionTile(
                context,
                icon: Icons.sync,
                color: AppColors.primaryBlue,
                title: "Scan Inbox Now",
                subtitle: "Check for new transactions",
                isLoading: provider.isLoading,
                onTap: () async {
                  await context.read<GmailProvider>().scanEmails();
                  if (context.mounted) {
                    showTopSnackBar(context, "Scan Complete");
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildActionTile(
                context,
                icon: Icons.link_off_rounded,
                color: AppColors.error,
                title: "Unlink Account",
                subtitle: "Stop tracking this email",
                onTap: () => context.read<GmailProvider>().unlinkAccount(),
              ),

              const SizedBox(height: 32),

              // 3. Stats
              if (provider.lastSyncTime != null)
                Text(
                  "Last synced: ${DateFormat.yMMMd().add_jm().format(provider.lastSyncTime!)}",
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.read<GmailProvider>().linkAccount(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.login),
                  label: const Text("Connect Gmail"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        onTap: isLoading ? null : onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: AppColors.textTertiary),
      ),
    );
  }
}
