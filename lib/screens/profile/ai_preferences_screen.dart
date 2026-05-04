import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_strings.dart';
import '../../providers/preferences_provider.dart';
import '../../services/translation_service.dart';

class AiPreferencesScreen extends StatelessWidget {
  const AiPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = TranslationService.instance.tr;
    final prefs = context.watch<PreferencesProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(tr(AppStrings.aiPrefsTitle))),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(tr(AppStrings.aiPrefsUseGemini)),
            subtitle: Text(tr(AppStrings.aiPrefsUseGeminiDesc)),
            value: prefs.useGemini,
            onChanged: (v) =>
                context.read<PreferencesProvider>().setUseGemini(v),
          ),
          SwitchListTile(
            title: Text(tr(AppStrings.aiPrefsFallbackTemplates)),
            subtitle: Text(tr(AppStrings.aiPrefsFallbackTemplatesDesc)),
            value: prefs.fallbackTemplates,
            onChanged: (v) =>
                context.read<PreferencesProvider>().setFallbackTemplates(v),
          ),
          SwitchListTile(
            title: Text(tr(AppStrings.aiPrefsAutoSummarise)),
            subtitle: Text(tr(AppStrings.aiPrefsAutoSummariseDesc)),
            value: prefs.autoSummarise,
            onChanged: (v) =>
                context.read<PreferencesProvider>().setAutoSummarise(v),
          ),
        ],
      ),
    );
  }
}
