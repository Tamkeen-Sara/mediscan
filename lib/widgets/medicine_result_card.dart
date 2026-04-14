import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../services/symptom_match_service.dart';
import '../services/translation_service.dart';
import '../constants/app_strings.dart';
import 'progress_confidence_bar.dart';

class MedicineResultCard extends StatelessWidget {
  final SymptomMatchResult result;
  final VoidCallback? onViewDetails;
  final VoidCallback? onAskAI;

  const MedicineResultCard({
    super.key,
    required this.result,
    this.onViewDetails,
    this.onAskAI,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tr = TranslationService.instance.tr;

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.medicine.displayName,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (result.medicine.genericName.isNotEmpty)
                        Text(result.medicine.genericName,
                            style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                if (result.isInHome)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spaceSM,
                        vertical: AppDimensions.spaceXS),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.statusGreenTintDark
                          : AppColors.statusGreenTint,
                      borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull),
                      border: Border.all(color: AppColors.statusGreen),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.home_outlined,
                            size: AppDimensions.iconXS,
                            color: AppColors.statusGreen),
                        const SizedBox(width: AppDimensions.spaceXXS),
                        Text(
                          tr(AppStrings.checkerInYourHome),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.statusGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceMD),
            // Match score bar
            ProgressConfidenceBar(
              value: result.matchScore,
              label: tr(AppStrings.checkerMatchScore),
            ),
            const SizedBox(height: AppDimensions.spaceSM),
            // Matched symptom chips
            Wrap(
              spacing: AppDimensions.spaceXS,
              runSpacing: AppDimensions.spaceXS,
              children: result.matchedSymptoms
                  .map((s) => Chip(
                        label: Text(s),
                        labelStyle: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AppColors.chipGreen),
                        backgroundColor: isDark
                            ? AppColors.chipGreenTintDark
                            : AppColors.chipGreenTint,
                        side: BorderSide(
                            color: AppColors.chipGreen.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spaceXS),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
            const SizedBox(height: AppDimensions.spaceMD),
            Row(
              children: [
                if (onViewDetails != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onViewDetails,
                      child: Text(tr(AppStrings.checkerViewDetails)),
                    ),
                  ),
                if (onViewDetails != null && onAskAI != null)
                  const SizedBox(width: AppDimensions.spaceSM),
                if (onAskAI != null)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onAskAI,
                      child: Text(tr(AppStrings.checkerAskAI)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
