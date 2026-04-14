import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_strings.dart';
import '../../providers/chat_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/scan_provider.dart';
import '../../services/translation_service.dart';
import '../../widgets/confidence_badge.dart';
import '../../widgets/dosage_card.dart';
import '../../widgets/emergency_card.dart';
import '../../widgets/medi_info_card.dart';
import '../../widgets/plain_language_summary_card.dart';
import '../../widgets/safety_card.dart';
import '../../widgets/suggested_questions_card.dart';
import '../../widgets/symptom_chips_row.dart';
import '../../widgets/save_success_dialog.dart';

class ScanResultsScreen extends StatelessWidget {
  /// When true, this screen is shown from SymptomChecker "View Details"
  /// and does not have a save button.
  final bool isInfoMode;
  const ScanResultsScreen({super.key, this.isInfoMode = false});

  @override
  Widget build(BuildContext context) {
    final scan = context.watch<ScanProvider>();
    final lang = context.watch<LanguageProvider>();
    final tr = TranslationService.instance.tr;
    final result = scan.result;

    // Guard: result not yet available
    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: Text(tr(AppStrings.resultsTitle))),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              TextButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: Text(tr(AppStrings.back)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    }

    final med = result.medicine;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summary = lang.isRTL
        ? (scan.summaryResult?.summaryUr.isNotEmpty == true
            ? scan.summaryResult!.summaryUr
            : med.cachedSummaryUr ?? med.summaryUr)
        : scan.summaryEn;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(AppStrings.resultsTitle)),
        actions: [
          // ── Language toggle ─────────────────────────────────────────
          IconButton(
            icon: Text(
              lang.isRTL ? 'EN' : 'UR',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            tooltip: tr(AppStrings.languageTitle),
            onPressed: () => context
                .read<LanguageProvider>()
                .setLanguage(lang.isRTL ? 'en' : 'ur'),
          ),
          // ── Ask AI shortcut ─────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined),
            tooltip: tr(AppStrings.askAIButton),
            onPressed: () => _openChat(context, null),
          ),
          // ── Save ────────────────────────────────────────────────────
          if (!isInfoMode)
            IconButton(
              icon: Icon(
                scan.isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: scan.isSaved ? AppColors.accentOrange : null,
              ),
              onPressed: scan.isSaved
                  ? null
                  : () => _saveMedicine(context, tr),
              tooltip: tr(AppStrings.saveButton),
            ),
          // ── Edit ────────────────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.pushNamed(context, '/manual-edit'),
            tooltip: tr(AppStrings.editButton),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.pagePadding),
        children: [
          // ── Section 1: Identity header ─────────────────────────────
          Card(
            margin: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          med.displayName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ConfidenceBadge(
                        status: result.scanStatus,
                        label: '${result.confidencePercent}%',
                      ),
                    ],
                  ),
                  if (med.genericName.isNotEmpty &&
                      med.genericName != med.brandName) ...[
                    const SizedBox(height: AppDimensions.spaceXS),
                    Text(
                      '${tr(AppStrings.genericName)}: ${med.genericName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                    ),
                  ],
                  if (med.manufacturer.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.spaceXXS),
                    Text(
                      '${tr(AppStrings.manufacturer)}: ${med.manufacturer}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                    ),
                  ],
                  if (med.category.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.spaceXS),
                    Chip(
                      label: Text(med.category),
                      labelStyle: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppColors.primaryBlue),
                      backgroundColor: isDark
                          ? AppColors.infoBlueTintDark
                          : AppColors.infoBlueTint,
                      side: BorderSide(
                          color:
                              AppColors.primaryBlue.withValues(alpha: 0.3)),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Section 2: Plain-language AI summary ───────────────────
          PlainLanguageSummaryCard(
            summary: summary.isNotEmpty ? summary : null,
            isLoading: scan.phase == ScanPhase.processing &&
                summary.isEmpty,
          ),

          // ── Section 3: Symptom chips ───────────────────────────────
          if (med.symptomsPlain.isNotEmpty) ...[
            _SectionLabel(tr(AppStrings.symptomsTitle)),
            Padding(
              padding:
                  const EdgeInsets.only(bottom: AppDimensions.spaceMD),
              child: SymptomChipsRow(
                symptoms: med.symptomsPlain,
                onChipTap: () =>
                    Navigator.pushNamed(context, '/symptom-checker'),
              ),
            ),
          ],

          // ── Section 4: Dosage ──────────────────────────────────────
          if (med.dosageAdults.isNotEmpty ||
              med.dosageChildren.isNotEmpty ||
              med.maxDailyDose.isNotEmpty)
            DosageCard(medicine: med),

          // ── Section 5: Safety ──────────────────────────────────────
          if (med.warningsPlain.isNotEmpty ||
              med.warnings.isNotEmpty ||
              med.sideEffects.isNotEmpty)
            SafetyCard(medicine: med),

          // ── Section 6: Onset + Storage ─────────────────────────────
          if (med.onsetTime.isNotEmpty ||
              med.storageInstructions.isNotEmpty)
            MediInfoCard(
              title: '',
              titleIcon: Icons.access_time_outlined,
              rows: [
                if (med.onsetTime.isNotEmpty)
                  InfoRow(
                    label: tr(AppStrings.onsetLabel),
                    value: med.onsetTime,
                    icon: Icons.timer_outlined,
                  ),
                if (med.storageInstructions.isNotEmpty)
                  InfoRow(
                    label: tr(AppStrings.storageLabel),
                    value: med.storageInstructions,
                    icon: Icons.thermostat_outlined,
                  ),
              ],
            ),

          // ── Section 7: Suggested questions ────────────────────────
          if (scan.suggestedQuestions.isNotEmpty ||
              scan.phase == ScanPhase.processing)
            SuggestedQuestionsCard(
              questions: scan.suggestedQuestions,
              isLoading: scan.suggestedQuestions.isEmpty &&
                  scan.phase == ScanPhase.processing,
              onQuestionTap: (q) => _openChat(context, q),
            ),

          // ── Section 8: Emergency ───────────────────────────────────
          const EmergencyCard(),

          const SizedBox(height: AppDimensions.spaceLG),

          // ── Bottom action buttons ──────────────────────────────────
          if (!isInfoMode && !scan.isSaved)
            SizedBox(
              width: double.infinity,
              height: AppDimensions.buttonHeightLG,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.bookmark_border),
                label: Text(tr(AppStrings.saveButton)),
                onPressed: () => _saveMedicine(context, tr),
              ),
            ),
          const SizedBox(height: AppDimensions.spaceSM),

          // Ask AI — also in AppBar icon above, but kept here as a
          // larger prominent call-to-action for first-time users.
          SizedBox(
            width: double.infinity,
            height: AppDimensions.buttonHeightLG,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.smart_toy_outlined),
              label: Text(tr(AppStrings.askAIButton)),
              onPressed: () => _openChat(context, null),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceHuge),
        ],
      ),
    );
  }

  Future<void> _saveMedicine(
      BuildContext context, String Function(String) tr) async {
    await context.read<ScanProvider>().saveCurrentMedicine();
    if (!context.mounted) return;
    SaveSuccessDialog.show(context,
        onViewSaved: () =>
            Navigator.pushNamed(context, '/saved-medicines'));
  }

  void _openChat(BuildContext context, String? question) {
    final scan = context.read<ScanProvider>();
    final lang = context.read<LanguageProvider>();
    final chat = context.read<ChatProvider>();
    if (scan.medicine != null) {
      chat.initWithContext(scan.medicine!,
          languageCode: lang.languageCode);
    }
    if (question != null) {
      chat.sendMessage(question, languageCode: lang.languageCode);
    }
    Navigator.pushNamed(context, '/chat');
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceSM),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
