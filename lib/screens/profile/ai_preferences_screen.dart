import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_strings.dart';
import '../../providers/preferences_provider.dart';
import '../../services/translation_service.dart';
import '../../widgets/animated_cards.dart';

class AiPreferencesScreen extends StatelessWidget {
  const AiPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = TranslationService.instance.tr;
    final prefs = context.watch<PreferencesProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(tr(AppStrings.aiPrefsTitle))),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.pagePadding),
        children: [
          FadeInCard(
            delay: const Duration(milliseconds: 80),
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              title: Text(tr(AppStrings.aiPrefsUseGemini)),
              subtitle: Text(tr(AppStrings.aiPrefsUseGeminiDesc)),
              value: prefs.useGemini,
              onChanged: (v) =>
                  context.read<PreferencesProvider>().setUseGemini(v),
            ),
          ),
          FadeInCard(
            delay: const Duration(milliseconds: 140),
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              title: Text(tr(AppStrings.aiPrefsFallbackTemplates)),
              subtitle: Text(tr(AppStrings.aiPrefsFallbackTemplatesDesc)),
              value: prefs.fallbackTemplates,
              onChanged: (v) =>
                  context.read<PreferencesProvider>().setFallbackTemplates(v),
            ),
          ),
          FadeInCard(
            delay: const Duration(milliseconds: 200),
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              title: Text(tr(AppStrings.aiPrefsAutoSummarise)),
              subtitle: Text(tr(AppStrings.aiPrefsAutoSummariseDesc)),
              value: prefs.autoSummarise,
              onChanged: (v) =>
                  context.read<PreferencesProvider>().setAutoSummarise(v),
            ),
          ),
        ],
      ),
    );
  }
}
