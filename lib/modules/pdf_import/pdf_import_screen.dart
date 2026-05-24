import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/account.dart';
import '../../core/models/transaction.dart';
import '../../core/providers/pdf_import_provider.dart';
import '../../core/providers/account_provider.dart';
import '../../core/providers/transaction_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_animations.dart';
import '../../core/utils/logo_utils.dart';
import 'pdf_password_manager_screen.dart';

class PDFImportScreen extends StatefulWidget {
  const PDFImportScreen({super.key});

  @override
  State<PDFImportScreen> createState() => _PDFImportScreenState();
}

class _PDFImportScreenState extends State<PDFImportScreen> {
  String? _selectedFilePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Bank Statement'),
        backgroundColor: AppColors.cardSurface,
        elevation: 0,
        actions: [
          Tooltip(
            message: 'Manage Saved Passwords',
            child: IconButton(
              icon: const Icon(Icons.lock_outline),
              color: AppColors.primaryBlue,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PDFPasswordManagerScreen(),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<PDFImportProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step indicator
                _buildStepIndicator(provider),
                const SizedBox(height: AppSpacing.xl3),

                // Content based on current step
                if (provider.currentStatement == null)
                  _buildUploadStep(context, provider)
                else if (provider.duplicateResults == null)
                  _buildAccountSelectionStep(context, provider)
                else
                  _buildPreviewStep(context, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepIndicator(PDFImportProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Import Progress', style: AppTypography.titleLarge),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            _buildStepBubble('1', 'Upload', provider.currentStatement != null),
            const Expanded(child: Divider(height: 2, color: Colors.grey)),
            _buildStepBubble('2', 'Account', provider.duplicateResults != null),
            const Expanded(child: Divider(height: 2, color: Colors.grey)),
            _buildStepBubble('3', 'Review', provider.duplicateResults != null),
          ],
        ),
      ],
    );
  }

