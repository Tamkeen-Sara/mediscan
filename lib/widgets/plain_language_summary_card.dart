import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../services/translation_service.dart';
import '../constants/app_strings.dart';

class PlainLanguageSummaryCard extends StatelessWidget {
  final String? summary;
  final bool isLoading;

  const PlainLanguageSummaryCard({
    super.key,
    this.summary,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        isDark ? AppColors.infoBlueTintDark : AppColors.infoBlueTint;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  size: AppDimensions.iconSM,
                  color: AppColors.primaryBlue),
              const SizedBox(width: AppDimensions.spaceSM),
              Text(
                TranslationService.instance.tr(AppStrings.summaryTitle),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          if (isLoading)
            _ShimmerLines(isDark: isDark)
          else
            Text(
              summary?.isNotEmpty == true
                  ? summary!
                  : TranslationService.instance
                      .tr(AppStrings.summaryLoading),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }
}

class _ShimmerLines extends StatefulWidget {
  final bool isDark;
  const _ShimmerLines({required this.isDark});

  @override
  State<_ShimmerLines> createState() => _ShimmerLinesState();
}

class _ShimmerLinesState extends State<_ShimmerLines>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200));
    _anim = Tween(begin: -1.0, end: 2.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Column(
        children: [0.9, 1.0, 0.7].map((frac) {
          return Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.spaceSM),
            height: AppDimensions.shimmerLineHeight,
            width: double.infinity * frac,
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(AppDimensions.shimmerRadius),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: [
                  (_anim.value - 1).clamp(0.0, 1.0),
                  _anim.value.clamp(0.0, 1.0),
                  (_anim.value + 1).clamp(0.0, 1.0),
                ],
                colors: widget.isDark
                    ? [
                        AppColors.shimmerBaseDark,
                        AppColors.shimmerHighlightDark,
                        AppColors.shimmerBaseDark,
                      ]
                    : [
                        AppColors.shimmerBaseLight,
                        AppColors.shimmerHighlightLight,
                        AppColors.shimmerBaseLight,
                      ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
