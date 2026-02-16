import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Claude AI Service
/// Handles communication with Anthropic's Claude API
class ClaudeAIService {
  final String _apiKey;
  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const String _apiVersion = '2024-06-15';

  ClaudeAIService({required String apiKey}) : _apiKey = apiKey;

  /// Send a message to Claude and get a response
  /// Returns the response text or throws an exception
  Future<String> sendMessage({
    required String prompt,
    required List<Map<String, dynamic>> conversationHistory,
    String model = 'claude-3-5-sonnet-latest',
    double temperature = 0.3,
  }) async {
    try {
      // Build messages array
      final messages = [
        ...conversationHistory.map(
          (msg) => {
            'role': msg['role'], // 'user' or 'assistant'
            'content': msg['content'] as String,
          },
        ),
        {'role': 'user', 'content': prompt},
      ];

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': _apiVersion,
        },
        body: jsonEncode({
          'model': model,
          'max_tokens': 4096,
          'temperature': temperature,
          'messages': messages,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'] as List<dynamic>;
        if (content.isNotEmpty) {
          return content[0]['text'] as String;
        }
        throw Exception('Empty response from Claude API');
      } else if (response.statusCode == 401) {
        throw Exception('Invalid Claude API key');
      } else {
        throw Exception(
          'Claude API error (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Claude API request failed: $e');
    }
  }

  /// Send a message with vision support (images)
  /// Currently used for PDF parsing
  Future<String> sendVisionMessage({
    required String prompt,
    required List<Map<String, dynamic>> images,
    String model = 'claude-3-5-sonnet-latest',
    double temperature = 0.1,
  }) async {
    try {
      // Build content with text and images
      final content = [
        {'type': 'text', 'text': prompt},
        ...images,
      ];

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': _apiVersion,
        },
        body: jsonEncode({
          'model': model,
          'max_tokens': 4096,
          'messages': [
            {'role': 'user', 'content': content},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseContent = data['content'] as List<dynamic>;
        if (responseContent.isNotEmpty) {
          return responseContent[0]['text'] as String;
        }
        throw Exception('Empty response from Claude API');
      } else if (response.statusCode == 401) {
        throw Exception('Invalid Claude API key');
      } else {
        throw Exception(
          'Claude API error (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      if (kDebugMode) print('Claude vision API error: $e');
      throw Exception('Claude vision API request failed: $e');
    }
  }

  /// Validate the API key by making a test request
  Future<bool> validateApiKey() async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': _apiVersion,
        },
        body: jsonEncode({
          'model': 'claude-3-5-sonnet-latest',
          'max_tokens': 10,
          'messages': [
            {'role': 'user', 'content': 'ping'},
          ],
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('API key validation error: $e');
      return false;
    }
  }
}
