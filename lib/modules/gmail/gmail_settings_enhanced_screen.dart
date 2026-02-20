import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/models/gmail_sync_settings.dart';
import '../../core/providers/gmail_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/top_snackbar.dart';
import '../../core/providers/new_nbox_provider.dart';

class GmailSettingsEnhancedScreen extends StatefulWidget {
  const GmailSettingsEnhancedScreen({super.key});

  @override
  State<GmailSettingsEnhancedScreen> createState() =>
      _GmailSettingsEnhancedScreenState();
}

class _GmailSettingsEnhancedScreenState
    extends State<GmailSettingsEnhancedScreen> {
  late GmailSyncSettings _settings;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<GmailProvider>();
    _settings = provider.settings;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GmailProvider>();
    final isLinked = provider.isLinked;

    final nboxProvider = context.watch<NewNboxProvider>();
    final smsEnabled = nboxProvider.smsReadingEnabled;
    final gmailEnabled = provider.isLinked;

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: false,
            expandedHeight: 110,
            backgroundColor: AppColors.backgroundBlack,
            surfaceTintColor: AppColors.backgroundBlack,
            elevation: 0,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final percent =
                    ((constraints.maxHeight - kToolbarHeight) /
                            (110 - kToolbarHeight))
                        .clamp(0.0, 1.0);
                return FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 24),
                  title: AnimatedOpacity(
                    opacity: percent,
                    duration: const Duration(milliseconds: 200),
                    child: AnimatedScale(
                      scale: 0.9 + 0.1 * percent,
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        'NBox Sync',
                        style: AppTypography.headlineMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: AppSpacing.borderRadiusMd,
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      value: smsEnabled,
                      onChanged: (val) {
                        nboxProvider.updateSettings(
                          nboxProvider.settings.copyWith(
                            smsReadingEnabled: val,
                          ),
                        );
                      },
                      title: const Text('Enable SMS Reading'),
                      subtitle: const Text(
                        'Detect transactions from your SMS inbox. Only transactional messages are read; no personal content is accessed.',
                      ),
                      activeColor: AppColors.primaryBlue,
                    ),
                    Divider(color: Colors.white.withOpacity(0.05)),
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      value: gmailEnabled,
                      onChanged: gmailEnabled
                          ? (val) {
                              if (!val) provider.unlinkAccount();
                            }
                          : null,
                      title: const Text('Enable Gmail Reading'),
                      subtitle: const Text(
                        'Detect transactions from your Gmail account. Only transactional emails are read; no personal content is accessed.',
                      ),
                      activeColor: AppColors.primaryBlue,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isLinked)
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildStatusCard(provider),
                  const SizedBox(height: AppSpacing.xl),
                  _buildAutoSyncSection(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildScanSettingsSection(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildAutoApprovalSection(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildExcludedSendersSection(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSaveButton(),
                  const SizedBox(height: AppSpacing.xl),
                ]),
              ),
            )
          else
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.link_off_rounded,
                        size: 64,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Gmail Not Connected',
                        style: AppTypography.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Connect your Gmail account to enable advanced sync options',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(GmailProvider provider) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Account Linked',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            provider.currentUser?.email ?? 'Connected',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (provider.lastSyncTime != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                'Last synced: ${DateFormat.yMMMd().add_jm().format(provider.lastSyncTime!)}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAutoSyncSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AUTO SYNC',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: Text('Enable Auto Sync', style: AppTypography.bodyLarge),
                subtitle: Text(
                  'Automatically scan emails at regular intervals',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                value: _settings.autoSyncEnabled,
                onChanged: (value) {
                  setState(
                    () =>
                        _settings = _settings.copyWith(autoSyncEnabled: value),
                  );
                },
                activeThumbColor: AppColors.accentTeal,
              ),
              if (_settings.autoSyncEnabled) ...[
                Divider(color: Colors.white.withOpacity(0.05)),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sync Frequency', style: AppTypography.bodyLarge),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: SyncFrequency.values
                            .map((freq) => _buildFrequencyChip(freq))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencyChip(SyncFrequency frequency) {
    final isSelected = _settings.syncFrequency == frequency;
    return GestureDetector(
      onTap: () {
        setState(
          () => _settings = _settings.copyWith(syncFrequency: frequency),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : AppColors.cardDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryBlue
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          frequency.displayName,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildScanSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SCAN SETTINGS',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              _buildSettingsTile(
                title: 'Scan Period',
                subtitle: '${_settings.daysToScan} days',
                trailing: DropdownButton<int>(
                  value: _settings.daysToScan,
                  dropdownColor: AppColors.cardDark,
                  items: [7, 14, 30, 90]
                      .map(
                        (days) => DropdownMenuItem(
                          value: days,
                          child: Text(
                            '$days days',
                            style: AppTypography.bodyMedium,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(
                        () => _settings = _settings.copyWith(daysToScan: value),
                      );
                    }
                  },
                ),
              ),
              Divider(color: Colors.white.withOpacity(0.05)),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
                title: Text(
                  'Include Promotions',
                  style: AppTypography.bodyLarge,
                ),
                value: _settings.scanPromotions,
                onChanged: (value) {
                  setState(
                    () => _settings = _settings.copyWith(scanPromotions: value),
                  );
                },
                activeThumbColor: AppColors.accentTeal,
              ),
              Divider(color: Colors.white.withOpacity(0.05)),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
                title: Text('Include Social', style: AppTypography.bodyLarge),
                value: _settings.scanSocial,
                onChanged: (value) {
                  setState(
                    () => _settings = _settings.copyWith(scanSocial: value),
                  );
                },
                activeThumbColor: AppColors.accentTeal,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAutoApprovalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AUTO APPROVAL',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
                title: Text(
                  'Auto-Approve High Confidence',
                  style: AppTypography.bodyLarge,
                ),
                subtitle: Text(
                  'Confidence ≥ 90%',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                value: _settings.autoApproveHighConfidence,
                onChanged: (value) {
                  setState(
                    () => _settings = _settings.copyWith(
                      autoApproveHighConfidence: value,
                    ),
                  );
                },
                activeThumbColor: AppColors.accentTeal,
              ),
              Divider(color: Colors.white.withOpacity(0.05)),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
                title: Text(
                  'Auto-Approve Low Value',
                  style: AppTypography.bodyLarge,
                ),
                subtitle: Text(
                  'Amount < ₹500',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                value: _settings.autoApproveLowValue,
                onChanged: (value) {
                  setState(
                    () => _settings = _settings.copyWith(
                      autoApproveLowValue: value,
                    ),
                  );
                },
                activeThumbColor: AppColors.accentTeal,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExcludedSendersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EXCLUDED SENDERS',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_settings.excludedSenders.isEmpty)
                Text(
                  'No excluded senders',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                )
              else
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _settings.excludedSenders
                      .map(
                        (sender) => Chip(
                          label: Text(sender),
                          onDeleted: () {
                            setState(() {
                              final updated = List<String>.from(
                                _settings.excludedSenders,
                              );
                              updated.remove(sender);
                              _settings = _settings.copyWith(
                                excludedSenders: updated,
                              );
                            });
                          },
                          backgroundColor: AppColors.cardDark,
                          deleteIconColor: AppColors.error,
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: _showAddSenderDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Email'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      title: Text(title, style: AppTypography.bodyLarge),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
      trailing: trailing,
    );
  }

  void _showAddSenderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.backgroundBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        insetPadding: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Email',
                    style: AppTypography.headlineSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Transactions and notifications from this email address will be excluded from NBox parsing and insights. Use this for newsletters, promos, or any sender you want to ignore.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'e.g., promo@example.com',
                    hintStyle: TextStyle(
                      color: AppColors.textTertiary.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (controller.text.isNotEmpty) {
                      setState(() {
                        final updated = List<String>.from(
                          _settings.excludedSenders,
                        );
                        updated.add(controller.text);
                        _settings = _settings.copyWith(
                          excludedSenders: updated,
                        );
                      });
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentTeal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Add Sender',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentTeal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isSaving
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.backgroundBlack,
                  ),
                ),
              )
            : Text(
                'Save Settings',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.backgroundBlack,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await context.read<GmailProvider>().updateSettings(_settings);
      if (mounted) {
        showTopSnackBar(context, 'Settings saved successfully');
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(context, 'Failed to save settings: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
