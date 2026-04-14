import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../services/translation_service.dart';
import '../constants/app_strings.dart';
import '../models/medicine_model.dart';

class DosageCard extends StatelessWidget {
  final MedicineModel medicine;

  const DosageCard({super.key, required this.medicine});

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
            Row(
              children: [
                const Icon(Icons.medication,
                    size: AppDimensions.iconSM,
                    color: AppColors.primaryBlue),
                const SizedBox(width: AppDimensions.spaceSM),
                Text(tr(AppStrings.dosageTitle),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceMD),
            if (medicine.dosageAdults.isNotEmpty)
              _DosageRow(
                  label: tr(AppStrings.adultsLabel),
                  value: medicine.dosageAdults,
                  isDark: isDark),
            if (medicine.dosageChildren.isNotEmpty)
              _DosageRow(
                  label: tr(AppStrings.childrenLabel),
                  value: medicine.dosageChildren,
                  isDark: isDark),
            if (medicine.maxDailyDose.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.spaceSM),
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceSM),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.accentOrangeTintDark
                      : AppColors.accentOrangeTint,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSM),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_outlined,
                        size: AppDimensions.iconSM,
                        color: AppColors.accentOrange),
                    const SizedBox(width: AppDimensions.spaceSM),
                    Expanded(
                      child: Text(
                        '${tr(AppStrings.maxDailyLabel)}: ${medicine.maxDailyDose}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.accentOrange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (medicine.importantNote.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.spaceSM),
              Text(
                '${tr(AppStrings.importantNoteLabel)}: ${medicine.importantNote}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DosageRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _DosageRow(
      {required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceSM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
            ),
          ),
          Expanded(
            child: Text(value,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
