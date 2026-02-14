import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_message.dart';
import '../models/ai_conversation.dart';
import '../models/ai_settings.dart';
import '../services/ai_service.dart';
import '../services/ai_system_prompt.dart';
import '../services/context_builder_service.dart';
import '../services/no_key_responses.dart';

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

/// AI Assistant Provider
/// Manages AI state, conversations, and API interactions
class AIAssistantProvider with ChangeNotifier {
  // Storage keys
  static const _settingsKey = 'ai_settings';
  static const _conversationsKey = 'ai_conversations';
  static const _geminiKeyKey = 'gemini_api_key';
  static const _claudeKeyKey = 'claude_api_key';
  static const _usageKey = 'ai_usage_stats';
  static const _noKeyAttemptsKey = 'ai_no_key_attempts';

  // Secure storage for API keys (lazy initialized for safety)
  FlutterSecureStorage? _secureStorage;
  bool _secureStorageAvailable = true;

  /// Get secure storage instance with fallback for compatibility
  FlutterSecureStorage? _getSecureStorage() {
    if (_secureStorage != null) return _secureStorage;
    if (!_secureStorageAvailable) return null;

    try {
      // Basic secure storage without platform-specific options to avoid crashes
      _secureStorage = const FlutterSecureStorage();
      debugPrint('FlutterSecureStorage: Initialized successfully');
      return _secureStorage;
    } catch (e) {
      debugPrint('FlutterSecureStorage: Failed to initialize: $e');
      _secureStorageAvailable = false;
      return null;
    }
  }

  // State
  AISettings _settings = AISettings();
  List<AIConversation> _conversations = [];
  AIConversation? _currentConversation;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  // Usage tracking
  int _messagesSentThisMonth = 0;
  int _estimatedTokensUsed = 0;
  DateTime? _usageResetDate;

  // No-key attempt tracking
  int _noKeyAttemptCount = 0;

  // Context providers (set via dependency injection)
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

  // Current AI service
  BaseAIService? _aiService;

  // Getters
  AISettings get settings => _settings;
  List<AIConversation> get conversations => _conversations;
  AIConversation? get currentConversation => _currentConversation;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get isReady => _settings.hasAnyKey && _settings.canUseActiveModel;

  // Usage getters
  int get messagesSentThisMonth => _messagesSentThisMonth;
  int get estimatedTokensUsed => _estimatedTokensUsed;
  int get noKeyAttemptCount => _noKeyAttemptCount;

  /// Estimated percentage of Gemini free tier used (rough estimate)
  /// Gemini has ~1.5M tokens/month free, we estimate ~500 tokens per message
  double get estimatedFreeUsagePercent {
    const freeLimit = 1500000; // 1.5M tokens
    return (_estimatedTokensUsed / freeLimit * 100).clamp(0, 100);
  }

  /// Human-readable usage summary
  String get usageSummary {
    if (_messagesSentThisMonth == 0) return 'No messages this month';
    return '$_messagesSentThisMonth messages (~${(_estimatedTokensUsed / 1000).toStringAsFixed(1)}K tokens)';
  }

  /// Initialize the provider
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('AIAssistantProvider: Starting initialization...');

    try {
      await _loadSettings();
      debugPrint('AIAssistantProvider: Settings loaded');
    } catch (e) {
      debugPrint('AIAssistantProvider: Error loading settings: $e');
    }

    try {
      await _loadConversations();
      debugPrint('AIAssistantProvider: Conversations loaded');
    } catch (e) {
      debugPrint('AIAssistantProvider: Error loading conversations: $e');
    }

    try {
      await _loadUsageStats();
      debugPrint('AIAssistantProvider: Usage stats loaded');
    } catch (e) {
      debugPrint('AIAssistantProvider: Error loading usage stats: $e');
    }

    try {
      _initializeAIService();
      debugPrint('AIAssistantProvider: AI service initialized');
    } catch (e) {
      debugPrint('AIAssistantProvider: Error initializing AI service: $e');
    }

