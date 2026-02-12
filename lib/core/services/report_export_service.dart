import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:share_plus/share_plus.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../models/budget.dart';
import 'expense_trend_service.dart';

/// Service for exporting financial reports in various formats
class ReportExportService {
  final _dateFormat = DateFormat('dd MMM yyyy');
  final _monthFormat = DateFormat('MMMM yyyy');
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  /// Export transactions to PDF
  Future<File> exportTransactionsPdf({
    required List<Transaction> transactions,
    required List<Account> accounts,
    required String userName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();

    // Filter transactions by date range
    final filteredTransactions = _filterByDateRange(
      transactions,
      startDate,
      endDate,
    );

    // Calculate totals
    final totalIncome = filteredTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = filteredTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    // Group by category
    final categoryTotals = <String, double>{};
    for (final t in filteredTransactions.where(
      (t) => t.type == TransactionType.expense,
    )) {
      final cat = t.categoryId ?? 'Uncategorized';
      categoryTotals[cat] = (categoryTotals[cat] ?? 0) + t.amount;
    }

    final dateRange = startDate != null && endDate != null
        ? '${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}'
        : 'All Time';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildPdfHeader(userName, dateRange),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          // Summary Section
          _buildSummarySection(totalIncome, totalExpense),
          pw.SizedBox(height: 20),

          // Category Breakdown
          if (categoryTotals.isNotEmpty) ...[
            _buildCategorySection(categoryTotals, totalExpense),
            pw.SizedBox(height: 20),
          ],

          // Transaction List
          _buildTransactionTable(filteredTransactions, accounts),
        ],
      ),
    );

    // Save file
    final directory = await path_provider.getApplicationDocumentsDirectory();
    final fileName =
        'nexus_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Export transactions to CSV (Excel-compatible)
  Future<File> exportTransactionsCsv({
    required List<Transaction> transactions,
    required List<Account> accounts,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final filteredTransactions = _filterByDateRange(
      transactions,
      startDate,
      endDate,
    );
    final accountMap = {for (var a in accounts) a.id: a.name};

    final buffer = StringBuffer();

    // CSV Header
    buffer.writeln('Date,Type,Amount,Description,Category,Account');

    // Data rows
    for (final t in filteredTransactions) {
      final date = _dateFormat.format(t.date);
      final type = t.type.name;
      final amount = t.amount.toStringAsFixed(2);
      final description = _escapeCsv(t.description ?? '');
      final category = _escapeCsv(t.categoryId ?? 'Uncategorized');
      final account = _escapeCsv(accountMap[t.accountId] ?? 'Unknown');

      buffer.writeln('$date,$type,$amount,$description,$category,$account');
    }

    // Save file
    final directory = await path_provider.getApplicationDocumentsDirectory();
    final fileName =
        'nexus_transactions_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(buffer.toString());

    return file;
  }

  /// Export monthly summary report
  Future<File> exportMonthlySummaryPdf({
    required List<Transaction> transactions,
    required List<Budget> budgets,
    required String userName,
    required DateTime month,
  }) async {
    final pdf = pw.Document();
    final trendService = ExpenseTrendService();

    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);

    // Filter transactions for the month
    final monthTransactions = _filterByDateRange(
      transactions,
      startOfMonth,
      endOfMonth,
    );

    // Calculate totals
    final totalIncome = monthTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = monthTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    // Daily spending
    final dailySpending = trendService.getDailySpending(
      transactions,
      startDate: startOfMonth,
      endDate: endOfMonth,
    );

    // Category breakdown
    final categorySpending = trendService.getSpendingByCategory(
      transactions,
      startDate: startOfMonth,
      endDate: endOfMonth,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildPdfHeader(
          userName,
          'Monthly Report - ${_monthFormat.format(month)}',
        ),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          // Overview
          _buildMonthlySummarySection(totalIncome, totalExpense),
          pw.SizedBox(height: 20),

          // Budget Performance
          if (budgets.isNotEmpty) ...[
            _buildBudgetPerformanceSection(budgets),
            pw.SizedBox(height: 20),
          ],

          // Category Breakdown
          if (categorySpending.isNotEmpty) ...[
            _buildCategorySection(categorySpending, totalExpense),
            pw.SizedBox(height: 20),
          ],

          // Top Expenses
          _buildTopExpensesSection(monthTransactions),
        ],
      ),
    );

    // Save file
    final directory = await path_provider.getApplicationDocumentsDirectory();
    final fileName = 'nexus_monthly_${month.year}_${month.month}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Share exported file
  Future<void> shareFile(File file, {String? subject}) async {
    await Share.shareXFiles([
      XFile(file.path),
    ], subject: subject ?? 'Nexus Financial Report');
  }

  // PDF Building Helpers
  pw.Widget _buildPdfHeader(String userName, String dateRange) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'NEXUS',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.Text(
                'Financial Report',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                userName,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                dateRange,
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
      ),
    );
  }

  pw.Widget _buildSummarySection(double income, double expense) {
    final savings = income - expense;
    final savingsRate = income > 0 ? (savings / income) * 100 : 0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total Income', income, PdfColors.green700),
          _buildSummaryItem('Total Expense', expense, PdfColors.red700),
          _buildSummaryItem(
            'Net Savings',
            savings,
            savings >= 0 ? PdfColors.green700 : PdfColors.red700,
          ),
          _buildSummaryItem(
            'Savings Rate',
            null,
            PdfColors.blue700,
            suffix: '${savingsRate.toStringAsFixed(1)}%',
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryItem(
    String label,
    double? amount,
    PdfColor color, {
    String? suffix,
  }) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          suffix ?? _currencyFormat.format(amount),
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildMonthlySummarySection(double income, double expense) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Monthly Overview',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Income', income, PdfColors.green700),
              _buildSummaryItem('Expenses', expense, PdfColors.red700),
              _buildSummaryItem(
                'Balance',
                income - expense,
                income >= expense ? PdfColors.green700 : PdfColors.red700,
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCategorySection(
    Map<String, double> categories,
    double total,
  ) {
    final sortedCategories = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Spending by Category',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Category', isHeader: true),
                _buildTableCell('Amount', isHeader: true),
                _buildTableCell('%', isHeader: true),
              ],
            ),
            ...sortedCategories.take(10).map((entry) {
              final percentage = total > 0 ? (entry.value / total) * 100 : 0;
              return pw.TableRow(
                children: [
                  _buildTableCell(entry.key),
                  _buildTableCell(_currencyFormat.format(entry.value)),
                  _buildTableCell('${percentage.toStringAsFixed(1)}%'),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildBudgetPerformanceSection(List<Budget> budgets) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Budget Performance',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Category', isHeader: true),
                _buildTableCell('Budget', isHeader: true),
                _buildTableCell('Spent', isHeader: true),
                _buildTableCell('Status', isHeader: true),
              ],
            ),
            ...budgets.map((budget) {
              final percentage = budget.spentPercentage;
              String status;
              PdfColor statusColor;
              if (percentage > 100) {
                status = 'Over';
                statusColor = PdfColors.red700;
              } else if (percentage > 80) {
                status = 'Warning';
                statusColor = PdfColors.orange700;
              } else {
                status = 'OK';
                statusColor = PdfColors.green700;
              }

              return pw.TableRow(
                children: [
                  _buildTableCell(budget.categoryName),
                  _buildTableCell(
                    _currencyFormat.format(budget.allocatedAmount),
                  ),
                  _buildTableCell(_currencyFormat.format(budget.spentAmount)),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      status,
                      style: pw.TextStyle(color: statusColor, fontSize: 10),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTopExpensesSection(List<Transaction> transactions) {
    final expenses =
        transactions.where((t) => t.type == TransactionType.expense).toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Top Expenses',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Date', isHeader: true),
                _buildTableCell('Description', isHeader: true),
                _buildTableCell('Amount', isHeader: true),
              ],
            ),
            ...expenses
                .take(10)
                .map(
                  (t) => pw.TableRow(
                    children: [
                      _buildTableCell(_dateFormat.format(t.date)),
                      _buildTableCell(t.description ?? 'No description'),
                      _buildTableCell(_currencyFormat.format(t.amount)),
                    ],
                  ),
                ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTransactionTable(
    List<Transaction> transactions,
    List<Account> accounts,
  ) {
    final accountMap = {for (var a in accounts) a.id: a.name};
    final sorted = transactions.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Transaction Details (${transactions.length} transactions)',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(3),
            4: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Date', isHeader: true),
                _buildTableCell('Type', isHeader: true),
                _buildTableCell('Amount', isHeader: true),
                _buildTableCell('Description', isHeader: true),
                _buildTableCell('Account', isHeader: true),
              ],
            ),
            ...sorted.take(100).map((t) {
              final typeColor = t.type == TransactionType.income
                  ? PdfColors.green700
                  : (t.type == TransactionType.expense
                        ? PdfColors.red700
                        : PdfColors.blue700);

              return pw.TableRow(
                children: [
                  _buildTableCell(_dateFormat.format(t.date)),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      t.type.name.toUpperCase(),
                      style: pw.TextStyle(fontSize: 8, color: typeColor),
                    ),
                  ),
                  _buildTableCell(_currencyFormat.format(t.amount)),
                  _buildTableCell(t.description ?? '-'),
                  _buildTableCell(accountMap[t.accountId] ?? 'Unknown'),
                ],
              );
            }),
          ],
        ),
        if (sorted.length > 100)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              '... and ${sorted.length - 100} more transactions (export to CSV for complete list)',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
            ),
          ),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  // Helper methods
  List<Transaction> _filterByDateRange(
    List<Transaction> transactions,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    return transactions.where((t) {
      if (startDate != null && t.date.isBefore(startDate)) return false;
      if (endDate != null &&
          t.date.isAfter(endDate.add(const Duration(days: 1))))
        return false;
      return true;
    }).toList();
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
