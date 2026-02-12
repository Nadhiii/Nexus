import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/report_export_service.dart';
import '../../core/providers/transaction_provider.dart';
import '../../core/providers/account_provider.dart';
import '../../core/providers/budget_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/top_snackbar.dart';

/// Screen for exporting financial reports
class ExportReportsScreen extends StatefulWidget {
  const ExportReportsScreen({super.key});

  @override
  State<ExportReportsScreen> createState() => _ExportReportsScreenState();
}

class _ExportReportsScreenState extends State<ExportReportsScreen> {
  final _exportService = ReportExportService();

  ExportType _selectedType = ExportType.transactions;
  ExportFormat _selectedFormat = ExportFormat.pdf;
  DateRange _selectedRange = DateRange.thisMonth;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBlack,
        title: Text(
          'Export Reports',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report Type Selection
            _buildSectionTitle('Report Type'),
            SizedBox(height: AppSpacing.sm),
            _buildReportTypeSelector(),
            SizedBox(height: AppSpacing.xl),

            // Format Selection
            _buildSectionTitle('Export Format'),
            SizedBox(height: AppSpacing.sm),
            _buildFormatSelector(),
            SizedBox(height: AppSpacing.xl),

            // Date Range Selection
            _buildSectionTitle('Date Range'),
            SizedBox(height: AppSpacing.sm),
            _buildDateRangeSelector(),
            SizedBox(height: AppSpacing.xl),

            // Preview Info
            _buildPreviewCard(),
            SizedBox(height: AppSpacing.xl),

            // Export Button
            _buildExportButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary),
    );
  }

  Widget _buildReportTypeSelector() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: ExportType.values.map((type) {
        final isSelected = _selectedType == type;
        return _buildChip(
          label: type.displayName,
          icon: type.icon,
          isSelected: isSelected,
          onTap: () => setState(() => _selectedType = type),
        );
      }).toList(),
    );
  }

  Widget _buildFormatSelector() {
    return Row(
      children: ExportFormat.values.map((format) {
        final isSelected = _selectedFormat == format;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: format != ExportFormat.values.last ? AppSpacing.sm : 0,
            ),
            child: _buildFormatCard(
              label: format.displayName,
              description: format.description,
              icon: format.icon,
              isSelected: isSelected,
              onTap: () => setState(() => _selectedFormat = format),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFormatCard({
    required String label,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue.withOpacity(0.2)
              : AppColors.cardDark,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.cardElevated,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? AppColors.primaryBlue
                  : AppColors.textSecondary,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected
                    ? AppColors.primaryBlue
                    : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              description,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Column(
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: DateRange.values.map((range) {
            final isSelected = _selectedRange == range;
            return _buildChip(
              label: range.displayName,
              isSelected: isSelected,
              onTap: () {
                setState(() => _selectedRange = range);
                if (range == DateRange.custom) {
                  _showCustomDatePicker();
                }
              },
            );
          }).toList(),
        ),
        if (_selectedRange == DateRange.custom && _customStartDate != null) ...[
          SizedBox(height: AppSpacing.md),
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.date_range, size: 16, color: AppColors.textTertiary),
                SizedBox(width: AppSpacing.sm),
                Text(
                  '${_formatDate(_customStartDate!)} - ${_formatDate(_customEndDate ?? DateTime.now())}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                GestureDetector(
                  onTap: _showCustomDatePicker,
                  child: Icon(
                    Icons.edit,
                    size: 16,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : AppColors.cardDark,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.cardElevated,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.white : AppColors.textSecondary,
              ),
              SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? AppColors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final transactionProvider = context.watch<TransactionProvider>();
    final dateRange = _getDateRange();

    final transactionsCount = transactionProvider.transactions.where((t) {
      if (dateRange.$1 != null && t.date.isBefore(dateRange.$1!)) return false;
      if (dateRange.$2 != null &&
          t.date.isAfter(dateRange.$2!.add(const Duration(days: 1)))) {
        return false;
      }
      return true;
    }).length;

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.cardElevated),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview, color: AppColors.textSecondary, size: 20),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Export Preview',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          _buildPreviewRow('Report Type', _selectedType.displayName),
          _buildPreviewRow('Format', _selectedFormat.displayName),
          _buildPreviewRow('Date Range', _selectedRange.displayName),
          _buildPreviewRow('Transactions', '$transactionsCount records'),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isExporting ? null : _exportReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
        child: _isExporting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.file_download, color: AppColors.white),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'Export & Share',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _exportReport() async {
    setState(() => _isExporting = true);

    try {
      final transactionProvider = context.read<TransactionProvider>();
      final accountProvider = context.read<AccountProvider>();
      final budgetProvider = context.read<BudgetProvider>();

      final dateRange = _getDateRange();
      File? file;

      switch (_selectedType) {
        case ExportType.transactions:
          if (_selectedFormat == ExportFormat.pdf) {
            file = await _exportService.exportTransactionsPdf(
              transactions: transactionProvider.transactions,
              accounts: accountProvider.accounts,
              userName: 'User', // TODO: Get from auth
              startDate: dateRange.$1,
              endDate: dateRange.$2,
            );
          } else {
            file = await _exportService.exportTransactionsCsv(
              transactions: transactionProvider.transactions,
              accounts: accountProvider.accounts,
              startDate: dateRange.$1,
              endDate: dateRange.$2,
            );
          }
          break;

        case ExportType.monthlySummary:
          final month = dateRange.$1 ?? DateTime.now();
          file = await _exportService.exportMonthlySummaryPdf(
            transactions: transactionProvider.transactions,
            budgets: budgetProvider.budgets,
            userName: 'User',
            month: month,
          );
          break;
      }

      await _exportService.shareFile(
        file,
        subject: 'Nexus ${_selectedType.displayName} Report',
      );

      if (mounted) {
        showTopSnackBar(context, 'Report exported successfully!');
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(context, 'Failed to export: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  (DateTime?, DateTime?) _getDateRange() {
    final now = DateTime.now();

    switch (_selectedRange) {
      case DateRange.thisMonth:
        return (DateTime(now.year, now.month, 1), now);
      case DateRange.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        final lastDayOfLastMonth = DateTime(now.year, now.month, 0);
        return (lastMonth, lastDayOfLastMonth);
      case DateRange.last3Months:
        return (DateTime(now.year, now.month - 3, 1), now);
      case DateRange.last6Months:
        return (DateTime(now.year, now.month - 6, 1), now);
      case DateRange.thisYear:
        return (DateTime(now.year, 1, 1), now);
      case DateRange.allTime:
        return (null, null);
      case DateRange.custom:
        return (_customStartDate, _customEndDate);
    }
  }

  Future<void> _showCustomDatePicker() async {
    final now = DateTime.now();

    final startDate = await showDatePicker(
      context: context,
      initialDate: _customStartDate ?? now.subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: 'Select Start Date',
    );

    if (startDate == null || !mounted) return;

    final endDate = await showDatePicker(
      context: context,
      initialDate: _customEndDate ?? now,
      firstDate: startDate,
      lastDate: now,
      helpText: 'Select End Date',
    );

    if (endDate != null && mounted) {
      setState(() {
        _customStartDate = startDate;
        _customEndDate = endDate;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

enum ExportType {
  transactions('Transaction History', Icons.receipt_long),
  monthlySummary('Monthly Summary', Icons.calendar_month);

  final String displayName;
  final IconData icon;
  const ExportType(this.displayName, this.icon);
}

enum ExportFormat {
  pdf('PDF', 'Formatted report', Icons.picture_as_pdf),
  csv('CSV', 'Excel compatible', Icons.table_chart);

  final String displayName;
  final String description;
  final IconData icon;
  const ExportFormat(this.displayName, this.description, this.icon);
}

enum DateRange {
  thisMonth('This Month'),
  lastMonth('Last Month'),
  last3Months('Last 3 Months'),
  last6Months('Last 6 Months'),
  thisYear('This Year'),
  allTime('All Time'),
  custom('Custom');

  final String displayName;
  const DateRange(this.displayName);
}
