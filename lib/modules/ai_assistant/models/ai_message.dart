/// AI Assistant Message Model
/// Represents a single message in the conversation
library;

enum MessageRole { user, assistant, system }

class AIMessage {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final bool isError;
  final Map<String, dynamic>?
  metadata; // For storing context used, tokens, etc.

  AIMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isError = false,
    this.metadata,
  });

  factory AIMessage.user(String content) {
    return AIMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: content,
      timestamp: DateTime.now(),
    );
  }

  factory AIMessage.assistant(
    String content, {
    Map<String, dynamic>? metadata,
  }) {
    return AIMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.assistant,
      content: content,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
  }

  factory AIMessage.error(String errorMessage) {
    return AIMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.assistant,
      content: errorMessage,
      timestamp: DateTime.now(),
      isError: true,
    );
  }

  factory AIMessage.system(String content) {
    return AIMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.system,
      content: content,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role.name,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'isError': isError,
    'metadata': metadata,
  };

  factory AIMessage.fromJson(Map<String, dynamic> json) {
    return AIMessage(
      id: json['id'] as String,
      role: MessageRole.values.firstWhere((e) => e.name == json['role']),
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isError: json['isError'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}
