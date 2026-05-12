import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/medicine_model.dart';
import '../models/prescription_models.dart';
import '../models/chat_message.dart';
import '../utils/app_logger.dart';
import 'realtime_db_service.dart';
import 'template_response_service.dart';
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

  // Stable model for OCR fallback identification and medicine summaries.
  // Use the preview model for better performance.
  static const String _modelId = 'gemini-3.1-flash-lite';
  static const List<String> _summaryFallbackModelIds = [
    'gemini-2.0-flash',
  ];

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
    debugPrint('[GEM] generateMedicineSummary start | medicine=${medicine.displayName} | id=${medicine.id} | cached=${medicine.cachedSummaryEn?.isNotEmpty == true} | isAvailable=$isAvailable | primaryModel=$_modelId | fallbackModels=${_summaryFallbackModelIds.join(',')}');
    // Return cached data if present
    if (medicine.cachedSummaryEn != null &&
        medicine.cachedSummaryEn!.isNotEmpty) {
      debugPrint('[GEM] summary served from cache | medicine=${medicine.displayName} | cachedSummaryLen=${medicine.cachedSummaryEn!.length}');
      return GeminiSummaryResult(
        summaryEn: medicine.cachedSummaryEn!,
        summaryUr: medicine.cachedSummaryUr ?? '',
        suggestedQuestions: medicine.cachedSuggestedQuestions ?? [],
      );
    }

    if (!isAvailable) {
      debugPrint('[GEM] summary skipped: Gemini unavailable (missing API key or init failed) | medicine=${medicine.displayName}');
      return null;
    }

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
      var result = await _generateSummaryWithModels(prompt);
      if (result == null) {
        debugPrint('[GEM] summary parse failed | medicine=${medicine.displayName} | falling back to offline summary');
        final offline = _buildOfflineSummary(medicine);
        if (offline != null) {
          debugPrint('[GEM] offline summary fallback used | medicine=${medicine.displayName} | enLen=${offline.summaryEn.length} | urLen=${offline.summaryUr.length}');
          return offline;
        }
        return null;
      }

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
      debugPrint('[GEM] summary success | medicine=${medicine.displayName} | enLen=${result.summaryEn.length} | urLen=${result.summaryUr.length} | questions=${result.suggestedQuestions.length}');
      return result;
    } catch (e, st) {
      lastError = _classifyError(e);
      AppLogger.error('Gemini summary failed', error: e, stackTrace: st);
      debugPrint('[GEM] summary exception: $e | medicine=${medicine.displayName}');
      return null;
    }
  }

  Future<GeminiSummaryResult?> _generateSummaryWithModels(String prompt) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      debugPrint('[GEM] summary aborted: empty GEMINI_API_KEY');
      return null;
    }

    final modelIds = <String>[_modelId, ..._summaryFallbackModelIds];
    for (final modelId in modelIds) {
      try {
        debugPrint('[GEM] summary request sent to Gemini | model=$modelId | promptLen=${prompt.length}');
        final model = GenerativeModel(model: modelId, apiKey: apiKey);
        final response = await model
            .generateContent([Content.text(prompt)])
            .timeout(_kGeminiTimeout,
                onTimeout: () => throw TimeoutException('Summary timed out'));
        final text = response.text ?? '';
        debugPrint('[GEM] summary raw response | model=$modelId | textLen=${text.length}');
        final result = _parseSummaryJson(text) ?? _parseLooseSummary(text);
        if (result != null) {
          debugPrint('[GEM] summary parsed successfully | model=$modelId | enLen=${result.summaryEn.length} | urLen=${result.summaryUr.length} | q=${result.suggestedQuestions.length}');
          return result;
        }
        debugPrint('[GEM] summary parse returned null | model=$modelId');
      } catch (e, st) {
        lastError = _classifyError(e);
        AppLogger.warning('Gemini summary model failed: $modelId', error: e);
        debugPrint('[GEM] summary exception | model=$modelId | classified=$lastError | error=$e');
        if (lastError != GeminiError.modelUnavailable && lastError != GeminiError.apiKeyInvalid) {
          continue;
        }
      }
    }

    return null;
  }

  GeminiSummaryResult? _buildOfflineSummary(MedicineModel medicine) {
    final name = medicine.displayName.trim().isNotEmpty
        ? medicine.displayName.trim()
        : medicine.genericName.trim();
    if (name.isEmpty) return null;

    final englishSummary = medicine.cachedSummaryEn?.isNotEmpty == true
        ? medicine.cachedSummaryEn!
        : medicine.summaryEn.isNotEmpty
            ? medicine.summaryEn
            : TemplateResponseService.instance.getResponse(
                question: 'what is it used for',
                medicine: medicine,
                languageCode: 'en',
              );

    final urduSummary = medicine.cachedSummaryUr?.isNotEmpty == true
        ? medicine.cachedSummaryUr!
        : medicine.summaryUr.isNotEmpty
            ? medicine.summaryUr
            : TemplateResponseService.instance.getResponse(
                question: 'what is it used for',
                medicine: medicine,
                languageCode: 'ur',
              );

    return GeminiSummaryResult(
      summaryEn: englishSummary,
      summaryUr: urduSummary,
      suggestedQuestions: const [],
    );
  }

  GeminiSummaryResult? _parseSummaryJson(String text) {
    try {
      final cleaned = text
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
      final jsonText = jsonMatch != null ? jsonMatch.group(0)! : cleaned;
      final map = jsonDecode(jsonText) as Map<String, dynamic>;
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

  GeminiSummaryResult? _parseLooseSummary(String text) {
    final cleaned = text
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();
    if (cleaned.isEmpty) return null;

    final summaryEnMatch = RegExp(
      r'(?:summaryEn|summary en|english)\s*[:\-]\s*(.+?)(?=(?:summaryUr|summary ur|urdu)\s*[:\-]|suggestedQuestions|questions|$)',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(cleaned);
    final summaryUrMatch = RegExp(
      r'(?:summaryUr|summary ur|urdu)\s*[:\-]\s*(.+?)(?=(?:summaryEn|summary en|english)\s*[:\-]|suggestedQuestions|questions|$)',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(cleaned);

    final summaryEn = summaryEnMatch?.group(1)?.trim() ?? cleaned;
    final summaryUr = summaryUrMatch?.group(1)?.trim() ?? '';

    if (summaryEn.isEmpty) return null;

    return GeminiSummaryResult(
      summaryEn: summaryEn,
      summaryUr: summaryUr,
      suggestedQuestions: const [],
    );
  }
  // ─────────────── OCR Fallback Identification ────────────────────────

  Future<MedicineModel?> identifyMedicineFromOcr(String ocrText) async {
    debugPrint('[GEM] identifyMedicineFromOcr start | isAvailable=$isAvailable | rawLen=${ocrText.length} | model=$_modelId');
    if (!isAvailable) return null;

    final prompt = '''
You are an expert pharmacist and OCR data extractor.
Analyze the following raw OCR text extracted from a medicine box or blister pack in Pakistan.
Identify the most likely medicine using a best-effort approach.
Return ONLY a valid JSON object matching this structure:
{
  "brandName": "Exact brand name (if any)",
  "genericName": "Generic name or active ingredient",
  "dosageForm": "e.g., Tablet, Syrup, Injection",
  "strength": "e.g., 500mg",
  "manufacturer": "Company name if visible"
}
Return an empty JSON object only if the text clearly contains no medicine information at all.
Do not include markdown formatting or any other text.

OCR Text:
$ocrText
''';

    try {
      final response = await _model!
          .generateContent([Content.text(prompt)])
          .timeout(_kGeminiTimeout,
              onTimeout: () => throw TimeoutException('OCR identification timed out'));
      
      final text = response.text ?? '';
        debugPrint('[GEM] raw response text: $text');
      final cleaned = text
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();
        debugPrint('[GEM] cleaned response: $cleaned');

      Map<String, dynamic>? map;
      try {
        // Try to extract a JSON object substring if the model wrapped it
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
        final jsonText = jsonMatch != null ? jsonMatch.group(0)! : cleaned;
        map = jsonDecode(jsonText) as Map<String, dynamic>?;
      } catch (_) {
        map = null;
      }

      String brand = '';
      String generic = '';
      String dosageForm = '';
      String strength = '';
      String manufacturer = '';

      if (map != null) {
        brand = (map['brandName'] ?? map['brand'] ?? map['Brand'] ?? map['brand_name'])?.toString() ?? '';
        generic = (map['genericName'] ?? map['generic'] ?? map['generic_name'])?.toString() ?? '';
        dosageForm = (map['dosageForm'] ?? map['dosage_form'] ?? map['dosage'])?.toString() ?? '';
        strength = (map['strength'] ?? map['Strength'] ?? map['dose'])?.toString() ?? '';
        manufacturer = (map['manufacturer'] ?? map['maker'] ?? map['company'])?.toString() ?? '';
      } else {
        // Fallback: parse simple `Key: Value` lines
        final lines = cleaned.split(RegExp(r'[\r\n]+'));
        for (final line in lines) {
          final parts = line.split(':');
          if (parts.length < 2) continue;
          final key = parts[0].toLowerCase();
          final value = parts.sublist(1).join(':').trim();
          if (key.contains('brand')) brand = brand.isEmpty ? value : brand;
          if (key.contains('generic') || key.contains('active')) generic = generic.isEmpty ? value : generic;
          if (key.contains('dosage') || key.contains('form')) dosageForm = dosageForm.isEmpty ? value : dosageForm;
          if (key.contains('strength') || key.contains('mg')) strength = strength.isEmpty ? value : strength;
          if (key.contains('manufact') || key.contains('maker') || key.contains('company')) manufacturer = manufacturer.isEmpty ? value : manufacturer;
        }
      }

      if ((brand.isEmpty) && (generic.isEmpty)) {
        AppLogger.info('Gemini OCR identification returned unparseable text: $cleaned');
        debugPrint('[GEM] parse failed: both brand and generic empty');
        return null;
      }

      lastError = null;
      debugPrint('[GEM] parse success | brand=$brand | generic=$generic | form=$dosageForm | strength=$strength');

      return MedicineModel(
        id: 'gemini_${DateTime.now().millisecondsSinceEpoch}',
        brandName: brand,
        genericName: generic,
        dosageForm: dosageForm,
        strength: strength,
        manufacturer: manufacturer,
      );
    } catch (e, st) {
      lastError = _classifyError(e);
      AppLogger.error('Gemini OCR identification failed', error: e, stackTrace: st);
      debugPrint('[GEM] exception during OCR identify: $e');
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

  // ─────────────── Prescription Extraction ─────────────────────────

  Future<List<PrescriptionEntry>> extractPrescriptionEntries(String ocrText) async {
    if (!isAvailable || ocrText.trim().isEmpty) return const [];

    final prompt = '''
You are extracting medicine names from a handwritten or printed prescription OCR text.
Return up to 6 probable medicines only.

Important:
- Ignore patient name, doctor name, dates, signatures, stamps, addresses, and page labels.
- Ignore dosage instructions unless they help identify the medicine.
- If a line contains extra text, keep only the medicine name in rawName.
- Do not invent medicines that are not present.
- Prefer fewer correct entries over many noisy ones.

OCR text:
$ocrText

Return ONLY valid JSON with this schema:
{
  "entries": [
    {
      "rawName": "medicine name",
      "dosageText": "e.g. 500mg",
      "frequencyText": "e.g. twice daily",
      "notes": "e.g. after food"
    }
  ]
}

Rules:
- Skip items that are clearly not medicine names.
- Keep uncertain medicine names only if they look like real medicines.
- Do not invent dosage/frequency.
- No markdown, no extra text.
''';

    try {
      final response = await _model!
          .generateContent([Content.text(prompt)])
          .timeout(_kGeminiTimeout,
              onTimeout: () => throw TimeoutException('Prescription extraction timed out'));
      final text = response.text ?? '';
      final cleaned = text
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
      final jsonText = jsonMatch != null ? jsonMatch.group(0)! : cleaned;
      final map = jsonDecode(jsonText) as Map<String, dynamic>;
      final rawEntries = (map['entries'] as List<dynamic>? ?? const []);
      final entries = rawEntries.map((e) {
        final m = e as Map<String, dynamic>;
        return PrescriptionEntry(
          rawName: m['rawName']?.toString().trim() ?? '',
          dosageText: m['dosageText']?.toString().trim() ?? '',
          frequencyText: m['frequencyText']?.toString().trim() ?? '',
          notes: m['notes']?.toString().trim() ?? '',
        );
      }).where((e) => e.rawName.isNotEmpty).toList();
      return entries;
    } catch (e, st) {
      AppLogger.error('Gemini prescription extraction failed', error: e, stackTrace: st);
      return const [];
    }
  }

  Future<PrescriptionEntry> generatePrescriptionExplanation(PrescriptionEntry entry) async {
    if (!isAvailable || entry.rawName.trim().isEmpty) return entry;

    final prompt = '''
You are a pharmacist assistant for Pakistani patients.
Given one prescription item, provide:
1) A simple explanation in English.
2) The same explanation in Urdu.

Input:
medicine: ${entry.rawName}
dosage: ${entry.dosageText}
frequency: ${entry.frequencyText}
notes: ${entry.notes}

Return ONLY valid JSON:
{
  "explanationEn": "...",
  "explanationUr": "..."
}
No markdown, no extra text.
''';

    try {
      final response = await _model!
          .generateContent([Content.text(prompt)])
          .timeout(_kGeminiTimeout,
              onTimeout: () => throw TimeoutException('Prescription explanation timed out'));
      final text = response.text ?? '';
      final cleaned = text
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
      final jsonText = jsonMatch != null ? jsonMatch.group(0)! : cleaned;
      final map = jsonDecode(jsonText) as Map<String, dynamic>;
      return entry.copyWith(
        explanationEn: map['explanationEn']?.toString().trim() ?? '',
        explanationUr: map['explanationUr']?.toString().trim() ?? '',
      );
    } catch (e, st) {
      AppLogger.error('Gemini prescription explanation failed', error: e, stackTrace: st);
      return entry;
    }
  }
}
