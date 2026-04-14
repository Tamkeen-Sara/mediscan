import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/medicine_model.dart';
import '../models/chat_message.dart';
import 'realtime_db_service.dart';
import 'translate_service.dart';

class GeminiSummaryResult {
  final String summaryEn;
  final String summaryUr;
  final List<String> suggestedQuestions;

  const GeminiSummaryResult({
    required this.summaryEn,
    required this.summaryUr,
    required this.suggestedQuestions,
  });
}

// Structured error codes returned instead of null so callers can show
// specific messages rather than a generic "offline" banner.
enum GeminiError { apiKeyInvalid, rateLimited, modelUnavailable, network }

class GeminiService {
  static GeminiService? _instance;
  static GeminiService get instance => _instance ??= GeminiService._();
  GeminiService._();

  // gemini-2.0-flash: GA model, generous free-tier quota, widely available.
  // Change this to any model ID from https://aistudio.google.com/models
  static const String _modelId = 'gemini-3.1-flash-lite-preview';

  GenerativeModel? _model;
  bool _initialised = false;

  // Last error from a failed call — exposed so the UI can show a reason.
  GeminiError? lastError;

  void _ensureInitialised() {
    if (_initialised) return;
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) return;
    _model = GenerativeModel(model: _modelId, apiKey: apiKey);
    _initialised = true;
  }

  bool get isAvailable {
    _ensureInitialised();
    return _model != null;
  }

  // ─────────────── Error classification ─────────────────────────────

  GeminiError _classifyError(Object e) {
    final msg = e.toString().toLowerCase();
    // Check API key errors FIRST — these often mention "model" in the message
    // (e.g. "not authorized to use this model") so order matters here.
    if (msg.contains('api_key') ||
        msg.contains('api key') ||
        msg.contains('permission_denied') ||
        msg.contains('unauthorized') ||
        msg.contains('invalid_api_key') ||
        (msg.contains('403') && !msg.contains('quota'))) {
      return GeminiError.apiKeyInvalid;
    }
    if (msg.contains('429') ||
        msg.contains('quota') ||
        msg.contains('resource_exhausted') ||
        msg.contains('rate_limit')) {
      return GeminiError.rateLimited;
    }
    // Only classify as modelUnavailable when we're certain it's a 404 on the
    // model path — NOT just any message that happens to contain the word "model".
    if (msg.contains('404') || msg.contains('is not found for api version')) {
      return GeminiError.modelUnavailable;
    }
    return GeminiError.network;
  }

  // ─────────────── Medicine Summary ─────────────────────────────────

  Future<GeminiSummaryResult?> generateMedicineSummary(
      MedicineModel medicine) async {
    // Return cached data if present
    if (medicine.cachedSummaryEn != null &&
        medicine.cachedSummaryEn!.isNotEmpty) {
      return GeminiSummaryResult(
        summaryEn: medicine.cachedSummaryEn!,
        summaryUr: medicine.cachedSummaryUr ?? '',
        suggestedQuestions: medicine.cachedSuggestedQuestions ?? [],
      );
    }

    if (!isAvailable) return null;

    final prompt = '''
You are a medical information assistant helping Pakistani patients understand their medicines.

Medicine: ${medicine.displayName}
Generic name: ${medicine.genericName}
Category: ${medicine.category}
Used for: ${medicine.symptomsPlain.join(', ')}
Dosage info: ${medicine.dosageAdults}
Key warnings: ${medicine.warningsPlain}

Please respond in valid JSON only, with exactly this structure:
{
  "summaryEn": "A 2-3 sentence plain English explanation of what this medicine does and when to use it, written for a patient with no medical background.",
  "summaryUr": "وہی خلاصہ اردو میں، سادہ زبان میں۔",
  "suggestedQuestions": [
    "First follow-up question a patient might ask",
    "Second follow-up question",
    "Third follow-up question"
  ]
}

Do not include any text outside the JSON object.
''';

    try {
      final response =
          await _model!.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      var result = _parseSummaryJson(text);
      if (result == null) return null;

      // Translate to Urdu if Gemini didn't produce one and the key is available
      if (result.summaryUr.isEmpty && result.summaryEn.isNotEmpty) {
        final translated = await TranslateService.instance
            .translate(result.summaryEn, source: 'en', target: 'ur');
        if (translated != null && translated.isNotEmpty) {
          result = GeminiSummaryResult(
            summaryEn: result.summaryEn,
            summaryUr: translated,
            suggestedQuestions: result.suggestedQuestions,
          );
        }
      }

      // Cache in RTDB
      if (medicine.id.isNotEmpty) {
        await RealtimeDatabaseService.instance.updateMedicineSummaryCache(
          medicineId: medicine.id,
          summaryEn: result.summaryEn,
          summaryUr: result.summaryUr,
          suggestedQuestions: result.suggestedQuestions,
        );
      }
      lastError = null;
      return result;
    } catch (e) {
      lastError = _classifyError(e);
      return null;
    }
  }

  GeminiSummaryResult? _parseSummaryJson(String text) {
    try {
      final cleaned = text
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();
      final map = jsonDecode(cleaned) as Map<String, dynamic>;
      final questions = (map['suggestedQuestions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      return GeminiSummaryResult(
        summaryEn: map['summaryEn']?.toString() ?? '',
        summaryUr: map['summaryUr']?.toString() ?? '',
        suggestedQuestions: questions,
      );
    } catch (_) {
      return null;
    }
  }

  // ─────────────── Chat ──────────────────────────────────────────────

  /// Returns:
  ///   String text   — successful reply
  ///   '__rate_limit__'    — 429 / quota exceeded
  ///   '__api_key_error__' — 403 / invalid key / API not enabled
  ///   '__model_error__'   — 404 / model not available
  ///   null                — other network/unknown failure
  Future<String?> sendMessage({
    required List<ChatMessage> history,
    required String userMessage,
    MedicineModel? context,
  }) async {
    if (!isAvailable) return null;

    try {
      final chat = _model!.startChat(
        history: _buildHistory(history, context),
      );
      final response =
          await chat.sendMessage(Content.text(userMessage));
      lastError = null;
      return response.text;
    } catch (e) {
      lastError = _classifyError(e);
      switch (lastError) {
        case GeminiError.rateLimited:
          return '__rate_limit__';
        case GeminiError.apiKeyInvalid:
          return '__api_key_error__';
        case GeminiError.modelUnavailable:
          return '__model_error__';
        default:
          return null;
      }
    }
  }

  List<Content> _buildHistory(
      List<ChatMessage> messages, MedicineModel? context) {
    final contents = <Content>[];

    if (context != null) {
      final systemText = '''
You are MediScan AI, a helpful medical information assistant for Pakistani patients.
You are answering questions about: ${context.displayName} (${context.genericName}).
Summary: ${context.cachedSummaryEn ?? context.summaryEn}
Dosage: ${context.dosageAdults}
Warnings: ${context.warningsPlain}
Always recommend consulting a doctor for personal medical advice.
''';
      contents.add(Content.text(systemText));
      contents.add(Content.model([
        TextPart(
            'Understood. I am ready to answer questions about ${context.displayName}. How can I help?')
      ]));
    } else {
      contents.add(Content.text(
          'You are MediScan AI, a helpful medical information assistant for Pakistani patients. '
          'Answer questions about medicines, dosage, interactions, and safety. '
          'Always recommend consulting a doctor for personal medical advice.'));
      contents.add(Content.model([
        TextPart(
            'Hello! I am MediScan AI. How can I help you with your medicine questions today?')
      ]));
    }

    for (final msg in messages) {
      if (msg.isLoading) continue;
      if (msg.isUser) {
        contents.add(Content.text(msg.text));
      } else {
        contents.add(Content.model([TextPart(msg.text)]));
      }
    }

    return contents;
  }
}
