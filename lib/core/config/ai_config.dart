/// Centralized AI Configuration (local-only)
/// This app now uses only the local Gemma model; cloud Gemini/Claude support
/// has been removed. Backward-compatible methods remain but are no-ops.
class AIConfig {
  // Local-only placeholder model identifiers
  static const String gemmaLocal = 'gemma-local';

  // API key getters/setters are no-ops and return null so code paths that
  // previously checked for cloud API keys will find none.
  static Future<String?> getGeminiApiKey() async => null;
  static Future<void> setGeminiApiKey(String _) async {}
  static Future<String?> getClaudeApiKey() async => null;
  static Future<void> setClaudeApiKey(String _) async {}

  static Future<AIProvider> getProvider() async => AIProvider.gemma;
  static Future<void> setProvider(AIProvider _) async {}

  static String getPrimaryModelFor(AITaskType task) => gemmaLocal;
  static List<String> getModelChain(
    AITaskType task, {
    AIProvider? providerOverride,
  }) => [gemmaLocal];
}

enum AIProvider { gemma, gemini, claude }

enum AITaskType { chat, reasoning, precision }
