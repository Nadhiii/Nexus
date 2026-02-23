/// AI Settings Model
/// Stores user's AI preferences and API keys
library;

import '../../../core/models/pdf_parsing_provider.dart';

enum AIModel { gemma, gemini, claude }

enum GeminiMode { auto, fast, thinking, pro }

class AISettings {
  final String? geminiApiKey;
  final String? claudeApiKey;
  final AIModel activeModel;
  final GeminiMode geminiMode;
  final PDFParsingProvider pdfParsingProvider;
  final bool enableProactiveInsights;
  final String assistantName;

  AISettings({
    this.geminiApiKey,
    this.claudeApiKey,
    this.activeModel = AIModel.gemma,
    this.geminiMode = GeminiMode.auto,
    this.pdfParsingProvider = PDFParsingProvider.gemini,
    this.enableProactiveInsights = true,
    this.assistantName = 'Nex',
  });

  bool get hasGeminiKey => geminiApiKey != null && geminiApiKey!.isNotEmpty;
  bool get hasClaudeKey => claudeApiKey != null && claudeApiKey!.isNotEmpty;
  bool get hasAnyKey => hasGeminiKey || hasClaudeKey;

  bool get canUseActiveModel {
    switch (activeModel) {
      case AIModel.gemma:
        return true;
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
    return AIModel.gemma; // default to local Gemma
  }

  AISettings copyWith({
    String? geminiApiKey,
    String? claudeApiKey,
    AIModel? activeModel,
    GeminiMode? geminiMode,
    PDFParsingProvider? pdfParsingProvider,
    bool? enableProactiveInsights,
    String? assistantName,
  }) {
    return AISettings(
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      claudeApiKey: claudeApiKey ?? this.claudeApiKey,
      activeModel: activeModel ?? this.activeModel,
      geminiMode: geminiMode ?? this.geminiMode,
      pdfParsingProvider: pdfParsingProvider ?? this.pdfParsingProvider,
      enableProactiveInsights:
          enableProactiveInsights ?? this.enableProactiveInsights,
      assistantName: assistantName ?? this.assistantName,
    );
  }

  Map<String, dynamic> toJson() => {
    'geminiApiKey': geminiApiKey,
    'claudeApiKey': claudeApiKey,
    'activeModel': activeModel.name,
    'geminiMode': geminiMode.name,
    'pdfParsingProvider': pdfParsingProvider.name,
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
      geminiMode: GeminiMode.values.firstWhere(
        (e) => e.name == json['geminiMode'],
        orElse: () => GeminiMode.auto,
      ),
      pdfParsingProvider: PDFParsingProvider.values.firstWhere(
        (e) => e.name == json['pdfParsingProvider'],
        orElse: () => PDFParsingProvider.gemini,
      ),
      enableProactiveInsights: json['enableProactiveInsights'] as bool? ?? true,
      assistantName: json['assistantName'] as String? ?? 'Nex',
    );
  }
}
