import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/app_strings.dart';
import '../../models/user_preferences_model.dart';
import '../../services/realtime_db_service.dart';
import '../../services/translation_service.dart';

class AiPreferencesScreen extends StatefulWidget {
  const AiPreferencesScreen({super.key});

  @override
  State<AiPreferencesScreen> createState() => _AiPreferencesScreenState();
}

class _AiPreferencesScreenState extends State<AiPreferencesScreen> {
  UserPreferencesModel _prefs = UserPreferencesModel.defaults();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _prefs = await RealtimeDatabaseService.instance.getPreferences(uid);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save(UserPreferencesModel updated) async {
    setState(() => _prefs = updated);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await RealtimeDatabaseService.instance.savePreferences(uid, updated);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(TranslationService.instance.tr(AppStrings.aiPrefsSaved)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = TranslationService.instance.tr;

    return Scaffold(
      appBar: AppBar(title: Text(tr(AppStrings.aiPrefsTitle))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: Text(tr(AppStrings.aiPrefsUseGemini)),
                  subtitle: Text(tr(AppStrings.aiPrefsUseGeminiDesc)),
                  value: _prefs.useGeminiAI,
                  onChanged: (v) =>
                      _save(_prefs.copyWith(useGeminiAI: v)),
                ),
                SwitchListTile(
                  title: Text(tr(AppStrings.aiPrefsFallbackTemplates)),
                  subtitle: Text(tr(AppStrings.aiPrefsFallbackTemplatesDesc)),
                  value: _prefs.fallbackToTemplates,
                  onChanged: (v) =>
                      _save(_prefs.copyWith(fallbackToTemplates: v)),
                ),
                SwitchListTile(
                  title: Text(tr(AppStrings.aiPrefsAutoSummarise)),
                  subtitle: Text(tr(AppStrings.aiPrefsAutoSummariseDesc)),
                  value: _prefs.autoSummariseMedicine,
                  onChanged: (v) =>
                      _save(_prefs.copyWith(autoSummariseMedicine: v)),
                ),
              ],
            ),
    );
  }
}
