// ignore_for_file: file_names
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// AIConfig and cloud providers removed — using local Gemma only
import '../../../core/models/pdf_parsing_provider.dart';
import '../models/Nex_message.dart';
import '../models/Nex_conversation.dart';
import '../models/Nex_settings.dart';
import '../services/Nex_service.dart';
import '../services/Nex_system_prompt.dart';
import '../services/context_builder_service.dart';

// Import your context providers
import '../../../core/providers/account_provider.dart';
import '../../../core/providers/debt_provider.dart';
import '../../../core/providers/investment_provider.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/providers/transaction_provider.dart';
import '../../../core/providers/budget_provider.dart';
import '../../../core/providers/goal_provider.dart';
import '../../../core/providers/bike_provider.dart';
import '../../../core/providers/new_nbox_provider.dart';
import '../../../core/providers/pdf_import_provider.dart';
import '../../../core/providers/shared_expense_provider.dart';
import '../../../core/providers/category_provider.dart';

class AIAssistantProvider with ChangeNotifier {
  // Storage keys
  static const _settingsKey = 'ai_settings';
  static const _conversationsKey = 'ai_conversations';

  // State
  AISettings _settings = AISettings();
  List<AIConversation> _conversations = [];
  AIConversation? _currentConversation;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  // Context providers
  AccountProvider? _accountProvider;
  DebtProvider? _debtProvider;
  InvestmentProvider? _investmentProvider;
  SubscriptionProvider? _subscriptionProvider;
  TransactionProvider? _transactionProvider;
  BudgetProvider? _budgetProvider;
  GoalProvider? _goalProvider;
  BikeProvider? _bikeProvider;
  NewNboxProvider? _nboxProvider;
  PDFImportProvider? _pdfImportProvider;
  SharedExpenseProvider? _sharedExpenseProvider;
  CategoryProvider? _categoryProvider;

  BaseAIService? _aiService;

  // Getters
  AISettings get settings => _settings;
  List<AIConversation> get conversations => _conversations;
  AIConversation? get currentConversation => _currentConversation;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  // Ready if local AI service is initialized
  bool get isReady => _aiService != null;

  // --- INITIALIZATION ---

