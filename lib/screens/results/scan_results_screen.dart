import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_strings.dart';
import '../../models/identification_result.dart';
import '../../providers/chat_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/scan_provider.dart';
import '../../services/gemini_service.dart';
import '../../services/translation_service.dart';
import '../../widgets/animated_cards.dart';
import '../../widgets/confidence_badge.dart';
import '../../widgets/dosage_card.dart';
import '../../widgets/emergency_card.dart';
import '../../widgets/medi_info_card.dart';
import '../../widgets/plain_language_summary_card.dart';
import '../../widgets/safety_card.dart';
import '../../widgets/suggested_questions_card.dart';
import '../../widgets/symptom_chips_row.dart';
import '../../widgets/save_success_dialog.dart';

class ScanResultsScreen extends StatefulWidget {
  /// When true, shown from SymptomChecker "View Details" — no save button.
  final bool isInfoMode;
  const ScanResultsScreen({super.key, this.isInfoMode = false});

  @override
  State<ScanResultsScreen> createState() => _ScanResultsScreenState();
}

class _ScanResultsScreenState extends State<ScanResultsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scan = context.read<ScanProvider>();
      if (scan.summaryResult == null && scan.result?.medicine != null) {
        scan.generateSummaryForCurrentMedicine();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // context.select: only the selected field triggers a rebuild,
    // not the entire ListView on every notifyListeners() call.
    final result = context
        .select<ScanProvider, IdentificationResult?>((p) => p.result);
    final summaryResult = context
        .select<ScanProvider, GeminiSummaryResult?>((p) => p.summaryResult);
    final phase =
        context.select<ScanProvider, ScanPhase>((p) => p.phase);
    final isSaved =
        context.select<ScanProvider, bool>((p) => p.isSaved);
    final suggestedQuestions = context
        .select<ScanProvider, List<String>>((p) => p.suggestedQuestions);
    final lang = context.watch<LanguageProvider>();
    final tr = TranslationService.instance.tr;

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
      ? (summaryResult?.summaryUr.isNotEmpty == true
        ? summaryResult!.summaryUr
        : (med.cachedSummaryUr?.isNotEmpty == true
          ? med.cachedSummaryUr!
          : med.summaryUr))
      : (summaryResult?.summaryEn.isNotEmpty == true
        ? summaryResult!.summaryEn
        : (med.cachedSummaryEn?.isNotEmpty == true
          ? med.cachedSummaryEn!
          : med.summaryEn));

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(AppStrings.resultsTitle)),
        actions: [
          // ── Language toggle ──────────────────────────────────────────
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
          // ── Ask AI shortcut ──────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined),
            tooltip: tr(AppStrings.askAIButton),
            onPressed: () => _openChat(context, null),
          ),
          // ── Save ─────────────────────────────────────────────────────
          if (!widget.isInfoMode)
            IconButton(
              icon: Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: isSaved ? AppColors.accentOrange : null,
              ),
              onPressed: isSaved ? null : () => _saveMedicine(context, tr),
              tooltip: tr(AppStrings.saveButton),
            ),
          // ── 3-dot overflow menu ───────────────────────────────────────
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'confidence':
                  Navigator.pushNamed(context, '/confidence');
                case 'edit':
                  Navigator.pushNamed(context, '/manual-edit');
                case 'share':
                  _shareMedicine(context, med.displayName, med.genericName,
                      med.manufacturer, med.category, summary);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'confidence',
                child: Row(children: [
                  const Icon(Icons.bar_chart_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(tr(AppStrings.viewConfidenceDetails)),
                ]),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  const Icon(Icons.edit_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(tr(AppStrings.editButton)),
                ]),
              ),
              PopupMenuItem(
                value: 'share',
                child: Row(children: [
                  const Icon(Icons.share_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(tr(AppStrings.share)),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.pagePadding),
        children: [
          // ── Section 1: Identity header ───────────────────────────────
          FadeInCard(
            delay: const Duration(milliseconds: 100),
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
                const SizedBox(height: AppDimensions.spaceXS),
                // ── OTC/Rx + Form badges ─────────────────────────────
                Wrap(
                  spacing: AppDimensions.spaceXS,
                  runSpacing: AppDimensions.spaceXS,
                  children: [
                    _BadgeChip(
                      label: med.requiresPrescription
                          ? tr(AppStrings.badgeRx)
                          : tr(AppStrings.badgeOtc),
                      color: med.requiresPrescription
                          ? AppColors.accentOrange
                          : AppColors.statusGreen,
                      isDark: isDark,
                    ),
                    if (med.dosageForm.isNotEmpty)
                      _BadgeChip(
                        label: med.dosageForm,
                        color: AppColors.primaryBlue,
                        isDark: isDark,
                      ),
                    if (med.category.isNotEmpty)
                      _BadgeChip(
                        label: med.category,
                        color: AppColors.primaryBlue,
                        isDark: isDark,
                      ),
                    if (result.source != null && result.source!.isNotEmpty)
                      _BadgeChip(
                        label: 'Source: ${result.source}',
                        color: AppColors.accentOrange.withValues(alpha: 0.7),
                        isDark: isDark,
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.spaceMD),

          // ── Section 2: AI summary ────────────────────────────────────
          FadeInCard(
            delay: const Duration(milliseconds: 200),
            child: PlainLanguageSummaryCard(
              summary: summary.isNotEmpty ? summary : null,
              isLoading: phase == ScanPhase.processing && summary.isEmpty,
            ),
          ),

          // ── Section 3: Symptom chips ─────────────────────────────────
          if (med.symptomsPlain.isNotEmpty) ...[
            _SectionLabel(tr(AppStrings.symptomsTitle)),
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
              child: SymptomChipsRow(
                symptoms: med.symptomsPlain,
                onChipTap: (_) =>
                    Navigator.pushNamed(context, '/symptom-checker'),
              ),
            ),
          ],

          // ── Section 4: Dosage ────────────────────────────────────────
          if (med.dosageAdults.isNotEmpty ||
              med.dosageChildren.isNotEmpty ||
              med.maxDailyDose.isNotEmpty)
            FadeInCard(
              delay: const Duration(milliseconds: 300),
              child: DosageCard(medicine: med),
            ),

          // ── Section 5: Safety ────────────────────────────────────────
          if (med.warningsPlain.isNotEmpty ||
              med.warnings.isNotEmpty ||
              med.sideEffects.isNotEmpty)
            FadeInCard(
              delay: const Duration(milliseconds: 350),
              child: SafetyCard(medicine: med),
            ),

          // ── Section 6: Onset + Storage ───────────────────────────────
          if (med.onsetTime.isNotEmpty || med.storageInstructions.isNotEmpty)
            FadeInCard(
              delay: const Duration(milliseconds: 400),
              child: MediInfoCard(
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
            ),

          // ── Section 7: Suggested questions ──────────────────────────
          if (suggestedQuestions.isNotEmpty ||
              phase == ScanPhase.processing)
            FadeInCard(
              delay: const Duration(milliseconds: 450),
              child: SuggestedQuestionsCard(
                questions: suggestedQuestions,
                isLoading: suggestedQuestions.isEmpty &&
                    phase == ScanPhase.processing,
                onQuestionTap: (q) => _openChat(context, q),
              ),
            ),

          // ── Section 8: Emergency ─────────────────────────────────────
          const FadeInCard(
            delay: Duration(milliseconds: 500),
            child: EmergencyCard(),
          ),

          const SizedBox(height: AppDimensions.spaceLG),

          // ── Bottom action buttons ────────────────────────────────────
          if (!widget.isInfoMode && !isSaved)
            SizedBox(
              width: double.infinity,
              height: AppDimensions.buttonHeightLG,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.bookmark_border),
                label: Text(tr(AppStrings.saveButton)),
                onPressed: () => _saveMedicine(context, tr),
              ),
            ),
          if (!widget.isInfoMode && !isSaved)
            const SizedBox(height: AppDimensions.spaceSM),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: AppDimensions.buttonHeightLG,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.share_outlined),
                    label: Text(tr(AppStrings.share)),
                    onPressed: () => _shareMedicine(
                        context,
                        med.displayName,
                        med.genericName,
                        med.manufacturer,
                        med.category,
                        summary),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceSM),
              Expanded(
                child: SizedBox(
                  height: AppDimensions.buttonHeightLG,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.smart_toy_outlined),
                    label: Text(tr(AppStrings.askAIButton)),
                    onPressed: () => _openChat(context, null),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceHuge),
        ],
      ),
    );
  }

  void _shareMedicine(
    BuildContext context,
    String displayName,
    String genericName,
    String manufacturer,
    String category,
    String summary,
  ) {
    final buf = StringBuffer();
    buf.writeln('💊 $displayName');
    if (genericName.isNotEmpty && genericName != displayName) {
      buf.writeln('Generic: $genericName');
    }
    if (manufacturer.isNotEmpty) buf.writeln('Manufacturer: $manufacturer');
    if (category.isNotEmpty) buf.writeln('Category: $category');
    if (summary.isNotEmpty) {
      buf.writeln();
      buf.writeln(summary);
    }
    buf.writeln();
    buf.write('Scanned with MediScan');
    Share.share(buf.toString(), subject: displayName);
  }

  Future<void> _saveMedicine(
      BuildContext context, String Function(String) tr) async {
    await context.read<ScanProvider>().saveCurrentMedicine();
    if (!context.mounted) return;
    SaveSuccessDialog.show(context,
        onViewSaved: () => Navigator.pushNamed(context, '/saved-medicines'));
  }

  void _openChat(BuildContext context, String? question) {
    final scan = context.read<ScanProvider>();
    final lang = context.read<LanguageProvider>();
    final chat = context.read<ChatProvider>();
    if (scan.medicine != null) {
      chat.initWithContext(scan.medicine!, languageCode: lang.languageCode);
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

class _BadgeChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const _BadgeChip({
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
