import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../models/scan_history_model.dart';

class ConfidenceBadge extends StatelessWidget {
  final ScanStatus status;
  final String? label;

  const ConfidenceBadge({super.key, required this.status, this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _color(isDark);
    final bg = _bg(isDark);
    final text = label ?? _label();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.badgePaddingH,
        vertical: AppDimensions.badgePaddingV,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(), size: AppDimensions.iconXS, color: color),
          const SizedBox(width: AppDimensions.spaceXS),
          Text(
            text,
            style: TextStyle(
              fontSize: AppDimensions.badgeFontSize,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _color(bool isDark) {
    switch (status) {
      case ScanStatus.highConfidence:
        return AppColors.statusGreen;
      case ScanStatus.mediumConfidence:
        return AppColors.statusAmber;
      case ScanStatus.lowConfidence:
      case ScanStatus.failed:
        return AppColors.statusRed;
    }
  }

  Color _bg(bool isDark) {
    switch (status) {
      case ScanStatus.highConfidence:
        return isDark
            ? AppColors.statusGreenTintDark
            : AppColors.statusGreenTint;
      case ScanStatus.mediumConfidence:
        return isDark
            ? AppColors.statusAmberTintDark
            : AppColors.statusAmberTint;
      case ScanStatus.lowConfidence:
      case ScanStatus.failed:
        return isDark ? AppColors.statusRedTintDark : AppColors.statusRedTint;
    }
  }

  IconData _icon() {
    switch (status) {
      case ScanStatus.highConfidence:
        return Icons.check_circle_outline;
      case ScanStatus.mediumConfidence:
        return Icons.info_outline;
      case ScanStatus.lowConfidence:
        return Icons.warning_amber_outlined;
      case ScanStatus.failed:
        return Icons.error_outline;
    }
  }

  String _label() {
    switch (status) {
      case ScanStatus.highConfidence:
        return 'High Confidence';
      case ScanStatus.mediumConfidence:
        return 'Medium Confidence';
      case ScanStatus.lowConfidence:
        return 'Low Confidence';
      case ScanStatus.failed:
        return 'Unidentified';
    }
  }
}
