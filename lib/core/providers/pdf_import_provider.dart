import 'package:flutter/material.dart';
import '../models/pdf_statement.dart';
import '../models/account.dart';
import '../models/pdf_parsing_provider.dart';
import '../services/pdf_parsing_service.dart';
import '../services/pdf_password_manager.dart';

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
    if (_duplicateResults == null) {
      return _currentStatement?.transactionCount ?? 0;
    }
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

  /// Set the Gemini API key for PDF parsing
  /// Call this after AI assistant provider is initialized with a key
  void setGeminiApiKeyForPDF(String apiKey) {
    _parsingService.setGeminiApiKey(apiKey);
  }

  /// Set the Claude API key for PDF parsing
  void setClaudeApiKeyForPDF(String apiKey) {
    _parsingService.setClaudeApiKey(apiKey);
  }

  /// Set which provider to use for PDF parsing (Gemini or Claude)
  void setPDFParsingProvider(PDFParsingProvider provider) {
    _parsingService.setPDFParsingProvider(provider);
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
        final s = result.statement!;
        _status =
            'PDF parsed successfully. '
            '${s.transactionCount} transactions found. '
            'Income: ${s.incomeCount}, Expenses: ${s.expenseCount}.';
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
