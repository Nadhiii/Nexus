// ignore_for_file: file_names
import 'package:flutter_gemma/flutter_gemma.dart'; // Local Gemma import
import '../models/Nex_message.dart';
import 'package:flutter/foundation.dart';

/// Defines the type of work required.
/// This determines which Gemini 3 model is used.
enum AITask { chat, reasoning, precision }

/// Base AI Service Interface
abstract class BaseAIService {
  Future<String> sendMessage(
    String message,
    String systemPrompt,
    List<AIMessage> history, {
    AITask task = AITask.chat,
  });

  Future<bool> validateApiKey(String apiKey);
  String get modelName;
}

/// Local Gemma AI Service (single supported provider)
class GemmaLocalAIService implements BaseAIService {
  bool _cancelRequested = false;

  /// Request cancellation of any ongoing generation.
  void cancel() {
    _cancelRequested = true;
  }

  /// Reset cancel flag before starting a new request
  void _resetCancel() {
    _cancelRequested = false;
  }

  @override
  String get modelName => 'Gemma (Local)';

  @override
  Future<bool> validateApiKey(String apiKey) async {
    // Local Gemma doesn't use API keys.
    return true;
  }

  @override
  Future<String> sendMessage(
    String message,
    String systemPrompt,
    List<AIMessage> history, {
    AITask task = AITask.chat,
  }) async {
    try {
      _resetCancel();

      // Wrap model initialization with timeout to catch native crashes
      final model = await FlutterGemma.getActiveModel(maxTokens: 4096).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Model initialization timeout'),
      );

      final chat = await model.createChat();

      if (systemPrompt.isNotEmpty) {
        await chat.addQueryChunk(
          Message.text(text: "Context: $systemPrompt", isUser: true),
        );
      }

      for (final msg in history) {
        if (msg.role == MessageRole.system) { continue; }
        await chat.addQueryChunk(
          Message.text(text: msg.content, isUser: msg.role == MessageRole.user),
        );
      }

      await chat.addQueryChunk(Message.text(text: message, isUser: true));

      String fullResponse = '';

      // Wrap response generation with error handling
      try {
        await for (final chunk in chat.generateChatResponseAsync()) {
          // Respect cancellation requests from UI/provider
          if (_cancelRequested) { break; }

          if (chunk is TextResponse) {
            fullResponse += chunk.token;
          } else {
            fullResponse += chunk.toString();
          }
        }
      } catch (e) {
        // If generation fails mid-stream, return what we have
        if (fullResponse.isNotEmpty) {
          return fullResponse;
        }
        throw Exception('Generation error: $e');
      }

      return fullResponse.isNotEmpty
          ? fullResponse
          : (_cancelRequested ? 'Cancelled' : 'Could not process locally.');
    } on Exception catch (e, stackTrace) {
      // Log the error for debugging
      debugPrint('Gemma Error: $e\n$stackTrace');

      // Return a user-friendly error message
      if (e.toString().contains('Unsupported or unknown file format')) {
        throw Exception(
          'Local AI model is corrupted. Please clear app cache and reinstall.',
        );
      } else if (e.toString().contains('timeout')) {
        throw Exception(
          'Local AI model took too long to initialize. Device may be low on memory.',
        );
      } else if (e.toString().contains('null')) {
        throw Exception(
          'Local AI model failed to load. Try restarting the app.',
        );
      }

      throw Exception('Local Gemma Error: $e');
    } catch (e) {
      // Catch any other errors (including platform exceptions from native code)
      debugPrint('Unexpected Gemma Error: $e');
      throw Exception('Local AI crashed. Please restart the app.');
    }
  }
}
