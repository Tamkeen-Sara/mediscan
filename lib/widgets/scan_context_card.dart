import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../services/translation_service.dart';
import '../constants/app_strings.dart';

class ScanContextCard extends StatelessWidget {
  final String medicineName;
  final String genericName;
  final String? category;

  const ScanContextCard({
    super.key,
    required this.medicineName,
    required this.genericName,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePadding),
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.accentOrange,
          width: 1.5,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        color: isDark
            ? AppColors.accentOrangeTintDark
            : AppColors.accentOrangeTint,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medication_outlined,
                  size: AppDimensions.iconSM, color: AppColors.accentOrange),
              const SizedBox(width: AppDimensions.spaceSM),
              Expanded(
                child: Text(
                  medicineName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.accentOrange,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (genericName.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spaceXS),
            Text(
              '${TranslationService.instance.tr(AppStrings.genericName)}: $genericName',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (category != null && category!.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spaceXXS),
            Text(
              '${TranslationService.instance.tr(AppStrings.category)}: $category',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
