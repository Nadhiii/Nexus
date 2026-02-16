import 'package:shared_preferences/shared_preferences.dart';

/// Centralized AI Configuration
/// Single source of truth for API keys, model names, and fallback chains.
class AIConfig {
  // ==================== STORAGE KEYS ====================
  static const String _geminiApiKeyPrimary = 'gemini_api_key_primary';
  static const String _geminiApiKeyFallback = 'gemini_api_key_fallback';
  static const String _claudeApiKeyKey = 'claude_api_key';
  static const String _activeProviderKey = 'ai_provider_preference';

  // ==================== GEMINI MODEL IDS ====================
  //
  static const String gemini3FlashPreview = 'gemini-3-flash-preview';
  static const String gemini3ProPreview = 'gemini-3-pro-preview';
  static const String gemini2Flash = 'gemini-2.0-flash-exp';
  static const String gemini2Thinking = 'gemini-2.0-flash-thinking-exp';
  static const String gemini15Pro = 'gemini-1.5-pro-latest';
  static const String gemini15Flash = 'gemini-1.5-flash-latest';

  // ==================== CLAUDE MODEL IDS ====================
  //
  /// Best Balance (Intelligence/Speed)
  static const String claude35Sonnet = 'claude-3-5-sonnet-latest';

  /// Fastest / Cheapest
  static const String claude35Haiku = 'claude-3-5-haiku-latest';

  /// Highest Intelligence (Legacy Opus is deprecated in 2026)
  /// Use Sonnet 3.5 or Opus 3.5/4 if available in your key's tier
  static const String claude3Opus = 'claude-3-opus-latest';

  // ==================== TASK ROUTING (GEMINI) ====================

  static const List<String> _geminiChat = [
    gemini2Flash,
    gemini3FlashPreview,
    gemini15Flash,
  ];
  static const List<String> _geminiReasoning = [
    gemini2Thinking,
    gemini3ProPreview,
    gemini15Pro,
  ];
  static const List<String> _geminiPrecision = [
    gemini15Pro,
    gemini2Flash,
    gemini3ProPreview,
  ];

  // Public accessors for backward compatibility
  static List<String> get chatModels => _geminiChat;
  static List<String> get reasoningModels => _geminiReasoning;
  static List<String> get precisionModels => _geminiPrecision;

  // Public accessors for Claude models
  static List<String> get claudeChatModels => _claudeChat;
  static List<String> get claudeReasoningModels => _claudeReasoning;
  static List<String> get claudePrecisionModels => _claudePrecision;

  // ==================== TASK ROUTING (CLAUDE) ====================

  static const List<String> _claudeChat = [claude35Haiku, claude35Sonnet];
  static const List<String> _claudeReasoning = [claude35Sonnet, claude3Opus];
  static const List<String> _claudePrecision = [
    claude35Sonnet, claude3Opus, // Sonnet 3.5 is excellent for PDFs
  ];

  // ==================== API KEY MANAGEMENT ====================

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<String?> getGeminiApiKey() async {
    await init();
    return _prefs?.getString(_geminiApiKeyPrimary) ??
        _prefs?.getString(_geminiApiKeyFallback);
  }

  static Future<void> setGeminiApiKey(String key) async {
    await init();
    await _prefs?.setString(_geminiApiKeyPrimary, key);
  }

  static Future<String?> getClaudeApiKey() async {
    await init();
    return _prefs?.getString(_claudeApiKeyKey);
  }

  static Future<void> setClaudeApiKey(String key) async {
    await init();
    await _prefs?.setString(_claudeApiKeyKey, key);
  }

  /// Get the user's preferred AI provider (default: Gemini)
  static Future<AIProvider> getProvider() async {
    await init();
    final saved = _prefs?.getString(_activeProviderKey);
    return saved == 'claude' ? AIProvider.claude : AIProvider.gemini;
  }

  /// Set the preferred AI provider
  static Future<void> setProvider(AIProvider provider) async {
    await init();
    await _prefs?.setString(_activeProviderKey, provider.name);
  }

  // ==================== MODEL SELECTION ====================

  /// Get the primary model for a specific task type (Gemini only)
  static String getPrimaryModelFor(AITaskType task) {
    switch (task) {
      case AITaskType.chat:
        return _geminiChat.first;
      case AITaskType.reasoning:
        return _geminiReasoning.first;
      case AITaskType.precision:
        return _geminiPrecision.first;
    }
  }

  /// Get the chain of models to try for a specific task
  static List<String> getModelChain(
    AITaskType task, {
    AIProvider? providerOverride,
  }) {
    // If no override, we could default to Gemini,
    // BUT usually you pass the active provider from your UI/State.
    final provider = providerOverride ?? AIProvider.gemini;

    if (provider == AIProvider.claude) {
      switch (task) {
        case AITaskType.chat:
          return _claudeChat;
        case AITaskType.reasoning:
          return _claudeReasoning;
        case AITaskType.precision:
          return _claudePrecision;
      }
    } else {
      switch (task) {
        case AITaskType.chat:
          return _geminiChat;
        case AITaskType.reasoning:
          return _geminiReasoning;
        case AITaskType.precision:
          return _geminiPrecision;
      }
    }
  }
}

enum AIProvider { gemini, claude }

enum AITaskType { chat, reasoning, precision }
