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

  // Secure storage for API keys
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

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

    try {
      await _loadSettings();
    } catch (e) {
      debugPrint('Error loading AI settings: $e');
    }

    try {
      await _loadConversations();
    } catch (e) {
      debugPrint('Error loading AI conversations: $e');
    }

    try {
      await _loadUsageStats();
    } catch (e) {
      debugPrint('Error loading AI usage stats: $e');
    }

    try {
      _initializeAIService();
    } catch (e) {
      debugPrint('Error initializing AI service: $e');
    }

    _isInitialized = true;
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
  }) {
    _accountProvider = accountProvider;
    _debtProvider = debtProvider;
    _investmentProvider = investmentProvider;
    _subscriptionProvider = subscriptionProvider;
    _transactionProvider = transactionProvider;
    _budgetProvider = budgetProvider;
    _goalProvider = goalProvider;
    _bikeProvider = bikeProvider;
  }

  /// Load settings from storage
  Future<void> _loadSettings() async {
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

    try {
      geminiKey = await _secureStorage.read(key: _geminiKeyKey);
    } catch (e) {
      debugPrint('Error reading Gemini key from secure storage: $e');
    }

    try {
      claudeKey = await _secureStorage.read(key: _claudeKeyKey);
    } catch (e) {
      debugPrint('Error reading Claude key from secure storage: $e');
    }

    _settings = _settings.copyWith(
      geminiApiKey: geminiKey,
      claudeApiKey: claudeKey,
    );
  }

  /// Save settings to storage
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Save non-sensitive settings
    final settingsToSave = AISettings(
      activeModel: _settings.activeModel,
      enableProactiveInsights: _settings.enableProactiveInsights,
      assistantName: _settings.assistantName,
    );
    await prefs.setString(_settingsKey, jsonEncode(settingsToSave.toJson()));

    // Save API keys securely (with error handling)
    try {
      if (_settings.geminiApiKey != null) {
        await _secureStorage.write(
          key: _geminiKeyKey,
          value: _settings.geminiApiKey,
        );
      } else {
        await _secureStorage.delete(key: _geminiKeyKey);
      }
    } catch (e) {
      debugPrint('Error saving Gemini key to secure storage: $e');
    }

    try {
      if (_settings.claudeApiKey != null) {
        await _secureStorage.write(
          key: _claudeKeyKey,
          value: _settings.claudeApiKey,
        );
      } else {
        await _secureStorage.delete(key: _claudeKeyKey);
      }
    } catch (e) {
      debugPrint('Error saving Claude key to secure storage: $e');
    }
  }

  /// Load usage stats from storage
  Future<void> _loadUsageStats() async {
    final prefs = await SharedPreferences.getInstance();
    final usageJson = prefs.getString(_usageKey);

    if (usageJson != null) {
      final usage = jsonDecode(usageJson) as Map<String, dynamic>;
      _messagesSentThisMonth = usage['messagesSent'] as int? ?? 0;
      _estimatedTokensUsed = usage['tokensUsed'] as int? ?? 0;
      _usageResetDate = usage['resetDate'] != null
          ? DateTime.parse(usage['resetDate'] as String)
          : null;

      // Reset if new month
      _checkAndResetMonthlyUsage();
    }

    // Load no-key attempts
    _noKeyAttemptCount = prefs.getInt(_noKeyAttemptsKey) ?? 0;
  }

  /// Save usage stats to storage
  Future<void> _saveUsageStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _usageKey,
      jsonEncode({
        'messagesSent': _messagesSentThisMonth,
        'tokensUsed': _estimatedTokensUsed,
        'resetDate': _usageResetDate?.toIso8601String(),
      }),
    );
  }

  /// Check and reset monthly usage if needed
  void _checkAndResetMonthlyUsage() {
    final now = DateTime.now();
    if (_usageResetDate == null ||
        now.month != _usageResetDate!.month ||
        now.year != _usageResetDate!.year) {
      _messagesSentThisMonth = 0;
      _estimatedTokensUsed = 0;
      _usageResetDate = DateTime(now.year, now.month, 1);
    }
  }

  /// Track message usage
  void _trackUsage(String userMessage, String aiResponse) {
    _messagesSentThisMonth++;
    // Rough token estimation: ~4 chars per token
    final estimatedTokens = ((userMessage.length + aiResponse.length) / 4)
        .round();
    _estimatedTokensUsed += estimatedTokens;
    _saveUsageStats();
  }

  /// Reset no-key attempt count (when key is added)
  Future<void> _resetNoKeyAttempts() async {
    _noKeyAttemptCount = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_noKeyAttemptsKey, 0);
  }

  /// Increment no-key attempts
  Future<void> _incrementNoKeyAttempts() async {
    _noKeyAttemptCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_noKeyAttemptsKey, _noKeyAttemptCount);
  }

  /// Load conversations from storage
  Future<void> _loadConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final conversationsJson = prefs.getString(_conversationsKey);

    if (conversationsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(conversationsJson);
        _conversations = decoded
            .map((c) => AIConversation.fromJson(c as Map<String, dynamic>))
            .toList();

        // Sort by most recent
        _conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      } catch (e) {
        debugPrint('Error parsing conversations: $e');
        _conversations = [];
      }
    }
  }

  /// Save conversations to storage
  Future<void> _saveConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_conversations.map((c) => c.toJson()).toList());
    await prefs.setString(_conversationsKey, json);
  }

  /// Initialize the AI service based on current settings
  void _initializeAIService() {
    switch (_settings.activeModel) {
      case AIModel.gemini:
        if (_settings.hasGeminiKey) {
          _aiService = GeminiAIService(apiKey: _settings.geminiApiKey!);
        }
        break;
      case AIModel.claude:
        if (_settings.hasClaudeKey) {
          _aiService = ClaudeAIService(apiKey: _settings.claudeApiKey!);
        }
        break;
    }
  }

  /// Update settings
  Future<void> updateSettings(AISettings newSettings) async {
    _settings = newSettings;
    await _saveSettings();
    _initializeAIService();
    notifyListeners();
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
        _error = 'Invalid Gemini API key';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _settings = _settings.copyWith(geminiApiKey: apiKey);
      await _saveSettings();
      _initializeAIService();

      // Reset no-key attempts since user added a key
      await _resetNoKeyAttempts();

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
        _error = 'Invalid Claude API key';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _settings = _settings.copyWith(claudeApiKey: apiKey);
      await _saveSettings();
      _initializeAIService();

      // Reset no-key attempts since user added a key
      await _resetNoKeyAttempts();

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
    if (_accountProvider == null ||
        _debtProvider == null ||
        _investmentProvider == null ||
        _subscriptionProvider == null ||
        _transactionProvider == null) {
      return 'Financial data not available.';
    }

    final contextBuilder = ContextBuilderService(
      accountProvider: _accountProvider!,
      debtProvider: _debtProvider!,
      investmentProvider: _investmentProvider!,
      subscriptionProvider: _subscriptionProvider!,
      transactionProvider: _transactionProvider!,
      budgetProvider: _budgetProvider,
      goalProvider: _goalProvider,
      bikeProvider: _bikeProvider,
    );

    // Use smart context for specific queries, full context for general questions
    if (query.length > 50 || _currentConversation!.messages.isEmpty) {
      return contextBuilder.buildSmartContext(query);
    } else {
      return contextBuilder.buildFullContext(userQuery: query);
    }
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
