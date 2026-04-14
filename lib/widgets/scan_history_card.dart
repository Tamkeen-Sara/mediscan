import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../models/scan_history_model.dart';
import '../services/translation_service.dart';
import '../constants/app_strings.dart';
import 'confidence_badge.dart';

class ScanHistoryCard extends StatelessWidget {
  final ScanHistoryModel item;
  final VoidCallback? onTap;
  final VoidCallback? onFavourite;
  final VoidCallback? onDelete;

  const ScanHistoryCard({
    super.key,
    required this.item,
    this.onTap,
    this.onFavourite,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tr = TranslationService.instance.tr;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceSM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.cardPadding),
          child: Row(
            children: [
              // Medicine icon
              Container(
                width: AppDimensions.avatarMD,
                height: AppDimensions.avatarMD,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.infoBlueTintDark
                      : AppColors.infoBlueTint,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSM),
                ),
                child: const Icon(Icons.medication_outlined,
                    size: AppDimensions.iconSM,
                    color: AppColors.primaryBlue),
              ),
              const SizedBox(width: AppDimensions.spaceMD),
              // Name + date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.genericName.isNotEmpty)
                      Text(item.genericName,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    const SizedBox(height: AppDimensions.spaceXS),
                    Text(
                      '${tr(AppStrings.scannedOn)} ${_formatDate(item.scannedAt)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? AppColors.textHintDark
                                : AppColors.textHintLight,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spaceSM),
              // Badge + actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ConfidenceBadge(status: item.status),
                  const SizedBox(height: AppDimensions.spaceXS),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onFavourite != null)
                        GestureDetector(
                          onTap: onFavourite,
                          child: Icon(
                            item.isFavourite
                                ? Icons.star
                                : Icons.star_border,
                            size: AppDimensions.iconSM,
                            color: item.isFavourite
                                ? AppColors.accentOrange
                                : (isDark
                                    ? AppColors.textHintDark
                                    : AppColors.textHintLight),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
