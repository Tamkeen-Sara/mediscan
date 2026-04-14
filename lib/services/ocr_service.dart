import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  static OcrService? _instance;
  static OcrService get instance => _instance ??= OcrService._();
  OcrService._();

  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> extractText(String imagePath) async {
    try {
      final inputImage = InputImage.fromFile(File(imagePath));
      final recognised = await _recognizer.processImage(inputImage);
      return cleanText(recognised.text);
    } catch (_) {
      return '';
    }
  }

  String cleanText(String raw) {
    return raw
        .replaceAll(RegExp(r'\r\n|\r'), '\n')
        // Keep printable ASCII + common extended Latin (accented medicine names)
        // but strip control chars and Urdu/Arabic (OCR is Latin-script only)
        .replaceAll(RegExp(r'[^\x20-\x7E\xA0-\xFF\n]'), ' ')
        .replaceAll(RegExp(r' {2,}'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  List<String> extractTokens(String text) {
    final tokens = <String>{};
    // Split on common separators
    final parts = text.split(RegExp(r'[\s,/\-\(\)\[\]\|:;]+'));
    for (final part in parts) {
      final cleaned = part.trim();
      if (cleaned.length >= 2) {
        tokens.add(cleaned.toLowerCase());
      }
    }

    // Also add multi-word phrases (bigrams/trigrams) for better matching
    final words = text.split(RegExp(r'\s+'));
    for (int i = 0; i < words.length - 1; i++) {
      final bigram =
          '${words[i].toLowerCase()} ${words[i + 1].toLowerCase()}';
      if (bigram.trim().length > 4) tokens.add(bigram.trim());
    }
    for (int i = 0; i < words.length - 2; i++) {
      final trigram =
          '${words[i].toLowerCase()} ${words[i + 1].toLowerCase()} ${words[i + 2].toLowerCase()}';
      if (trigram.trim().length > 6) tokens.add(trigram.trim());
    }

    return tokens.toList();
  }

  /// Tries to extract a dosage string like "500mg", "250 mg", "1g" etc.
  String? extractDosage(String text) {
    final match = RegExp(
            r'\b(\d+(?:\.\d+)?)\s*(mg|mcg|g|ml|iu|mmol)\b',
            caseSensitive: false)
        .firstMatch(text);
    if (match == null) return null;
    return '${match.group(1)}${match.group(2)?.toLowerCase()}';
  }

  void dispose() {
    _recognizer.close();
  }
}
