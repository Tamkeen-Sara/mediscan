import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_strings.dart';
import '../../models/scan_history_model.dart';
import '../../providers/scan_provider.dart';
import '../../services/translation_service.dart';
import '../../widgets/confidence_badge.dart';
import '../../widgets/progress_confidence_bar.dart';

class ConfidenceScreen extends StatelessWidget {
  const ConfidenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = TranslationService.instance.tr;
    final scan = context.watch<ScanProvider>();
    final result = scan.result;

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: Text(tr(AppStrings.confidenceTitle))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = result.scanStatus;

    Color headerBg() {
      if (isDark) {
        return status == ScanStatus.highConfidence
            ? AppColors.statusGreenTintDark
            : status == ScanStatus.mediumConfidence
                ? AppColors.statusAmberTintDark
                : AppColors.statusRedTintDark;
      }
      return status == ScanStatus.highConfidence
          ? AppColors.statusGreenTint
          : status == ScanStatus.mediumConfidence
              ? AppColors.statusAmberTint
              : AppColors.statusRedTint;
    }

    return Scaffold(
      appBar: AppBar(title: Text(tr(AppStrings.confidenceTitle))),
      body: Column(
        children: [
          // Score header
          Container(
            width: double.infinity,
            color: headerBg(),
            padding: const EdgeInsets.all(AppDimensions.sectionPadding),
            child: Column(
              children: [
                Text(
                  result.medicine.displayName,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.spaceMD),
                ConfidenceBadge(status: status),
                const SizedBox(height: AppDimensions.spaceSM),
                Text(
                  '${result.confidencePercent}% ${tr(AppStrings.overallScore)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          // Breakdown bars
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppDimensions.pagePadding),
              children: [
                const SizedBox(height: AppDimensions.spaceMD),
                ProgressConfidenceBar(
                  value: result.overallScore,
                  label: tr(AppStrings.overallScore),
                  large: true,
                ),
                const SizedBox(height: AppDimensions.spaceMD),
                ProgressConfidenceBar(
                  value: result.nameScore,
                  label: tr(AppStrings.nameScore),
                ),
                const SizedBox(height: AppDimensions.spaceSM),
                ProgressConfidenceBar(
                  value: result.dosageScore,
                  label: tr(AppStrings.dosageScore),
                ),
                const SizedBox(height: AppDimensions.spaceSM),
                ProgressConfidenceBar(
                  value: result.brandScore,
                  label: tr(AppStrings.brandScore),
                ),
                const SizedBox(height: AppDimensions.spaceXXL),
                // Actions
                SizedBox(
                  width: double.infinity,
                  height: AppDimensions.buttonHeightLG,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(
                        context, '/results'),
                    child: Text(tr(AppStrings.proceedAnyway)),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceSM),
                SizedBox(
                  width: double.infinity,
                  height: AppDimensions.buttonHeightLG,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushReplacementNamed(
                        context, '/manual-edit'),
                    child: Text(tr(AppStrings.editButton)),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceSM),
                TextButton(
                  onPressed: () {
                    context.read<ScanProvider>().reset();
                    Navigator.popUntil(
                        context, (r) => r.settings.name == '/home' || r.isFirst);
                  },
                  child: Text(tr(AppStrings.retakeScan)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