  Widget _buildStepBubble(String number, String label, bool completed) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed ? AppColors.success : Colors.grey,
          ),
          child: Center(
            child: Text(
              number,
              style: AppTypography.titleLarge.copyWith(color: AppColors.white),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(label, style: AppTypography.bodySmall),
      ],
    );
  }

  Widget _buildUploadStep(BuildContext context, PDFImportProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                Icon(
                  Icons.picture_as_pdf,
                  size: 80,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Select Bank Statement PDF',
                  style: AppTypography.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Supported formats: SBI, HDFC, ICICI, Axis, and generic statements',
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl2),
                ElevatedButton.icon(
                  onPressed: () => _pickAndParsePDF(context, provider),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Choose PDF File'),
                ),
                if (_selectedFilePath != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            _selectedFilePath!.split('/').last,
                            style: AppTypography.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (provider.status.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: provider.lastParseResult?.success ?? false
                  ? AppColors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Text(provider.status, style: AppTypography.bodySmall),
          ),
        ],
        // Password input section
        if (provider.showPasswordInput) ...[
          const SizedBox(height: AppSpacing.xl2),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.warning),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.lock, color: AppColors.warning),
                    const SizedBox(width: AppSpacing.md),
                    const Expanded(
                      child: Text(
                        'This PDF is password-protected',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Enter PDF password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  onChanged: (value) => provider.setPassword(value),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: provider.isLoading
                      ? null
                      : () async {
                          if (_selectedFilePath != null) {
                            await provider.submitPassword(_selectedFilePath!);
                          }
                        },
                  icon: provider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Unlock PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton(
                  onPressed: () => provider.hidePasswordInput(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ],
        // Error recovery section for corrupted PDFs or bank detection failures
        if (!provider.showPasswordInput &&
            provider.lastParseResult != null &&
            !provider.lastParseResult!.success &&
            (provider.status.contains('corrupted') ||
                provider.status.contains('detect bank'))) ...[
          const SizedBox(height: AppSpacing.xl2),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: Colors.orange),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: AppSpacing.md),
                    const Expanded(
                      child: Text(
                        'Cannot extract text automatically',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'This PDF might be scanned or image-based. You can try selecting the bank manually.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: () => _showBankSelectionDialog(context, provider),
                  icon: const Icon(Icons.select_all),
                  label: const Text('Select Bank Manually'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedFilePath = null;
                    });
                    provider.reset();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Another PDF'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAccountSelectionStep(
    BuildContext context,
    PDFImportProvider provider,
  ) {
    final statement = provider.currentStatement;
    if (statement == null) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Select or Create Account', style: AppTypography.headlineSmall),
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Statement Details:', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.md),
                _buildDetailRow(
                  'Bank:',
                  statement.metadata.bankName ?? 'Unknown',
                ),
                _buildDetailRow(
                  'Account Number:',
                  statement.metadata.accountNumber ?? 'Not detected',
                ),
                _buildDetailRow(
                  'Account Holder:',
                  statement.metadata.accountHolder ?? 'Not detected',
                ),
                _buildDetailRow(
                  'Transactions:',
                  '${statement.transactionCount}',
                ),
                _buildDetailRow(
                  'Income / Expenses:',
                  '${statement.incomeCount} income • ${statement.expenseCount} expenses',
                ),
                _buildDetailRow(
                  'Totals:',
                  '₹${statement.incomeTotal.toStringAsFixed(2)} income • ₹${statement.expenseTotal.toStringAsFixed(2)} expenses',
                ),
                _buildDetailRow('Period:', statement.dateRange),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl2),
        Text('Account Options:', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.lg),
        ElevatedButton(
          onPressed: () => _showAccountSelectionDialog(context, provider),
          child: const Text('Select Existing Account'),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(
          onPressed: () =>
              _showCreateAccountDialog(context, provider, statement),
          child: const Text('Create New Account'),
        ),
        const SizedBox(height: AppSpacing.xl2),
        if (provider.selectedAccount != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Selected: ${provider.selectedAccount!.name}',
                    style: AppTypography.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: () => _proceedToDuplicateCheck(context, provider),
            child: const Text('Continue to Review'),
          ),
        ] else if (provider.accountToCreate != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.info),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'New account: ${provider.accountToCreate!.name}',
                    style: AppTypography.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: () => _proceedToDuplicateCheck(context, provider),
            child: const Text('Create & Continue'),
          ),
        ],
      ],
    );
  }

  Widget _buildPreviewStep(BuildContext context, PDFImportProvider provider) {
    final statement = provider.currentStatement;
    if (statement == null) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Review & Import', style: AppTypography.headlineSmall),
        const SizedBox(height: AppSpacing.lg),
        // Summary cards
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total',
                '${statement.transactionCount}',
                AppColors.info,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: _buildSummaryCard(
                'Duplicates',
                '${provider.duplicateCount}',
                Colors.orange,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: _buildSummaryCard(
                'To Import',
                '${provider.importableCount}',
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Income',
                '${statement.incomeCount} • ₹${statement.incomeTotal.toStringAsFixed(2)}',
                Colors.green,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: _buildSummaryCard(
                'Expenses',
                '${statement.expenseCount} • ₹${statement.expenseTotal.toStringAsFixed(2)}',
                AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl2),
        // Duplicate list
        if (provider.duplicateCount > 0) ...[
          Text('Detected Duplicates:', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.orange),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: ListView.builder(
              itemCount: provider.duplicateResults!.length,
              itemBuilder: (context, index) {
                final entry = provider.duplicateResults!.entries
                    .toList()[index];
                if (!entry.value.isDuplicate) {
                  return const SizedBox();
                }

                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.key.date} - ${entry.key.description}',
                        style: AppTypography.bodySmall,
                      ),
                      Text(
                        '₹${entry.key.amount} (Confidence: ${entry.value.confidenceScore.toStringAsFixed(0)}%)',
                        style: AppTypography.labelSmall,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        // Import button
        ElevatedButton(
          onPressed: provider.isLoading
              ? null
              : () => _confirmImport(context, provider),
          child: provider.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Import Transactions'),
        ),
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton(
          onPressed: () {
            provider.reset();
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(value, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Text(label, style: AppTypography.labelSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: AppTypography.headlineMedium.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndParsePDF(
    BuildContext context,
    PDFImportProvider provider,
  ) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path;
        if (filePath != null) {
          _selectedFilePath = filePath;
          if (mounted) {
            await provider.parsePDF(filePath);
          }
        }
      }
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
    }
  }

  Future<void> _showAccountSelectionDialog(
    BuildContext context,
    PDFImportProvider provider,
  ) async {
    final accountProvider = context.read<AccountProvider>();
    final existingAccounts = accountProvider.accounts;

    if (existingAccounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No existing accounts. Please create one first.'),
        ),
      );
      return;
    }

    // Try to find a matching account by account number or similar
    final statement = provider.currentStatement;
    dynamic matchedAccount;

    if (statement?.metadata.accountNumber != null) {
      try {
        matchedAccount = existingAccounts.firstWhere(
          (acc) =>
              acc.accountNumber?.toLowerCase().contains(
                statement!.metadata.accountNumber!.toLowerCase(),
              ) ??
              false,
        );
      } catch (e) {
        // No match found
      }
    }

    if (!context.mounted) {
      return;
    }

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
                    'Select Account',
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
              const SizedBox(height: 16),
              if (matchedAccount != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Matched: ${matchedAccount.name}',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  child: Column(
                    children: existingAccounts.map((account) {
                      final bankLogo = LogoUtils.bankLogoFor(
                        account.bankName ?? account.name,
                      );
                      final isMatched = account.id == matchedAccount?.id;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isMatched
                              ? AppColors.primaryBlue.withValues(alpha: 0.1)
                              : AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isMatched
                                ? AppColors.primaryBlue.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          leading: bankLogo != null
                              ? SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: LogoUtils.buildLogo(
                                    bankLogo,
                                    size: 32,
                                  ),
                                )
                              : Icon(
                                  account.icon,
                                  color: AppColors.textSecondary,
                                ),
                          title: Text(
                            account.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            account.typeDisplayName,
                            style: TextStyle(color: AppColors.textTertiary),
                          ),
                          trailing: isMatched
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.success,
                                )
                              : null,
                          onTap: () {
                            provider.selectAccount(account);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateAccountDialog(
    BuildContext context,
    PDFImportProvider provider,
    dynamic statement,
  ) async {
    String accountName = statement.metadata.bankName ?? 'New Account';
    String bankName = statement.metadata.bankName ?? 'Unknown';
    String accountNumber = statement.metadata.accountNumber ?? '';
    AccountType selectedAccountType = AccountType.savings;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: AppColors.backgroundBlack,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            insetPadding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
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
                          'Create Account',
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
                    const SizedBox(height: 24),
                    _buildDialogLabel('ACCOUNT NAME'),
                    _buildDialogGlassField(
                      initialValue: accountName,
                      hint: 'Account Name',
                      onChanged: (v) => accountName = v,
                    ),
                    const SizedBox(height: 16),
                    _buildDialogLabel('BANK NAME'),
                    _buildDialogGlassField(
                      initialValue: bankName,
                      hint: 'Bank Name',
                      onChanged: (v) => bankName = v,
                    ),
                    const SizedBox(height: 16),
                    _buildDialogLabel('ACCOUNT NUMBER'),
                    _buildDialogGlassField(
                      initialValue: accountNumber,
                      hint: 'Account Number (optional)',
                      onChanged: (v) => accountNumber = v,
                    ),
                    const SizedBox(height: 16),
                    _buildDialogLabel('ACCOUNT TYPE'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<AccountType>(
                          value: selectedAccountType,
                          isExpanded: true,
                          dropdownColor: AppColors.cardElevated,
                          style: const TextStyle(color: Colors.white),
                          items: AccountType.values
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(
                                    type.name.replaceFirst(
                                      type.name[0],
                                      type.name[0].toUpperCase(),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(
                            () =>
                                selectedAccountType = v ?? AccountType.savings,
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
                          provider.createNewAccount(
                            accountName: accountName,
                            bankName: bankName,
                            accountType: selectedAccountType,
                            accountColor: AppColors.info,
                            accountIcon: Icons.account_balance,
                            accountNumber: accountNumber.isNotEmpty
                                ? accountNumber
                                : null,
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Create Account',
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
        },
      ),
    );
  }

  Widget _buildDialogLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(
      text,
      style: TextStyle(
        color: AppColors.textTertiary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _buildDialogGlassField({
    required String hint,
    String? initialValue,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TextFormField(
        initialValue: initialValue,
        style: const TextStyle(color: Colors.white),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Future<void> _showBankSelectionDialog(
    BuildContext context,
    PDFImportProvider provider,
  ) async {
    String? selectedBank;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: AppColors.backgroundBlack,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
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
                        'Select Bank',
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
                    'Select the bank for this statement',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: PDFImportProvider.supportedBanks.map((bank) {
                      final isSelected = selectedBank == bank;
                      return GestureDetector(
                        onTap: () => setState(
                          () => selectedBank = isSelected ? null : bank,
                        ),
                        child: AnimatedContainer(
                          duration: AppAnimations.standard,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryBlue.withValues(alpha: 0.2)
                                : AppColors.cardSurface,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Text(
                            bank,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: selectedBank != null
                          ? () async {
                              Navigator.pop(context);
                              if (_selectedFilePath != null) {
                                await provider.parsePDF(
                                  _selectedFilePath!,
                                  userSelectedBank: selectedBank,
                                );
                                if (!context.mounted) {
                                  return;
                                }
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        disabledBackgroundColor: AppColors.cardSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Continue',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: selectedBank != null
                              ? Colors.white
                              : AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _proceedToDuplicateCheck(
    BuildContext context,
    PDFImportProvider provider,
  ) async {
    debugPrint('[PDF Import] Starting duplicate check...');

    // Fetch existing transactions from TransactionProvider
    final transactionProvider = context.read<TransactionProvider>();
    final existingTransactions = transactionProvider.transactions;

    debugPrint(
      '[PDF Import] Checking against ${existingTransactions.length} existing transactions',
    );

    await provider.checkDuplicates(existingTransactions);

    debugPrint(
      '[PDF Import] Duplicate check complete. Duplicate results: ${provider.duplicateResults != null}',
    );
    debugPrint(
      '[PDF Import] Importable count: ${provider.importableCount}, Duplicate count: ${provider.duplicateCount}',
    );
  }

  Future<void> _confirmImport(
    BuildContext context,
    PDFImportProvider provider,
  ) async {
    debugPrint('[PDF Import] Starting import process...');

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: AppColors.backgroundBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primaryBlue),
              const SizedBox(height: 24),
              Text(
                'Importing ${provider.importableCount} transactions...',
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final accountProvider = context.read<AccountProvider>();
      final transactionProvider = context.read<TransactionProvider>();
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Step 1: Create account if needed
      String accountId;
      if (provider.accountToCreate != null) {
        debugPrint(
          '[PDF Import] Creating new account: ${provider.accountToCreate!.name}',
        );

        // Use the Account object directly
        await accountProvider.addAccount(provider.accountToCreate!);

        // Get the newly created account ID
        final newAccount = accountProvider.accounts.firstWhere(
          (acc) => acc.name == provider.accountToCreate!.name,
        );
        accountId = newAccount.id;

        debugPrint('[PDF Import] Account created with ID: $accountId');
      } else if (provider.selectedAccount != null) {
        accountId = provider.selectedAccount!.id;
        debugPrint(
          '[PDF Import] Using existing account: ${provider.selectedAccount!.name} ($accountId)',
        );
      } else {
        throw Exception('No account selected or created');
      }

      // Step 2: Import transactions (excluding duplicates, updating type mismatches)
      int importedCount = 0;
      int skippedCount = 0;
      int updatedCount = 0;

      final duplicateResults = provider.duplicateResults!;
      final now = DateTime.now();

      for (final entry in duplicateResults.entries) {
        final pdfTransaction = entry.key;
        final duplicateCheck = entry.value;

        if (duplicateCheck.isDuplicate) {
          // Check if this duplicate needs a type update
          if (duplicateCheck.needsTypeUpdate &&
              duplicateCheck.matchingTransactionId != null) {
            debugPrint(
              '[PDF Import] Updating transaction type: ${pdfTransaction.description}',
            );

            // Find the existing transaction
            final existingTransaction = transactionProvider.transactions
                .firstWhere(
                  (t) => t.id == duplicateCheck.matchingTransactionId,
                );

            // Determine correct type based on amount
            final isExpense = pdfTransaction.amount < 0;
            final correctType = isExpense
                ? TransactionType.expense
                : TransactionType.income;

            // Create updated transaction
            final updatedTransaction = Transaction(
              id: existingTransaction.id,
              userId: existingTransaction.userId,
              type: correctType, // Corrected type
              amount: existingTransaction.amount,
              description: existingTransaction.description,
              categoryId: existingTransaction.categoryId,
              accountId: existingTransaction.accountId,
              date: existingTransaction.date,
              metadata: existingTransaction.metadata,
              attachments: existingTransaction.attachments,
              createdAt: existingTransaction.createdAt,
              updatedAt: now, // Update timestamp
            );

            // Update the transaction
            await transactionProvider.updateTransaction(
              updatedTransaction,
              existingTransaction,
            );

            updatedCount++;

            if (updatedCount % 10 == 0) {
              debugPrint(
                '[PDF Import] Updated $updatedCount transaction types...',
              );
            }
          } else {
            skippedCount++;
            debugPrint(
              '[PDF Import] Skipping duplicate: ${pdfTransaction.description}',
            );
          }
          continue;
        }

        // Determine transaction type based on amount
        // Negative amounts are expenses, positive are income
        final isExpense = pdfTransaction.amount < 0;

        // Create Transaction object
        final transaction = Transaction(
          id: '', // Will be set by Firestore
          userId: currentUser.uid,
          type: isExpense ? TransactionType.expense : TransactionType.income,
          amount: pdfTransaction.amount.abs(),
          description: pdfTransaction.description,
          categoryId: null, // Let user categorize later
          accountId: accountId,
          date: DateTime.tryParse(pdfTransaction.date) ?? now,
          metadata: {'importedFromPDF': true, 'pdfSource': 'bank_statement'},
          attachments: null,
          createdAt: now,
          updatedAt: now,
        );

        // Add transaction
        await transactionProvider.addTransaction(transaction);

        importedCount++;

        if (importedCount % 10 == 0) {
          debugPrint('[PDF Import] Imported $importedCount transactions...');
        }
      }

      debugPrint(
        '[PDF Import] Import complete! Imported: $importedCount, Updated: $updatedCount, Skipped: $skippedCount',
      );

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Step 3: Show success message and close
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updatedCount > 0
                ? 'Imported $importedCount new transactions, updated $updatedCount incorrect types! ($skippedCount duplicates skipped)'
                : 'Successfully imported $importedCount transactions! ($skippedCount duplicates skipped)',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

      // Reset provider and go back
      provider.reset();
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('[PDF Import] Error during import: $e');

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
