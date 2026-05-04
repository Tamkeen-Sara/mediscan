import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/medicine_model.dart';
import '../models/chat_message.dart';
import '../utils/app_logger.dart';
import 'realtime_db_service.dart';
import 'translate_service.dart';

const Duration _kGeminiTimeout = Duration(seconds: 30);

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
You are a friendly pharmacist explaining medicine to a Pakistani person who has limited medical knowledge.
Always use simple everyday language. Never use medical jargon.
If you must use a medical term, immediately explain it in brackets.
Example: "ibuprofen (a medicine that reduces pain and swelling)"
Always be reassuring but honest. If something is dangerous, say so clearly but kindly.
Never say "consult your doctor" as the ONLY answer — always give useful information first.

Medicine: ${medicine.displayName}
Generic name: ${medicine.genericName}
Category: ${medicine.category}
Used for: ${medicine.symptomsPlain.join(', ')}
Dosage info: ${medicine.dosageAdults}
Key warnings: ${medicine.warningsPlain.join('; ')}

Task 1 — Write a plain-language summary in English:
- 3 to 4 sentences
- Use words a 12-year-old would understand
- Cover: what this medicine is, what problem it solves, who would need it

Task 2 — Write the same summary in Urdu (summaryUr).

Task 3 — Generate 3 questions a Pakistani person would most want to ask about this medicine.
These should be questions someone asks when they find an old medicine at home.
Simple, conversational, in English.

Return ONLY valid JSON:
{
  "summaryEn": "...",
  "summaryUr": "...",
  "suggestedQuestions": ["q1", "q2", "q3"]
}
No markdown, no explanation, no extra text.
''';

    try {
      final response = await _model!
          .generateContent([Content.text(prompt)])
          .timeout(_kGeminiTimeout,
              onTimeout: () => throw TimeoutException('Summary timed out'));
      final text = response.text ?? '';
      var result = _parseSummaryJson(text);
      if (result == null) return null;

      // Translate to Urdu if Gemini didn't produce one
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
    } catch (e, st) {
      lastError = _classifyError(e);
      AppLogger.error('Gemini summary failed', error: e, stackTrace: st);
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
    String languageCode = 'en',
  }) async {
    if (!isAvailable) return null;

    try {
      final chat = _model!.startChat(
        history: _buildHistory(history, context, languageCode),
      );
      final response = await chat
          .sendMessage(Content.text(userMessage))
          .timeout(_kGeminiTimeout,
              onTimeout: () => throw TimeoutException('Chat timed out'));
      lastError = null;
      return response.text;
    } catch (e, st) {
      lastError = _classifyError(e);
      AppLogger.error('Gemini chat failed', error: e, stackTrace: st);
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
      List<ChatMessage> messages, MedicineModel? context, String languageCode) {
    final contents = <Content>[];
    final isUrdu = languageCode == 'ur';

    if (context != null) {
      final systemText = isUrdu
          ? '''
آپ ایک دوستانہ فارماسسٹ ہیں جو محدود طبی معلومات رکھنے والے پاکستانی شخص کو دوائی سمجھا رہے ہیں۔
ہمیشہ سادہ روزمرہ کی زبان استعمال کریں۔ طبی اصطلاحات سے گریز کریں۔
آپ اس دوائی کے بارے میں سوالات کا جواب دے رہے ہیں: ${context.displayName} (${context.genericName})۔
خلاصہ: ${context.cachedSummaryUr ?? context.cachedSummaryEn ?? context.summaryEn}
خوراک: ${context.dosageAdults}
احتیاطیں: ${context.warningsPlain.join('؛ ')}
ہمیشہ اردو میں جواب دیں۔ صرف "ڈاکٹر سے ملیں" نہ کہیں — پہلے مفید معلومات دیں۔
'''
          : '''
You are a friendly pharmacist explaining medicine to a Pakistani person with limited medical knowledge.
Always use simple everyday language. Never use medical jargon.
If you must use a medical term, immediately explain it in brackets.
Always be reassuring but honest. Keep answers under 150 words unless more is needed.
Never say "consult your doctor" as the ONLY answer — always give useful information first.
Respond in English.

You are answering questions about: ${context.displayName} (${context.genericName}).
Summary: ${context.cachedSummaryEn ?? context.summaryEn}
Dosage: ${context.dosageAdults}
Warnings: ${context.warningsPlain.join('; ')}
''';
      contents.add(Content.text(systemText));
      contents.add(Content.model([
        TextPart(isUrdu
            ? '${context.displayName} کے بارے میں آپ کے سوالات کا جواب دینے کے لیے تیار ہوں۔ کیا مدد کر سکتا ہوں؟'
            : 'Understood. I am ready to answer questions about ${context.displayName}. How can I help?')
      ]));
    } else {
      final systemText = isUrdu
          ? 'آپ ایک دوستانہ فارماسسٹ ہیں جو پاکستانی مریضوں کو دوائیوں کے بارے میں سادہ زبان میں بتا رہے ہیں۔ طبی اصطلاحات سے گریز کریں۔ اگر کوئی علامات بیان کرے تو 2-3 عام OTC دوائیاں بتائیں جو پاکستان میں دستیاب ہوں۔ ہمیشہ اردو میں جواب دیں۔'
          : 'You are a friendly pharmacist explaining medicines to Pakistani patients with limited medical knowledge. '
              'Use simple everyday language. Never use medical jargon without explaining it. '
              'If someone describes symptoms, suggest 2-3 common OTC medicines available in Pakistan that help, '
              'giving brand name, what it does, and usual dose. '
              'End symptom answers with: "You can also use the Symptom Checker in the Scanner tab to search your saved medicines." '
              'Keep answers under 150 words unless more is needed. '
              'Never say "consult your doctor" as the ONLY answer — give useful information first.';
      contents.add(Content.text(systemText));
      contents.add(Content.model([
        TextPart(isUrdu
            ? 'السلام علیکم! میں MediScan AI ہوں۔ آج آپ کی دواؤں کے بارے میں کیا مدد کر سکتا ہوں؟'
            : 'Hello! I am MediScan AI. How can I help you with your medicine questions today?')
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
