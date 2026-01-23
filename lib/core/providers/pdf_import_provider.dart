import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pdf_statement.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../services/pdf_parsing_service.dart';
import '../services/pdf_password_manager.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';

class PDFImportProvider extends ChangeNotifier {
  final PDFParsingService _parsingService = PDFParsingService();

  PDFStatement? _currentStatement;
  PDFParseResult? _lastParseResult;
  Map<ExtractedTransaction, DuplicateCheckResult>? _duplicateResults;
  Account? _selectedAccount;
  Account? _accountToCreate;
  bool _isLoading = false;
  String _status = '';
  bool _showPasswordInput = false;
  String _currentPassword = '';
  int _savedPasswordCount = 0;

  PDFStatement? get currentStatement => _currentStatement;
  PDFParseResult? get lastParseResult => _lastParseResult;
  Map<ExtractedTransaction, DuplicateCheckResult>? get duplicateResults =>
      _duplicateResults;
  Account? get selectedAccount => _selectedAccount;
  Account? get accountToCreate => _accountToCreate;
  bool get isLoading => _isLoading;
  String get status => _status;
  bool get showPasswordInput => _showPasswordInput;
  String get currentPassword => _currentPassword;
  int get savedPasswordCount => _savedPasswordCount;

  int get importableCount {
    if (_duplicateResults == null)
      return _currentStatement?.transactionCount ?? 0;
    return _duplicateResults!.values.where((r) => !r.isDuplicate).length;
  }

  int get duplicateCount {
    if (_duplicateResults == null) return 0;
    return _duplicateResults!.values.where((r) => r.isDuplicate).length;
  }

  Future<void> loadSavedPasswordCount() async {
    _savedPasswordCount = await PDFPasswordManager.getPasswordCount();
    notifyListeners();
  }

