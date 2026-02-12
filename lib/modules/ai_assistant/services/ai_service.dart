import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_message.dart';

/// Base AI Service Interface
abstract class BaseAIService {
  Future<String> sendMessage(
    String message,
    String systemPrompt,
    List<AIMessage> history,
  );
  Future<bool> validateApiKey(String apiKey);
  String get modelName;
}

/// Gemini AI Service (Google)
/// Uses Gemini 1.5 Flash for fast, free responses
class GeminiAIService implements BaseAIService {
  final String apiKey;

  // Using Gemini 1.5 Flash - fast and has free tier
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  GeminiAIService({required this.apiKey});

  @override
  String get modelName => 'Gemini 1.5 Flash';

  @override
  Future<String> sendMessage(
    String message,
    String systemPrompt,
    List<AIMessage> history,
  ) async {
    try {
      // Build conversation contents
      final contents = <Map<String, dynamic>>[];

      // Add conversation history
      for (final msg in history) {
        if (msg.role == MessageRole.system)
          continue; // Gemini handles system differently
        contents.add({
          'role': msg.role == MessageRole.user ? 'user' : 'model',
          'parts': [
            {'text': msg.content},
          ],
        });
      }

      // Add current message
      contents.add({
        'role': 'user',
        'parts': [
          {'text': message},
        ],
      });

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': contents,
          'systemInstruction': {
            'parts': [
              {'text': systemPrompt},
            ],
          },
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 2048,
            'topP': 0.9,
          },
          'safetySettings': [
            {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_NONE',
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_NONE',
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_NONE',
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];

        if (text != null) {
          return text;
        } else {
          throw Exception('No response generated');
        }
      } else {
        final error = jsonDecode(response.body);
        final errorMessage = error['error']?['message'] ?? 'Unknown error';
        throw Exception('Gemini API error: $errorMessage');
      }
    } catch (e) {
      throw Exception('Failed to get response: $e');
    }
  }

  @override
  Future<bool> validateApiKey(String apiKey) async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': 'Hello'},
              ],
            },
          ],
          'generationConfig': {'maxOutputTokens': 10},
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// Claude AI Service (Anthropic)
/// Uses Claude 3.5 Sonnet for high-quality responses
class ClaudeAIService implements BaseAIService {
  final String apiKey;

  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';

  ClaudeAIService({required this.apiKey});

  @override
  String get modelName => 'Claude 3.5 Sonnet';

  @override
  Future<String> sendMessage(
    String message,
    String systemPrompt,
    List<AIMessage> history,
  ) async {
    try {
      // Build messages array
      final messages = <Map<String, dynamic>>[];

      // Add conversation history
      for (final msg in history) {
        if (msg.role == MessageRole.system)
          continue; // Claude uses system parameter
        messages.add({
          'role': msg.role == MessageRole.user ? 'user' : 'assistant',
          'content': msg.content,
        });
      }

      // Add current message
      messages.add({'role': 'user', 'content': message});

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-3-5-sonnet-20241022',
          'max_tokens': 2048,
          'system': systemPrompt,
          'messages': messages,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['content']?[0]?['text'];

        if (text != null) {
          return text;
        } else {
          throw Exception('No response generated');
        }
      } else {
        final error = jsonDecode(response.body);
        final errorMessage = error['error']?['message'] ?? 'Unknown error';
        throw Exception('Claude API error: $errorMessage');
      }
    } catch (e) {
      throw Exception('Failed to get response: $e');
    }
  }

  @override
  Future<bool> validateApiKey(String apiKey) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-3-5-sonnet-20241022',
          'max_tokens': 10,
          'messages': [
            {'role': 'user', 'content': 'Hi'},
          ],
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
