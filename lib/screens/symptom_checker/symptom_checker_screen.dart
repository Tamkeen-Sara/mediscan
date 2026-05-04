import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_strings.dart';
import '../../providers/chat_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/scan_provider.dart';
import '../../providers/symptom_checker_provider.dart';
import '../../services/symptom_match_service.dart';
import '../../services/translation_service.dart';
import '../../widgets/medicine_result_card.dart';

class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  // All 26 symptom keys mapped to display strings via tr()
  static const _symptoms = [
    AppStrings.symptomHeadache,
    AppStrings.symptomFever,
    AppStrings.symptomCough,
    AppStrings.symptomColdFlu,
    AppStrings.symptomSoreThroat,
    AppStrings.symptomBodyAche,
    AppStrings.symptomNausea,
    AppStrings.symptomVomiting,
    AppStrings.symptomDiarrhoea,
    AppStrings.symptomConstipation,
    AppStrings.symptomAcidity,
    AppStrings.symptomStomachPain,
    AppStrings.symptomAllergy,
    AppStrings.symptomRash,
    AppStrings.symptomItching,
    AppStrings.symptomDizziness,
    AppStrings.symptomFatigue,
    AppStrings.symptomInsomnia,
    AppStrings.symptomAnxiety,
    AppStrings.symptomJointPain,
    AppStrings.symptomBackPain,
    AppStrings.symptomEyeIrritation,
    AppStrings.symptomEarPain,
    AppStrings.symptomToothache,
    AppStrings.symptomHighBP,
    AppStrings.symptomDiabetes,
  ];

  int _lastResultCount = 0;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _fadeAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  void _onResultsChanged(List<dynamic> results) {
    if (results.isNotEmpty && _lastResultCount == 0) {
      _slideCtrl.forward(from: 0);
    } else if (results.isEmpty) {
      _slideCtrl.reverse();
    }
    _lastResultCount = results.length;
  }

  @override
  Widget build(BuildContext context) {
    final tr = TranslationService.instance.tr;
    final checker = context.watch<SymptomCheckerProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Trigger animation whenever result count changes
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => _onResultsChanged(checker.results));

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(AppStrings.checkerTitle)),
        actions: [
          if (checker.hasSelections)
            TextButton(
              onPressed: () => context.read<SymptomCheckerProvider>().clearAll(),
              child: Text(tr(AppStrings.checkerClearAll),
                  style: const TextStyle(color: AppColors.primaryBlueDark)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Mode selector
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppDimensions.pagePadding,
                AppDimensions.spaceMD,
                AppDimensions.pagePadding,
                0),
            child: SegmentedButton<SymptomMode>(
              segments: [
                ButtonSegment(
                  value: SymptomMode.allMedicines,
                  label: Text(tr(AppStrings.checkerModeAll)),
                  icon: const Icon(Icons.search),
                ),
                ButtonSegment(
                  value: SymptomMode.myMedicines,
                  label: Text(tr(AppStrings.checkerModeMyMedicines)),
                  icon: const Icon(Icons.home_outlined),
                ),
              ],
              selected: {checker.mode},
              onSelectionChanged: (s) =>
                  context.read<SymptomCheckerProvider>().setMode(s.first),
            ),
          ),

          // Selection count
          if (checker.hasSelections)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.pagePadding,
                  vertical: AppDimensions.spaceSM),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      size: AppDimensions.iconSM,
                      color: AppColors.primaryBlue),
                  const SizedBox(width: AppDimensions.spaceXS),
                  Text(
                    '${checker.selectionCount} ${tr(AppStrings.checkerSymptomsSelected)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),

          // Symptom chips
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.pagePadding),
            child: Wrap(
              spacing: AppDimensions.symptomChipSpacing,
              runSpacing: AppDimensions.symptomChipRunSpacing,
              children: _symptoms.map((key) {
                final label = tr(key);
                final selected = checker.selectedSymptoms.contains(label);
                return FilterChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) => context
                      .read<SymptomCheckerProvider>()
                      .toggleSymptom(label),
                  selectedColor:
                      isDark ? AppColors.chipGreenTintDark : AppColors.chipGreenTint,
                  checkmarkColor: AppColors.chipGreen,
                  labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: selected ? AppColors.chipGreen : null,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                  side: BorderSide(
                    color: selected
                        ? AppColors.chipGreen
                        : (isDark
                            ? AppColors.dividerDark
                            : AppColors.dividerLight),
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: AppDimensions.spaceLG),

          // Results
          Expanded(
            child: checker.isSearching
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: AppDimensions.spaceMD),
                        Text(tr(AppStrings.checkerSearching)),
                      ],
                    ),
                  )
                : !checker.hasSelections
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.health_and_safety_outlined,
                                size: AppDimensions.iconXXL,
                                color: isDark
                                    ? AppColors.textHintDark
                                    : AppColors.textHintLight),
                            const SizedBox(height: AppDimensions.spaceMD),
                            Text(tr(AppStrings.checkerSelectSymptoms),
                                style:
                                    Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: AppDimensions.spaceSM),
                            Text(tr(AppStrings.checkerDesc),
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center),
                          ],
                        ),
                      )
                    : checker.results.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off,
                                    size: AppDimensions.iconXXL,
                                    color: isDark
                                        ? AppColors.textHintDark
                                        : AppColors.textHintLight),
                                const SizedBox(height: AppDimensions.spaceMD),
                                Text(tr(AppStrings.checkerNoResults),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall),
                                const SizedBox(height: AppDimensions.spaceSM),
                                Text(
                                  checker.mode == SymptomMode.myMedicines
                                      ? tr(AppStrings.checkerNoMedicinesInHome)
                                      : tr(AppStrings.checkerNoResultsDesc),
                                  style:
                                      Theme.of(context).textTheme.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : SlideTransition(
                            position: _slideAnim,
                            child: FadeTransition(
                              opacity: _fadeAnim,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(
                                    AppDimensions.pagePadding),
                                itemCount: checker.results.length,
                                itemBuilder: (ctx, i) {
                                  final r = checker.results[i];
                                  return MedicineResultCard(
                                    result: r,
                                    onViewDetails: () =>
                                        _viewDetails(ctx, r),
                                    onAskAI: () => _askAI(ctx, r),
                                  );
                                },
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  void _viewDetails(BuildContext ctx, dynamic r) {
    ctx.read<ScanProvider>().setManualMedicine(r.medicine);
    Navigator.pushNamed(ctx, '/results', arguments: {'isInfoMode': true});
  }

  void _askAI(BuildContext ctx, dynamic r) {
    final lang = ctx.read<LanguageProvider>();
    ctx.read<ChatProvider>().initWithContext(r.medicine,
        languageCode: lang.languageCode);
    Navigator.pushNamed(ctx, '/chat');
  }
}
