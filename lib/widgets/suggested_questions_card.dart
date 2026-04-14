import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../services/translation_service.dart';
import '../constants/app_strings.dart';

class SuggestedQuestionsCard extends StatelessWidget {
  final List<String> questions;
  final bool isLoading;
  final ValueChanged<String>? onQuestionTap;

  const SuggestedQuestionsCard({
    super.key,
    required this.questions,
    this.isLoading = false,
    this.onQuestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        isDark ? AppColors.aiPurpleTintDark : AppColors.aiPurpleTint;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(
            color: AppColors.aiPurple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline,
                  size: AppDimensions.iconSM, color: AppColors.aiPurple),
              const SizedBox(width: AppDimensions.spaceSM),
              Text(
                TranslationService.instance.tr(AppStrings.questionsTitle),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.aiPurple,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          if (isLoading)
            Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(AppDimensions.spaceMD),
                child: Text(
                  TranslationService.instance
                      .tr(AppStrings.questionsLoading),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            )
          else
            ...questions.map((q) => InkWell(
                  onTap: () => onQuestionTap?.call(q),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSM),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.spaceSM),
                    child: Row(
                      children: [
                        const Icon(Icons.chevron_right,
                            size: AppDimensions.iconSM,
                            color: AppColors.aiPurple),
                        const SizedBox(width: AppDimensions.spaceSM),
                        Expanded(
                          child: Text(q,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium),
                        ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}
