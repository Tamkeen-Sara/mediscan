import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class InfoRow {
  final String label;
  final String value;
  final IconData? icon;

  const InfoRow({required this.label, required this.value, this.icon});
}

class MediInfoCard extends StatelessWidget {
  final String title;
  final List<InfoRow> rows;
  final IconData? titleIcon;
  final Color? accentColor;

  const MediInfoCard({
    super.key,
    required this.title,
    required this.rows,
    this.titleIcon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = accentColor ?? AppColors.primaryBlue;

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (titleIcon != null) ...[
                  Icon(titleIcon, size: AppDimensions.iconSM, color: accent),
                  const SizedBox(width: AppDimensions.spaceSM),
                ],
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(
                            color: accent, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceMD),
            ...rows.map((row) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppDimensions.spaceSM),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          row.label,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight),
                        ),
                      ),
                      Expanded(
                        child: Text(row.value,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
