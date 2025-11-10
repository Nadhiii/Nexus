import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/nbox_provider.dart';
import 'core/services/sms_inbox_service.dart';
import 'core/theme/app_typography.dart';
import 'core/theme/app_spacing.dart';
import 'core/widgets/nbox_confirmation_dialog.dart';
import 'nbox_item_detail_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class ModernNBoxScreen extends StatelessWidget {
  const ModernNBoxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Consumer<NBoxProvider>(
        builder: (context, nbox, _) {
          return CustomScrollView(
            slivers: [
              _buildAppBar(context, nbox, colorScheme),
              if (nbox.pending.isEmpty)
                SliverFillRemaining(child: _buildEmptyState(context, colorScheme))
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: _buildSummaryCard(context, nbox, colorScheme),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = nbox.pending[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _buildNBoxCard(context, item, nbox, colorScheme),
                        );
                      },
                      childCount: nbox.pending.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 140)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, NBoxProvider nbox, ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: colorScheme.background,
      foregroundColor: colorScheme.onBackground,
      flexibleSpace: FlexibleSpaceBar(
        title: Text('NBox', style: AppTypography.titleLarge.copyWith(color: colorScheme.onBackground, fontWeight: FontWeight.w600)),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.sync), tooltip: 'Scan SMS', onPressed: () => _scanSMS(context)),
        if (nbox.pending.isNotEmpty) ...[
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: 'Approve All',
            onPressed: () {
              nbox.approveAll();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All transactions approved'), backgroundColor: Colors.green));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear All',
            onPressed: () {
              nbox.clearAll();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All transactions cleared')));
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, NBoxProvider nbox, ColorScheme colorScheme) {
    final totalAmount = nbox.pending.fold<double>(0, (sum, item) => sum + item.amount);
    return Container(
      padding: AppSpacing.cardPaddingXl,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pending Review', style: AppTypography.bodyMedium.copyWith(color: colorScheme.onPrimary.withOpacity(0.9), letterSpacing: 0.5)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('₹', style: AppTypography.headlineMedium.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              Expanded(child: Text(totalAmount.toStringAsFixed(2), style: AppTypography.currencyLarge.copyWith(color: colorScheme.onPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('${nbox.pending.length} transactions detected', style: AppTypography.bodySmall.copyWith(color: colorScheme.onPrimary.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _buildNBoxCard(BuildContext context, dynamic item, NBoxProvider nbox, ColorScheme colorScheme) {
    return Dismissible(
      key: Key(item.id),
      background: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        alignment: Alignment.centerLeft,
        child: const Row(children: [Icon(Icons.check_circle, color: Colors.white, size: 28), SizedBox(width: 12), Text('Approve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))]),
      ),
      secondaryBackground: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(color: colorScheme.error, borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        alignment: Alignment.centerRight,
        child: const Row(mainAxisAlignment: MainAxisAlignment.end, children: [Text('Reject', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), SizedBox(width: 12), Icon(Icons.cancel, color: Colors.white, size: 28)]),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          final result = await showDialog<bool>(context: context, builder: (context) => NBoxConfirmationDialog(detectedTransaction: item));
          if (result == true) {
            await nbox.approve(item.id);
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transaction "${item.title}" approved'), backgroundColor: Colors.green));
          }
          return result ?? false;
        } else {
          await nbox.reject(item.id);
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transaction "${item.title}" rejected'), backgroundColor: colorScheme.error));
          return true;
        }
      },
      child: InkWell(
        onTap: () async {
          final result = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (context) => NBoxItemDetailScreen(itemId: item.id, title: item.title, amount: item.amount, source: item.source)));
          if (result == 'approved') nbox.approve(item.id);
          else if (result == 'rejected') nbox.reject(item.id);
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                    child: Icon(Icons.message_outlined, color: colorScheme.primary, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: AppTypography.titleSmall.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600)),
                        Text(item.source, style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurface.withOpacity(0.6))),
                      ],
                    ),
                  ),
                  Text('₹${item.amount.toStringAsFixed(2)}', style: AppTypography.titleMedium.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      await nbox.reject(item.id);
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transaction "${item.title}" rejected'), backgroundColor: colorScheme.error));
                    },
                    style: OutlinedButton.styleFrom(foregroundColor: colorScheme.error, side: BorderSide(color: colorScheme.error.withOpacity(0.5))),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await showDialog<bool>(context: context, builder: (context) => NBoxConfirmationDialog(detectedTransaction: item));
                      if (result == true) {
                        await nbox.approve(item.id);
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transaction "${item.title}" approved'), backgroundColor: Colors.green));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 120, color: colorScheme.primary.withOpacity(0.3)),
            const SizedBox(height: AppSpacing.xl2),
            Text('No Pending Items', style: AppTypography.headlineSmall.copyWith(color: colorScheme.onBackground, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.lg),
            Text('Tap Scan SMS to import messages and detect transactions.', textAlign: TextAlign.center, style: AppTypography.bodyLarge.copyWith(color: colorScheme.onBackground.withOpacity(0.7))),
            const SizedBox(height: AppSpacing.xl2),
            ElevatedButton.icon(
              onPressed: () => _scanSMS(context),
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl2, vertical: AppSpacing.lg)),
              icon: const Icon(Icons.sync),
              label: const Text('Scan SMS'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanSMS(BuildContext context) async {
    final status = await Permission.sms.request();
    if (!status.isGranted && !status.isLimited) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SMS permission denied.')));
      return;
    }
    final service = SmsInboxService();
    final detected = await service.detectTransactions(days: 14);
    if (!context.mounted) return;
    if (detected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No transactions detected.')));
    } else {
      context.read<NBoxProvider>().addDetectedAll(detected);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Found ${detected.length} transactions'), backgroundColor: Colors.green));
    }
  }
}