  Future<void> parsePDF(
    String filePath, {
    String? userSelectedBank,
    String? userPassword,
  }) async {
    _isLoading = true;
    _showPasswordInput = false;
    _status = 'Parsing PDF...';
    notifyListeners();

    try {
      final result = await _parsingService.parsePDF(
        filePath,
        userSelectedBank: userSelectedBank,
        userProvidedPassword: userPassword,
      );

      _lastParseResult = result;

      if (result.success && result.statement != null) {
        _currentStatement = result.statement;
        _status =
            'PDF parsed successfully. ${result.statement!.transactionCount} transactions found.';
        _duplicateResults = null;
        _selectedAccount = null;
        _accountToCreate = null;
        await loadSavedPasswordCount();
      } else if (result.requiresPassword) {
        _showPasswordInput = true;
        _status = 'PDF is password-protected. Please enter the password.';
      } else {
        _status = result.errors.join(', ');
      }
    } catch (e) {
      _status = 'Error: $e';
      _lastParseResult = PDFParseResult(
        success: false,
        errors: ['Failed to parse PDF: $e'],
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setPassword(String password) {
    _currentPassword = password;
    notifyListeners();
  }

  Future<void> submitPassword(
    String filePath, {
    String? userSelectedBank,
  }) async {
    if (_currentPassword.isEmpty) {
      _status = 'Please enter a password';
      notifyListeners();
      return;
    }
    await parsePDF(
      filePath,
      userSelectedBank: userSelectedBank,
      userPassword: _currentPassword,
    );
    _currentPassword = '';
  }

  void hidePasswordInput() {
    _showPasswordInput = false;
    _currentPassword = '';
    notifyListeners();
  }

  Future<void> checkDuplicates(dynamic existingTransactions) async {
    if (_currentStatement == null) return;
    _isLoading = true;
    _status = 'Checking for duplicates...';
    notifyListeners();
    try {
      _duplicateResults = await _parsingService.checkDuplicates(
        _currentStatement!.transactions,
        existingTransactions,
      );
      _status = 'Duplicate check complete. $duplicateCount duplicates found.';
    } catch (e) {
      _status = 'Error checking duplicates: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectAccount(Account account) {
    _selectedAccount = account;
    _accountToCreate = null;
    _status = 'Account selected: ${account.name}';
    notifyListeners();
  }

  void createNewAccount({
    required String accountName,
    required String bankName,
    required AccountType accountType,
    required Color accountColor,
    required IconData accountIcon,
    String? accountNumber,
    double initialBalance = 0,
  }) {
    if (_currentStatement == null) return;
    _accountToCreate = Account(
      id: '',
      userId: '',
      name: accountName,
      type: accountType,
      balance: initialBalance,
      currency: '₹',
      bankName: bankName,
      accountNumber: accountNumber,
      color: accountColor,
      iconCodePoint: accountIcon.codePoint,
      iconFontFamily: accountIcon.fontFamily ?? 'MaterialIcons',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _selectedAccount = null;
    _status = 'New account configured: $accountName';
    notifyListeners();
  }

  void reset() {
    _currentStatement = null;
    _lastParseResult = null;
    _duplicateResults = null;
    _selectedAccount = null;
    _accountToCreate = null;
    _isLoading = false;
    _status = '';
    _showPasswordInput = false;
    _currentPassword = '';
    notifyListeners();
  }

  Future<void> _confirmImport(
    BuildContext context,
    PDFImportProvider provider,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing...'),
          ],
        ),
      ),
    );

    try {
      final accountProvider = context.read<AccountProvider>();
      final transactionProvider = context.read<TransactionProvider>();
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      String accountId;
      if (provider.accountToCreate != null) {
        await accountProvider.addAccount(provider.accountToCreate!);
        final newAccount = accountProvider.accounts.firstWhere(
          (acc) => acc.name == provider.accountToCreate!.name,
        );
        accountId = newAccount.id;
      } else if (provider.selectedAccount != null) {
        accountId = provider.selectedAccount!.id;
      } else {
        throw Exception('No account selected');
      }

      int importedCount = 0;
      int skippedCount = 0;
      int updatedCount = 0;
      final now = DateTime.now();

      for (final entry in provider.duplicateResults!.entries) {
        final pdfTransaction = entry.key;
        final duplicateCheck = entry.value;

        // --- FAILSAFE TYPE CHECK ---
        bool isExpense =
            pdfTransaction.type.toLowerCase() == 'debit' ||
            pdfTransaction.type.toLowerCase() == 'expense';
        // Failsafe: if parser missed it, check description manually
        if (pdfTransaction.description.toUpperCase().contains('UPIOUT')) {
          isExpense = true;
        }

        final correctType = isExpense
            ? TransactionType.expense
            : TransactionType.income;

        if (duplicateCheck.isDuplicate) {
          if (duplicateCheck.needsTypeUpdate &&
              duplicateCheck.matchingTransactionId != null) {
            final existingTransaction = transactionProvider.transactions
                .firstWhere(
                  (t) => t.id == duplicateCheck.matchingTransactionId,
                );

            final updatedTransaction = Transaction(
              id: existingTransaction.id,
              userId: existingTransaction.userId,
              type: correctType, // Use Failsafe Type
              amount: existingTransaction.amount,
              description: existingTransaction.description,
              categoryId: existingTransaction.categoryId,
              accountId: existingTransaction.accountId,
              date: existingTransaction.date,
              metadata: existingTransaction.metadata,
              attachments: existingTransaction.attachments,
              createdAt: existingTransaction.createdAt,
              updatedAt: now,
            );

            await transactionProvider.updateTransaction(
              updatedTransaction,
              existingTransaction,
            );
            updatedCount++;
          } else {
            skippedCount++;
          }
          continue;
        }

        final transaction = Transaction(
          id: '',
          userId: currentUser.uid,
          type: correctType, // Use Failsafe Type
          amount: pdfTransaction.amount,
          description: pdfTransaction.description,
          categoryId: null,
          accountId: accountId,
          date: DateTime.tryParse(pdfTransaction.date) ?? now,
          metadata: {'importedFromPDF': true, 'pdfSource': 'bank_statement'},
          attachments: null,
          createdAt: now,
          updatedAt: now,
        );

        await transactionProvider.addTransaction(transaction);
        importedCount++;
      }

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Import complete: $importedCount added, $updatedCount updated, $skippedCount skipped.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        provider.reset();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static const List<String> supportedBanks = [
    'SBI',
    'HDFC',
    'ICICI',
    'AXIS',
    'KOTAK',
    'BOI',
    'PNB',
    'IDBI',
    'INDUSIND',
    'YES BANK',
    'FEDERAL',
    'FI MONEY',
    'OTHER',
  ];
}
