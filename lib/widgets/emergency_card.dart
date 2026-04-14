import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../services/translation_service.dart';
import '../constants/app_strings.dart';

class EmergencyCard extends StatelessWidget {
  const EmergencyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tr = TranslationService.instance.tr;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color:
            isDark ? AppColors.emergencyRedTintDark : AppColors.emergencyRedTint,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(
            color: AppColors.emergencyRed,
            width: AppDimensions.emergencyBorderWidth),
      ),
      child: Row(
        children: [
          const Icon(Icons.emergency,
              color: AppColors.emergencyRed, size: AppDimensions.iconMD),
          const SizedBox(width: AppDimensions.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(AppStrings.emergencyTitle),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.emergencyRed,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppDimensions.spaceXS),
                Text(
                  tr(AppStrings.emergencyDesc),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spaceSM),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergencyRed,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceMD,
                  vertical: AppDimensions.spaceSM),
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSM)),
            ),
            icon: const Icon(Icons.call, size: AppDimensions.iconSM),
            label: Text(tr(AppStrings.emergencyCall)),
            onPressed: () async {
              final uri = Uri.parse('tel:1122');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
          ),
        ],
      ),
    );
  }
}
