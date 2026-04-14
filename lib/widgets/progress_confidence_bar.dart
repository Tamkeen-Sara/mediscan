import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class ProgressConfidenceBar extends StatelessWidget {
  final double value; // 0.0 – 1.0
  final String? label;
  final bool large;

  const ProgressConfidenceBar({
    super.key,
    required this.value,
    this.label,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _barColor();
    final height = large
        ? AppDimensions.progressBarHeightLG
        : AppDimensions.progressBarHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label!,
                  style: Theme.of(context).textTheme.bodySmall),
              Text('${(value * 100).round()}%',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceXS),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: height,
            backgroundColor: AppColors.dividerLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Color _barColor() {
    if (value >= 0.80) return AppColors.statusGreen;
    if (value >= 0.50) return AppColors.statusAmber;
    return AppColors.statusRed;
  }
}
