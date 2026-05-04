import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Keys
const _kUseGemini = 'pref_use_gemini';
const _kFallbackTemplates = 'pref_fallback_templates';
const _kAutoSummarise = 'pref_auto_summarise';

class PreferencesProvider extends ChangeNotifier {
  bool _useGemini = true;
  bool _fallbackTemplates = true;
  bool _autoSummarise = true;

  bool get useGemini => _useGemini;
  bool get fallbackTemplates => _fallbackTemplates;
  bool get autoSummarise => _autoSummarise;

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _useGemini = prefs.getBool(_kUseGemini) ?? true;
    _fallbackTemplates = prefs.getBool(_kFallbackTemplates) ?? true;
    _autoSummarise = prefs.getBool(_kAutoSummarise) ?? true;
    notifyListeners();
  }

  Future<void> setUseGemini(bool v) async {
    if (_useGemini == v) return;
    _useGemini = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kUseGemini, v);
  }

  Future<void> setFallbackTemplates(bool v) async {
    if (_fallbackTemplates == v) return;
    _fallbackTemplates = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kFallbackTemplates, v);
  }

  Future<void> setAutoSummarise(bool v) async {
    if (_autoSummarise == v) return;
    _autoSummarise = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoSummarise, v);
  }
}
