import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_strings.dart';
import '../../models/prescription_models.dart';
import '../../providers/language_provider.dart';
import '../../services/prescription_service.dart';
import '../../services/translation_service.dart';
import '../../widgets/animated_cards.dart';

class PrescriptionResultsScreen extends StatefulWidget {
  final PrescriptionAnalysisResult analysisResult;

  const PrescriptionResultsScreen({
    super.key,
    required this.analysisResult,
  });

  @override
  State<PrescriptionResultsScreen> createState() => _PrescriptionResultsScreenState();
}

class _PrescriptionResultsScreenState extends State<PrescriptionResultsScreen> {
  late final List<PrescriptionEntry> _entries = List<PrescriptionEntry>.from(
    widget.analysisResult.entries,
  );
  late final List<String> _warnings = List<String>.from(widget.analysisResult.interactionWarnings);
  late final String _rawOcrText = widget.analysisResult.rawOcrText;
  final Set<int> _loadingExplanationIndexes = <int>{};

  Future<void> _generateExplanation(int index) async {
    if (_loadingExplanationIndexes.contains(index)) return;

    final current = _entries[index];
    setState(() {
      _loadingExplanationIndexes.add(index);
    });

    try {
      final updated = await PrescriptionService.instance.generateExplanationForEntry(current);
      if (!mounted) return;
      setState(() {
        _entries[index] = updated;
      });
      if (updated.explanationEn.isEmpty && updated.explanationUr.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not generate an explanation for this medicine.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingExplanationIndexes.remove(index);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = TranslationService.instance.tr;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUrdu = context.watch<LanguageProvider>().isRTL;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(AppStrings.resultsTitle)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.pagePadding),
        children: [
          FadeInCard(
            delay: Duration.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(AppStrings.prescriptionTitle),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppDimensions.spaceXS),
                Text(
                  'Scanned medicines found in the prescription.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          if (_warnings.isNotEmpty)
            FadeInCard(
              delay: const Duration(milliseconds: 80),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.statusRedTint,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                ),
                padding: const EdgeInsets.all(AppDimensions.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(AppStrings.prescriptionInteractionWarnings),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.statusRed,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppDimensions.spaceXS),
                    ..._warnings.map((warning) => Padding(
                          padding: const EdgeInsets.only(bottom: AppDimensions.spaceXS),
                          child: Text('- $warning'),
                        )),
                  ],
                ),
              ),
            ),
          if (_warnings.isNotEmpty) const SizedBox(height: AppDimensions.spaceMD),
          if (_entries.isEmpty)
            FadeInCard(
              delay: const Duration(milliseconds: 100),
              child: Text(
                tr(AppStrings.prescriptionNoMedicinesFound),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            ..._entries.asMap().entries.map((item) {
              final index = item.key;
              final entry = item.value;
              final explanation = isUrdu
                  ? (entry.explanationUr.isNotEmpty ? entry.explanationUr : entry.explanationEn)
                  : entry.explanationEn;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
                child: FadeInCard(
                  delay: Duration(milliseconds: 120 + (index * 60)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.rawName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (entry.dosageText.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.spaceXXS),
                        Text('${tr(AppStrings.prescriptionDosage)}: ${entry.dosageText}'),
                      ],
                      if (entry.frequencyText.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.spaceXXS),
                        Text('${tr(AppStrings.prescriptionFrequency)}: ${entry.frequencyText}'),
                      ],
                      if (entry.notes.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.spaceXXS),
                        Text('${tr(AppStrings.prescriptionNotes)}: ${entry.notes}'),
                      ],
                      const SizedBox(height: AppDimensions.spaceSM),
                      if (explanation.isNotEmpty)
                        Text(
                          explanation,
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: _loadingExplanationIndexes.contains(index)
                              ? null
                              : () => _generateExplanation(index),
                          icon: _loadingExplanationIndexes.contains(index)
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.auto_awesome_outlined),
                          label: Text(
                            _loadingExplanationIndexes.contains(index)
                                ? 'Generating explanation...'
                                : tr(AppStrings.prescriptionExplainButton),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: AppDimensions.spaceMD),
          FadeInCard(
            delay: const Duration(milliseconds: 260),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(top: AppDimensions.spaceXS),
              title: Text(
                'Raw extraction',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: SelectableText(
                    _rawOcrText.isEmpty ? 'No OCR text available.' : _rawOcrText,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}