import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/gmail_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../screens/new_modern_nbox_screen.dart';
import '../../core/widgets/top_snackbar.dart';

class GmailSettingsScreen extends StatelessWidget {
  const GmailSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GmailProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gmail Sync'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: provider.isLinked
            ? _buildLinkedView(context)
            : _buildUnlinkedView(context),
      ),
    );
  }

  Widget _buildLinkedView(BuildContext context) {
    final provider = context.watch<GmailProvider>();
    final user = provider.currentUser!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 28,
            backgroundImage: user.photoUrl != null
                ? NetworkImage(user.photoUrl!)
                : null,
            child: user.photoUrl == null
                ? const Icon(Icons.person, size: 28)
                : null,
          ),
          title: Text(
            user.displayName ?? 'Linked Account',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(user.email, style: AppTypography.bodyMedium),
        ),
        const SizedBox(height: AppSpacing.xl2),
        ElevatedButton.icon(
          icon: provider.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.sync),
          label: Text(provider.isLoading ? 'Scanning...' : 'Scan Emails Now'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            textStyle: AppTypography.titleSmall,
          ),
          onPressed: provider.isLoading
              ? null
              : () async {
                  await context.read<GmailProvider>().scanEmails();
                  if (context.mounted) {
                    final error = context.read<GmailProvider>().error;
                    if (error != null) {
                      showTopSnackBar(context, 'Error: $error', isError: true);
                    } else {
                      showTopSnackBar(context, 'Scan complete!');
                    }
                  }
                },
        ),
        const SizedBox(height: AppSpacing.xl2),
        _buildSyncStatus(context, provider),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            icon: const Icon(Icons.link_off, color: AppColors.error),
            label: const Text(
              'Unlink Account',
              style: TextStyle(color: AppColors.error),
            ),
            onPressed: () => _confirmUnlink(context),
          ),
        ),
      ],
    );
  }

  void _confirmUnlink(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Unlink Gmail Account?'),
        content: const Text(
          'This will stop Nexus from scanning this email account. You can link it again anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<GmailProvider>().unlinkAccount();
              Navigator.pop(dialogContext);
            },
            child: Text(
              'Unlink',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlinkedView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.email_outlined,
            size: 80,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('No Gmail account linked.', style: AppTypography.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Connect your Gmail to automatically find new transactions.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton.icon(
            icon: const Icon(Icons.link),
            label: const Text('Link Gmail Account'),
            onPressed: () => context.read<GmailProvider>().linkAccount(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatus(BuildContext context, GmailProvider provider) {
    final lastSync = provider.lastSyncTime;

    if (lastSync == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Last Sync: ${DateFormat.yMMMd().add_jm().format(lastSync)}',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (provider.detectedTransactions.isNotEmpty) ...[
            Text(
              'Found ${provider.detectedTransactions.length} new potential transactions.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              child: const Text('Review in N-Box'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NewModernNBoxScreen(),
                  ),
                );
              },
            ),
          ] else ...[
            Text(
              'No new transactions found.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge,
            ),
          ],
        ],
      ),
    );
  }
}
