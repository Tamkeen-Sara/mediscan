import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class SymptomChipsRow extends StatelessWidget {
  final List<String> symptoms;
  /// Called with the tapped symptom label. If null, chips still show a SnackBar
  /// but do nothing else.
  final void Function(String symptom)? onChipTap;

  const SymptomChipsRow({
    super.key,
    required this.symptoms,
    this.onChipTap,
  });

  @override
  Widget build(BuildContext context) {
    if (symptoms.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: AppDimensions.symptomChipSpacing,
      runSpacing: AppDimensions.symptomChipRunSpacing,
      children: symptoms.map((symptom) {
        return GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Used for: $symptom'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                action: onChipTap != null
                    ? SnackBarAction(
                        label: 'Check',
                        onPressed: () => onChipTap!(symptom),
                      )
                    : null,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.chipPaddingH,
              vertical: AppDimensions.chipPaddingV,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.chipGreenTintDark
                  : AppColors.chipGreenTint,
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusFull),
              border:
                  Border.all(color: AppColors.chipGreen.withValues(alpha: 0.5)),
            ),
            child: Text(
              symptom,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.chipGreen,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
