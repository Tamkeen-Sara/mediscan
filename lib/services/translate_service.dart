import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Thin wrapper around the Google Cloud Translation REST API (v2).
/// Requires GOOGLE_TRANSLATE_API_KEY in .env.
/// If the key is absent or the call fails, returns null and the caller
/// falls back to the cached Gemini translation or the English text.
class TranslateService {
  static TranslateService? _instance;
  static TranslateService get instance =>
      _instance ??= TranslateService._();
  TranslateService._();

  static const String _baseUrl =
      'https://translation.googleapis.com/language/translate/v2';

  String get _apiKey => dotenv.env['GOOGLE_TRANSLATE_API_KEY'] ?? '';

  bool get isAvailable => _apiKey.isNotEmpty;

  /// Translate [text] from [source] to [target] language code.
  /// Returns null on failure.
  Future<String?> translate(
    String text, {
    String source = 'en',
    String target = 'ur',
  }) async {
    if (!isAvailable || text.trim().isEmpty) return null;
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'key': _apiKey,
      });
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'q': text,
              'source': source,
              'target': target,
              'format': 'text',
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final translations = body['data']?['translations'] as List<dynamic>?;
      return translations?.first?['translatedText']?.toString();
    } catch (_) {
      return null;
    }
  }

  /// Translate a batch of strings in one request (more efficient).
  Future<List<String?>> translateBatch(
    List<String> texts, {
    String source = 'en',
    String target = 'ur',
  }) async {
    if (!isAvailable || texts.isEmpty) return List.filled(texts.length, null);
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'key': _apiKey,
      });
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'q': texts,
              'source': source,
              'target': target,
              'format': 'text',
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return List.filled(texts.length, null);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final translations = body['data']?['translations'] as List<dynamic>?;
      if (translations == null) return List.filled(texts.length, null);
      return translations
          .map((t) => t['translatedText']?.toString())
          .toList();
    } catch (_) {
      return List.filled(texts.length, null);
    }
  }
}
