import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_strings.dart';
import '../../services/translation_service.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = TranslationService.instance.tr;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(tr(AppStrings.aboutTitle))),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.pagePadding),
        children: [
          Center(
            child: Container(
              width: AppDimensions.logoSizeLG,
              height: AppDimensions.logoSizeLG,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.infoBlueTintDark
                    : AppColors.primaryBlueLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusXXL),
              ),
              child: const Icon(Icons.document_scanner,
                  size: AppDimensions.iconXXL, color: AppColors.primaryBlue),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          Center(
            child: Text(tr(AppStrings.appName),
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Center(
            child: Text('${tr(AppStrings.aboutVersion)} 1.0.0',
                style: Theme.of(context).textTheme.bodySmall),
          ),
          const SizedBox(height: AppDimensions.spaceLG),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.cardPadding),
              child: Text(tr(AppStrings.aboutDesc)),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr(AppStrings.aboutDeveloper),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppDimensions.spaceSM),
                  Text(tr(AppStrings.aboutDisclaimer),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          )),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          ListTile(
            leading: const Icon(Icons.description_outlined,
                color: AppColors.primaryBlue),
            title: Text(tr(AppStrings.aboutLicenses)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLicensePage(
              context: context,
              applicationName: tr(AppStrings.appName),
              applicationVersion: '1.0.0',
            ),
          ),
        ],
      ),
    );
  }
}
