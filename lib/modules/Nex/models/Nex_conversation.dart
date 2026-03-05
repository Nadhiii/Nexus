// ignore_for_file: file_names
import 'Nex_message.dart';

/// AI Conversation Model
/// Represents a full conversation thread with history

class AIConversation {
  final String id;
  final String title;
  final List<AIMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  AIConversation({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AIConversation.create({String? title}) {
    final now = DateTime.now();
    return AIConversation(
      id: now.millisecondsSinceEpoch.toString(),
      title: title ?? 'New Conversation',
      messages: [],
      createdAt: now,
      updatedAt: now,
    );
  }

  AIConversation copyWith({
    String? id,
    String? title,
    List<AIMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AIConversation(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  AIConversation addMessage(AIMessage message) {
    return copyWith(
      messages: [...messages, message],
      updatedAt: DateTime.now(),
    );
  }

  /// Get conversation history formatted for AI context
  List<Map<String, String>> toApiFormat() {
    return messages
        .where((m) => m.role != MessageRole.system)
        .map(
          (m) => {
            'role': m.role == MessageRole.user ? 'user' : 'assistant',
            'content': m.content,
          },
        )
        .toList();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'messages': messages.map((m) => m.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory AIConversation.fromJson(Map<String, dynamic> json) {
    return AIConversation(
      id: json['id'] as String,
      title: json['title'] as String,
      messages: (json['messages'] as List)
          .map((m) => AIMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