    _isInitialized = true;
    debugPrint('AIAssistantProvider: Initialization complete');
    notifyListeners();
  }

  /// Set context providers for financial data access
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
    debugPrint('AIAssistantProvider: Setting context providers');
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
    debugPrint('AIAssistantProvider: Context providers set successfully');
  }

  /// Load settings from storage
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);

      if (settingsJson != null) {
        try {
          _settings = AISettings.fromJson(jsonDecode(settingsJson));
        } catch (e) {
          debugPrint('Error parsing AI settings: $e');
          _settings = AISettings();
        }
      }

      // Load API keys from secure storage (with error handling)
      String? geminiKey;
      String? claudeKey;

      final storage = _getSecureStorage();
      if (storage != null) {
        try {
          geminiKey = await storage.read(key: _geminiKeyKey);
        } catch (e) {
          debugPrint('Error reading Gemini key from secure storage: $e');
        }

        try {
          claudeKey = await storage.read(key: _claudeKeyKey);
        } catch (e) {
          debugPrint('Error reading Claude key from secure storage: $e');
        }
      } else {
        debugPrint('Secure storage not available, API keys will not persist');
      }

      _settings = _settings.copyWith(
        geminiApiKey: geminiKey,
        claudeApiKey: claudeKey,
      );
    } catch (e) {
      debugPrint('Error in _loadSettings: $e');
      rethrow;
    }
  }

  /// Save settings to storage
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save non-sensitive settings
      final settingsToSave = AISettings(
        activeModel: _settings.activeModel,
        enableProactiveInsights: _settings.enableProactiveInsights,
        assistantName: _settings.assistantName,
      );
      await prefs.setString(_settingsKey, jsonEncode(settingsToSave.toJson()));

      // Save API keys to secure storage
      final storage = _getSecureStorage();
      if (storage != null) {
        try {
          if (_settings.geminiApiKey != null) {
            await storage.write(
              key: _geminiKeyKey,
              value: _settings.geminiApiKey,
            );
          }
          if (_settings.claudeApiKey != null) {
            await storage.write(
              key: _claudeKeyKey,
              value: _settings.claudeApiKey,
            );
          }
        } catch (e) {
          debugPrint('Error writing to secure storage: $e');
        }
      }
    } catch (e) {
      debugPrint('Error in _saveSettings: $e');
    }
  }

  /// Load conversations from storage
  Future<void> _loadConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conversationsJson = prefs.getString(_conversationsKey);

      if (conversationsJson != null) {
        final List<dynamic> list = jsonDecode(conversationsJson);
        _conversations = list
            .map((json) => AIConversation.fromJson(json))
            .toList();

        // Set current conversation to most recent
        if (_conversations.isNotEmpty) {
          _currentConversation = _conversations.first;
        }
      }
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      _conversations = [];
    }
  }

  /// Save conversations to storage
  Future<void> _saveConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conversationsJson = jsonEncode(
        _conversations.map((c) => c.toJson()).toList(),
      );
      await prefs.setString(_conversationsKey, conversationsJson);
    } catch (e) {
      debugPrint('Error saving conversations: $e');
    }
  }

  /// Load usage statistics
  Future<void> _loadUsageStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _messagesSentThisMonth = prefs.getInt('${_usageKey}_messages') ?? 0;
      _estimatedTokensUsed = prefs.getInt('${_usageKey}_tokens') ?? 0;
      final resetDateStr = prefs.getString('${_usageKey}_reset');
      if (resetDateStr != null) {
        _usageResetDate = DateTime.parse(resetDateStr);
      }

      // Load no-key attempt count
      _noKeyAttemptCount = prefs.getInt(_noKeyAttemptsKey) ?? 0;

      // Reset stats if new month
      final now = DateTime.now();
      if (_usageResetDate == null ||
          now.month != _usageResetDate!.month ||
          now.year != _usageResetDate!.year) {
        _messagesSentThisMonth = 0;
        _estimatedTokensUsed = 0;
        _usageResetDate = now;
        await _saveUsageStats();
      }
    } catch (e) {
      debugPrint('Error loading usage stats: $e');
    }
  }

  /// Save usage statistics
  Future<void> _saveUsageStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('${_usageKey}_messages', _messagesSentThisMonth);
      await prefs.setInt('${_usageKey}_tokens', _estimatedTokensUsed);
      if (_usageResetDate != null) {
        await prefs.setString(
          '${_usageKey}_reset',
          _usageResetDate!.toIso8601String(),
        );
      }
    } catch (e) {
      debugPrint('Error saving usage stats: $e');
    }
  }

  /// Increment no-key attempt counter
  Future<void> _incrementNoKeyAttempts() async {
    try {
      _noKeyAttemptCount++;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_noKeyAttemptsKey, _noKeyAttemptCount);
    } catch (e) {
      debugPrint('Error incrementing no-key attempts: $e');
    }
  }

  /// Track usage for a message exchange
  void _trackUsage(String userMessage, String aiResponse) {
    _messagesSentThisMonth++;
    // Rough estimate: ~500 tokens per exchange
    final estimatedTokens = (userMessage.length + aiResponse.length) ~/ 2;
    _estimatedTokensUsed += estimatedTokens;
    _saveUsageStats();
  }

  /// Initialize AI service based on settings
  void _initializeAIService() {
    if (_settings.activeModel == AIModel.gemini && _settings.hasGeminiKey) {
      _aiService = GeminiAIService(apiKey: _settings.geminiApiKey!);
    } else if (_settings.activeModel == AIModel.claude &&
        _settings.hasClaudeKey) {
      _aiService = ClaudeAIService(apiKey: _settings.claudeApiKey!);
    } else {
      _aiService = null;
    }
  }

  /// Set Gemini API key
  Future<bool> setGeminiApiKey(String apiKey) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Validate key
      final service = GeminiAIService(apiKey: apiKey);
      final isValid = await service.validateApiKey(apiKey);

      if (!isValid) {
        throw Exception('Invalid API key');
      }

      // Save key
      _settings = _settings.copyWith(geminiApiKey: apiKey);
      await _saveSettings();

      // Switch to Gemini if not configured
      if (!_settings.canUseActiveModel) {
        _settings = _settings.copyWith(activeModel: AIModel.gemini);
        await _saveSettings();
      }

      _initializeAIService();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to validate API key: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Set Claude API key
  Future<bool> setClaudeApiKey(String apiKey) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Validate key
      final service = ClaudeAIService(apiKey: apiKey);
      final isValid = await service.validateApiKey(apiKey);

      if (!isValid) {
        throw Exception('Invalid API key');
      }

      // Save key
      _settings = _settings.copyWith(claudeApiKey: apiKey);
      await _saveSettings();

      // Switch to Claude automatically if it's the best available
      if (_settings.bestAvailableModel == AIModel.claude) {
        _settings = _settings.copyWith(activeModel: AIModel.claude);
        await _saveSettings();
      }

      _initializeAIService();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to validate API key: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Switch active AI model
  Future<void> switchModel(AIModel model) async {
    if (model == AIModel.gemini && !_settings.hasGeminiKey) {
      _error = 'Please add a Gemini API key first';
      notifyListeners();
      return;
    }
    if (model == AIModel.claude && !_settings.hasClaudeKey) {
      _error = 'Please add a Claude API key first';
      notifyListeners();
      return;
    }

    _settings = _settings.copyWith(activeModel: model);
    await _saveSettings();
    _initializeAIService();
    notifyListeners();
  }

  /// Start a new conversation
  void startNewConversation() {
    _currentConversation = AIConversation.create();
    _conversations.insert(0, _currentConversation!);
    _saveConversations();
    notifyListeners();
  }

  /// Select an existing conversation
  void selectConversation(String conversationId) {
    _currentConversation = _conversations.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => AIConversation.create(),
    );
    notifyListeners();
  }

  /// Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    _conversations.removeWhere((c) => c.id == conversationId);
    if (_currentConversation?.id == conversationId) {
      _currentConversation = _conversations.isNotEmpty
          ? _conversations.first
          : null;
    }
    await _saveConversations();
    notifyListeners();
  }

  /// Build financial context
  String _buildContext(String query) {
    // Check if all required providers are available
    if (_accountProvider == null ||
        _debtProvider == null ||
        _investmentProvider == null ||
        _subscriptionProvider == null ||
        _transactionProvider == null) {
      debugPrint('AIAssistantProvider: Context providers not set, returning basic context');
      return 'Financial data is still loading. Please try again in a moment.';
    }

    try {
      final contextBuilder = ContextBuilderService(
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
      );

      // Use smart context for specific queries, full context for general questions
      if (query.length > 50 || _currentConversation!.messages.isEmpty) {
        return contextBuilder.buildSmartContext(query);
      } else {
        return contextBuilder.buildFullContext(userQuery: query);
      }
    } catch (e) {
      debugPrint('AIAssistantProvider: Error building context: $e');
      return 'Error loading financial data. Please try again.';
    }
  }

  /// Send a raw prompt and return the response string directly.
  /// Used by background services (e.g. AI categorization) that need
  /// the response text without storing it in conversation history.
  Future<String> sendRawPrompt(String prompt) async {
    if (_aiService == null || !_settings.hasAnyKey) {
      throw Exception('AI service not configured');
    }
    return await _aiService!.sendMessage(
      prompt,
      'You are a helpful assistant.',
      [],
    );
  }

  /// Send a message to the AI
  Future<void> sendMessage(String message) async {
    // Handle no API key case with witty responses
    if (_aiService == null || !_settings.hasAnyKey) {
      await _handleNoKeyAttempt(message);
      return;
    }

    if (_currentConversation == null) {
      startNewConversation();
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Add user message
      final userMessage = AIMessage.user(message);
      _currentConversation = _currentConversation!.addMessage(userMessage);
      notifyListeners();

      // Build context and system prompt
      final context = _buildContext(message);
      final systemPrompt = AISystemPrompt.buildSystemPrompt(
        financialContext: context,
      );

      // Get AI response
      final response = await _aiService!.sendMessage(
        message,
        systemPrompt,
        _currentConversation!.messages,
      );

      // Track usage
      _trackUsage(message, response);

      // Add assistant response
      final assistantMessage = AIMessage.assistant(
        response,
        metadata: {'model': _aiService!.modelName},
      );
      _currentConversation = _currentConversation!.addMessage(assistantMessage);

      // Update conversation title if first exchange
      if (_currentConversation!.messages.length == 2) {
        final title = message.length > 40
            ? '${message.substring(0, 40)}...'
            : message;
        _currentConversation = _currentConversation!.copyWith(title: title);
      }

      // Save
      _updateConversationInList();
      await _saveConversations();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceAll('Exception: ', '');

      // Add error message to conversation
      final errorMessage = AIMessage.error(
        'Sorry Sir, I encountered an issue: $_error',
      );
      _currentConversation = _currentConversation!.addMessage(errorMessage);

      notifyListeners();
    }
  }

  /// Handle attempts to chat without API key
  Future<void> _handleNoKeyAttempt(String message) async {
    if (_currentConversation == null) {
      startNewConversation();
    }

    // Add user message
    final userMessage = AIMessage.user(message);
    _currentConversation = _currentConversation!.addMessage(userMessage);
    notifyListeners();

    // Get witty response based on attempt count
    final response = NoKeyResponses.getResponse(_noKeyAttemptCount);

    // Increment attempts
    await _incrementNoKeyAttempts();

    // Add the witty response
    final assistantMessage = AIMessage.assistant(
      response,
      metadata: {'model': 'Nex (offline)', 'noKey': 'true'},
    );
    _currentConversation = _currentConversation!.addMessage(assistantMessage);

    // Update conversation in list
    _updateConversationInList();
    await _saveConversations();

    notifyListeners();
  }

  /// Send a quick prompt
  Future<void> sendQuickPrompt(String promptKey) async {
    final prompt = AISystemPrompt.quickPrompts[promptKey];
    if (prompt != null) {
      await sendMessage(prompt);
    }
  }

  /// Update conversation in the list
  void _updateConversationInList() {
    if (_currentConversation == null) return;

    final index = _conversations.indexWhere(
      (c) => c.id == _currentConversation!.id,
    );
    if (index != -1) {
      _conversations[index] = _currentConversation!;
    }

    // Keep sorted by most recent
    _conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get active model name
  String get activeModelName {
    return _aiService?.modelName ?? 'Not configured';
  }
}