  Future<void> initialize() async {
    if (_isInitialized) { return; }
    await _loadSettings();
    await _loadConversations();
    await _initService();

    // Propagate PDF parsing provider setting
    if (_pdfImportProvider != null) {
      _pdfImportProvider!.setPDFParsingProvider(_settings.pdfParsingProvider);
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _initService() async {
    // Always initialize the local Gemma AI service.
    try {
      _aiService = GemmaLocalAIService();
      debugPrint('[AIAssistantProvider] Using local Gemma service');
    } catch (e) {
      _aiService = null;
      debugPrint('[AIAssistantProvider] Failed to initialize local Gemma: $e');
    }
  }

  Future<void> setGeminiMode(GeminiMode mode) async {
    _settings = _settings.copyWith(geminiMode: mode);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setPDFParsingProvider(PDFParsingProvider provider) async {
    _settings = _settings.copyWith(pdfParsingProvider: provider);
    await _saveSettings();

    if (_pdfImportProvider != null) {
      _pdfImportProvider!.setPDFParsingProvider(provider);
    }
    notifyListeners();
  }

  // --- CONTEXT INJECTION ---

  void setContextProviders({
    required AccountProvider accountProvider,
    required DebtProvider debtProvider,
    required InvestmentProvider investmentProvider,
    required SubscriptionProvider subscriptionProvider,
    required TransactionProvider transactionProvider,
    BudgetProvider? budgetProvider,
    GoalProvider? goalProvider,
    BikeProvider? bikeProvider,
    NewNboxProvider? nboxProvider,
    PDFImportProvider? pdfImportProvider,
    SharedExpenseProvider? sharedExpenseProvider,
    CategoryProvider? categoryProvider,
  }) {
    _accountProvider = accountProvider;
    _debtProvider = debtProvider;
    _investmentProvider = investmentProvider;
    _subscriptionProvider = subscriptionProvider;
    _transactionProvider = transactionProvider;
    _budgetProvider = budgetProvider;
    _goalProvider = goalProvider;
    _bikeProvider = bikeProvider;
    _nboxProvider = nboxProvider;
    _pdfImportProvider = pdfImportProvider;
    _sharedExpenseProvider = sharedExpenseProvider;
    _categoryProvider = categoryProvider;
  }

  // --- API KEY MANAGEMENT (Kept for PDF backups) ---

  Future<void> setGeminiApiKey(String apiKey) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Store the key locally (kept for backward compatibility with PDF import).
      _settings = _settings.copyWith(
        geminiApiKey: apiKey,
        activeModel: AIModel.gemma,
      );
      await _saveSettings();
      await _initService();

      if (_pdfImportProvider != null) {
        _pdfImportProvider!.setGeminiApiKeyForPDF(apiKey);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setClaudeApiKey(String apiKey) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Store the key locally for PDF-import compatibility only.
      _settings = _settings.copyWith(claudeApiKey: apiKey);
      await _saveSettings();
      await _initService();

      // Claude API key support has been removed - using Gemini only
      // if (_pdfImportProvider != null) {
      //   _pdfImportProvider!.setClaudeApiKeyForPDF(apiKey);
      // }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send a raw prompt and return the response string directly.
  Future<String> sendRawPrompt(String prompt) async {
    if (_aiService == null) {
      throw Exception('AI service not configured');
    }
    return await _aiService!.sendMessage(
      prompt,
      'You are a helpful assistant.',
      [],
      task: AITask.chat,
    );
  }

  // --- MESSAGING & ROUTING ---

  Future<void> sendMessage(String message) async {
    // 🔥 UPDATED: Removed the hasAnyKey check since local models don't need it!

    if (_currentConversation == null) { startNewConversation(); }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Add User Message
      _currentConversation = _currentConversation!.addMessage(
        AIMessage.user(message),
      );
      notifyListeners();

      // 2. Build Context
      final context = _buildContext(message);
      final systemPrompt = AISystemPrompt.buildSystemPrompt(
        financialContext: context,
      );

      // 3. Send via GemmaLocalAIService
      final response = await _aiService!.sendMessage(
        message,
        systemPrompt,
        _currentConversation!.messages,
        task: AITask.chat, // Gemma is fast local, so just use chat
      );

      // 4. Add Response
      _currentConversation = _currentConversation!.addMessage(
        AIMessage.assistant(response),
      );

      // Update Title if new
      if (_currentConversation!.messages.length == 2) {
        final title = message.length > 30
            ? '${message.substring(0, 30)}...'
            : message;
        _currentConversation = _currentConversation!.copyWith(title: title);
      }

      await _saveConversations();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _currentConversation = _currentConversation!.addMessage(
        AIMessage.error(_error!),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cancel any ongoing AI generation (e.g., user navigated away from chat)
  void cancelOngoingChat() {
    try {
      if (_aiService is GemmaLocalAIService) {
        (_aiService as GemmaLocalAIService).cancel();
        debugPrint('[AIAssistantProvider] Cancelled ongoing Gemma generation');
      }
    } catch (e) {
      debugPrint('[AIAssistantProvider] Failed to cancel generation: $e');
    }
  }

  // --- PDF PARSING (Using Cloud for precision if needed) ---
  Future<String> parseBankStatement(String pdfText) async {
    if (_aiService == null) { throw Exception('AI not initialized'); }

    const systemPrompt =
        "You are a specialized data extraction AI. Extract the transaction data from this bank statement text into strict JSON format with fields: date, description, amount, type. Return ONLY JSON.";

    return await _aiService!.sendMessage(
      pdfText,
      systemPrompt,
      [],
      task: AITask.precision,
    );
  }

  // --- HELPERS ---

  void startNewConversation() {
    _currentConversation = AIConversation.create();
    _conversations.insert(0, _currentConversation!);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _buildContext(String query) {
    if (_accountProvider == null) { return "Data loading..."; }
    return ContextBuilderService(
      accountProvider: _accountProvider!,
      debtProvider: _debtProvider!,
      investmentProvider: _investmentProvider!,
      subscriptionProvider: _subscriptionProvider!,
      transactionProvider: _transactionProvider!,
      budgetProvider: _budgetProvider,
      goalProvider: _goalProvider,
      bikeProvider: _bikeProvider,
      nboxProvider: _nboxProvider,
      pdfImportProvider: _pdfImportProvider,
      sharedExpenseProvider: _sharedExpenseProvider,
      categoryProvider: _categoryProvider,
    ).buildSmartContext(query);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_settingsKey);
    if (json != null) {
      try {
        _settings = AISettings.fromJson(jsonDecode(json));
      } catch (e) {
        _settings = AISettings();
      }
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(_settings.toJson()));
  }

  Future<void> _loadConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_conversationsKey);
    if (jsonStr != null) {
      final List list = jsonDecode(jsonStr);
      _conversations = list.map((e) => AIConversation.fromJson(e)).toList();
      if (_conversations.isNotEmpty) {
        _currentConversation = _conversations.first;
      }
    }
  }

  Future<void> _saveConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_conversations.map((c) => c.toJson()).toList());
    await prefs.setString(_conversationsKey, jsonStr);
  }
}
