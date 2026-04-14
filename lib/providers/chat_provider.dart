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

  /// Called when navigating to chat from a scan result.
  void initWithContext(MedicineModel medicine, {String languageCode = 'en'}) {
    _contextMedicine = medicine;
    if (_messages.isEmpty) {
      final briefing = languageCode == 'ur'
          ? 'آپ کی دوائی ${medicine.displayName} کے بارے میں معلومات لوڈ ہے۔ آپ کوئی بھی سوال پوچھ سکتے ہیں۔'
          : 'I have your medicine information loaded. Here is a quick summary, and feel free to ask me anything about it.';
      _messages.add(ChatMessage.bot(text: briefing));
      notifyListeners();
    }
  }

  void setGeneralMode() {
    _contextMedicine = null;
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
      final history = _messages
          .where((m) => !m.isLoading)
          .toList();
      // exclude the user message just added (last item) — chat history is prior turns
      final priorHistory =
          history.length > 1 ? history.sublist(0, history.length - 1) : <ChatMessage>[];

      reply = await GeminiService.instance.sendMessage(
        history: priorHistory,
        userMessage: text,
        context: _contextMedicine,
      );
      usedGemini = true;
    }

    // Specific error signals from GeminiService
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
            ? 'AI سے رابطہ ناکام: API key غلط ہے یا Gemini API فعال نہیں۔ Google AI Studio میں key چیک کریں۔'
            : 'AI connection failed: API key is invalid or the Gemini API is not enabled. '
                'Please check your key at aistudio.google.com.',
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

    // Gemini returned null — generic failure, fall back to templates
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
