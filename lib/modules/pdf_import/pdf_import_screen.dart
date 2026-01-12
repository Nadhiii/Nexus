import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/models/account.dart';
import '../../core/providers/pdf_import_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';

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
        backgroundColor: AppColors.transparent,
        elevation: 0,
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
                      color: AppColors.green.withOpacity(0.1),
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
                  ? AppColors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Text(provider.status, style: AppTypography.bodySmall),
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
    if (statement == null) return const SizedBox();

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
              color: AppColors.green.withOpacity(0.1),
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
              color: AppColors.info.withOpacity(0.1),
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
    if (statement == null) return const SizedBox();

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
                if (!entry.value.isDuplicate) return const SizedBox();

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
      color: color.withOpacity(0.1),
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      }
    }
  }

  Future<void> _showAccountSelectionDialog(
    BuildContext context,
    PDFImportProvider provider,
  ) async {
    // TODO: Fetch existing accounts from AccountProvider
    // This is a placeholder
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Account'),
        content: const Text('Integration with AccountProvider needed'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateAccountDialog(
    BuildContext context,
    PDFImportProvider provider,
    dynamic statement,
  ) async {
    String accountName = statement.metadata.accountHolder ?? 'New Account';
    String bankName = statement.metadata.bankName ?? 'Unknown';
    String accountNumber = statement.metadata.accountNumber ?? '';
    AccountType selectedAccountType = AccountType.savings;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Create New Account'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: accountName,
                    decoration: const InputDecoration(
                      labelText: 'Account Name',
                    ),
                    onChanged: (v) => accountName = v,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    initialValue: bankName,
                    decoration: const InputDecoration(labelText: 'Bank Name'),
                    onChanged: (v) => bankName = v,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    initialValue: accountNumber,
                    decoration: const InputDecoration(
                      labelText: 'Account Number',
                    ),
                    onChanged: (v) => accountNumber = v,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  DropdownButton<AccountType>(
                    value: selectedAccountType,
                    onChanged: (v) => setState(
                      () => selectedAccountType = v ?? AccountType.savings,
                    ),
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
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
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
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _proceedToDuplicateCheck(
    BuildContext context,
    PDFImportProvider provider,
  ) async {
    // TODO: Fetch existing transactions from TransactionProvider
    // For now, check against empty list
    await provider.checkDuplicates([]);
  }

  Future<void> _confirmImport(
    BuildContext context,
    PDFImportProvider provider,
  ) async {
    // TODO: Implement actual import logic
    // This should:
    // 1. Create account if needed
    // 2. Create transactions
    // 3. Update AccountProvider

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Ready to import ${provider.importableCount} transactions',
        ),
      ),
    );
  }
}
