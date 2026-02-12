/// AI Settings Model
/// Stores user's AI preferences and API keys

enum AIModel { gemini, claude }

class AISettings {
  final String? geminiApiKey;
  final String? claudeApiKey;
  final AIModel activeModel;
  final bool enableProactiveInsights;
  final String assistantName;

  AISettings({
    this.geminiApiKey,
    this.claudeApiKey,
    this.activeModel = AIModel.gemini,
    this.enableProactiveInsights = true,
    this.assistantName = 'Nex',
  });

  bool get hasGeminiKey => geminiApiKey != null && geminiApiKey!.isNotEmpty;
  bool get hasClaudeKey => claudeApiKey != null && claudeApiKey!.isNotEmpty;
  bool get hasAnyKey => hasGeminiKey || hasClaudeKey;

  bool get canUseActiveModel {
    switch (activeModel) {
      case AIModel.gemini:
        return hasGeminiKey;
      case AIModel.claude:
        return hasClaudeKey;
    }
  }

  /// Get the best available model
  AIModel? get bestAvailableModel {
    if (hasClaudeKey) return AIModel.claude; // Prefer Claude when available
    if (hasGeminiKey) return AIModel.gemini;
    return null;
  }

  AISettings copyWith({
    String? geminiApiKey,
    String? claudeApiKey,
    AIModel? activeModel,
    bool? enableProactiveInsights,
    String? assistantName,
  }) {
    return AISettings(
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      claudeApiKey: claudeApiKey ?? this.claudeApiKey,
      activeModel: activeModel ?? this.activeModel,
      enableProactiveInsights:
          enableProactiveInsights ?? this.enableProactiveInsights,
      assistantName: assistantName ?? this.assistantName,
    );
  }

  Map<String, dynamic> toJson() => {
    'geminiApiKey': geminiApiKey,
    'claudeApiKey': claudeApiKey,
    'activeModel': activeModel.name,
    'enableProactiveInsights': enableProactiveInsights,
    'assistantName': assistantName,
  };

  factory AISettings.fromJson(Map<String, dynamic> json) {
    return AISettings(
      geminiApiKey: json['geminiApiKey'] as String?,
      claudeApiKey: json['claudeApiKey'] as String?,
      activeModel: AIModel.values.firstWhere(
        (e) => e.name == json['activeModel'],
        orElse: () => AIModel.gemini,
      ),
      enableProactiveInsights: json['enableProactiveInsights'] as bool? ?? true,
      assistantName: json['assistantName'] as String? ?? 'Nex',
    );
  }
}
