import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class TranslationService {
  static TranslationService? _instance;
  static TranslationService get instance =>
      _instance ??= TranslationService._();
  TranslationService._();

  Map<String, String> _strings = {};
  String _currentLanguage = 'en';

  String get currentLanguage => _currentLanguage;
  bool get isUrdu => _currentLanguage == 'ur';

  Future<void> load(String languageCode) async {
    _currentLanguage = languageCode;
    try {
      final jsonString = await rootBundle
          .loadString('assets/translations/$languageCode.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _strings = jsonMap.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      if (languageCode != 'en') {
        final jsonString =
            await rootBundle.loadString('assets/translations/en.json');
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        _strings = jsonMap.map((k, v) => MapEntry(k, v.toString()));
      }
    }
  }

  String tr(String key) => _strings[key] ?? key;

  static String of(BuildContext context, String key) =>
      instance.tr(key);
}

extension TranslationExtension on BuildContext {
  String tr(String key) => TranslationService.instance.tr(key);
}
