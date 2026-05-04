import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/medicine_model.dart';
import '../services/gemini_service.dart';
import '../services/template_response_service.dart';

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  MedicineModel? _contextMedicine;
  bool _isOffline = false;
  bool _isTyping = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  MedicineModel? get contextMedicine => _contextMedicine;
  bool get isOffline => _isOffline;
  bool get isTyping => _isTyping;
  bool get hasContext => _contextMedicine != null;

  /// Called when opening chat from a scan result.
  /// Always starts fresh — clears any previous conversation so one medicine's
  /// history never bleeds into a different medicine's chat session.
  void initWithContext(MedicineModel medicine, {String languageCode = 'en'}) {
    _contextMedicine = medicine;
    _messages.clear();
    _isOffline = false;
    _isTyping = false;

    final isUr = languageCode == 'ur';

    // Message 1 — Identity
    final identityParts = <String>[];
    if (isUr) {
      identityParts.add('**${medicine.displayName}**');
      if (medicine.genericName.isNotEmpty && medicine.genericName != medicine.displayName) {
        identityParts.add('(${medicine.genericName})');
      }
      if (medicine.category.isNotEmpty) identityParts.add('— ${medicine.category}');
      if (medicine.manufacturer.isNotEmpty) identityParts.add('by ${medicine.manufacturer}');
    } else {
      identityParts.add('**${medicine.displayName}**');
      if (medicine.genericName.isNotEmpty && medicine.genericName != medicine.displayName) {
        identityParts.add('(${medicine.genericName})');
      }
      if (medicine.category.isNotEmpty) identityParts.add('— ${medicine.category}');
      if (medicine.manufacturer.isNotEmpty) identityParts.add('by ${medicine.manufacturer}');
    }
    _messages.add(ChatMessage.bot(text: identityParts.join(' ')));

    // Message 2 — Summary (only if one is cached)
    final summary = isUr
        ? (medicine.summaryUr.isNotEmpty ? medicine.summaryUr : medicine.cachedSummaryUr)
        : (medicine.summaryEn.isNotEmpty ? medicine.summaryEn : medicine.cachedSummaryEn);
    if (summary != null && summary.isNotEmpty) {
      _messages.add(ChatMessage.bot(text: summary));
    }

    // Message 3 — Call to action
    _messages.add(ChatMessage.bot(
      text: isUr
          ? 'آپ نیچے دی گئی تجاویز میں سے کوئی بھی سوال تھپتھپائیں، یا اپنا سوال ٹائپ کریں۔'
          : 'Tap a suggested question below, or ask me anything about ${medicine.displayName}.',
    ));

    notifyListeners();
  }

  /// Resets to general assistant mode (no medicine context, blank slate).
  void setGeneralMode() {
    _contextMedicine = null;
    _messages.clear();
    _isOffline = false;
    _isTyping = false;
    notifyListeners();
  }

  Future<void> sendMessage(
    String text, {
    String languageCode = 'en',
    bool useGemini = true,
    bool fallbackTemplates = true,
  }) async {
    if (text.trim().isEmpty) return;

    _messages.add(ChatMessage.user(text));
    _messages.add(ChatMessage.loading());
    _isTyping = true;
    notifyListeners();

    String? reply;
    bool usedGemini = false;

    if (useGemini && GeminiService.instance.isAvailable) {
      final history = _messages.where((m) => !m.isLoading).toList();
      final priorHistory =
          history.length > 1 ? history.sublist(0, history.length - 1) : <ChatMessage>[];

      reply = await GeminiService.instance.sendMessage(
        history: priorHistory,
        userMessage: text,
        context: _contextMedicine,
        languageCode: languageCode,
      );
      usedGemini = true;
    }

    if (reply == '__rate_limit__') {
      _removeLoading();
      _isTyping = false;
      _isOffline = true;
      _messages.add(ChatMessage.bot(
        text: languageCode == 'ur'
            ? 'بہت زیادہ درخواستیں۔ کچھ دیر بعد دوبارہ پوچھیں۔'
            : 'Too many requests. Please wait a moment and try again.',
        isTemplateResponse: true,
      ));
      notifyListeners();
      return;
    }

    if (reply == '__api_key_error__') {
      _removeLoading();
      _isTyping = false;
      _isOffline = true;
      _messages.add(ChatMessage.bot(
        text: languageCode == 'ur'
            ? 'AI سے رابطہ ناکام: API key غلط ہے یا Gemini API فعال نہیں۔'
            : 'AI connection failed: API key is invalid or the Gemini API is not enabled.',
        isTemplateResponse: true,
      ));
      notifyListeners();
      return;
    }

    if (reply == '__model_error__') {
      _removeLoading();
      _isTyping = false;
      _isOffline = true;
      _messages.add(ChatMessage.bot(
        text: languageCode == 'ur'
            ? 'AI ماڈل دستیاب نہیں۔ براہ کرم ڈویلپر سے رابطہ کریں۔'
            : 'AI model is unavailable. The developer may need to update the model name.',
        isTemplateResponse: true,
      ));
      notifyListeners();
      return;
    }

    if (reply == null || reply.isEmpty) {
      _isOffline = usedGemini;
      if (fallbackTemplates) {
        reply = TemplateResponseService.instance.getResponse(
          question: text,
          medicine: _contextMedicine,
          languageCode: languageCode,
        );
      }
    } else {
      _isOffline = false;
    }

    _removeLoading();
    _isTyping = false;

    if (reply != null && reply.isNotEmpty) {
      _messages.add(ChatMessage.bot(
        text: reply,
        isTemplateResponse: !usedGemini || _isOffline,
      ));
    }

    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  void _removeLoading() {
    _messages.removeWhere((m) => m.isLoading);
  }
}
