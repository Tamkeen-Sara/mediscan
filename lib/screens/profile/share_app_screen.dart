import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_strings.dart';
import '../../services/translation_service.dart';

class ShareAppScreen extends StatelessWidget {
  const ShareAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = TranslationService.instance.tr;

    return Scaffold(
      appBar: AppBar(title: Text(tr(AppStrings.shareAppTitle))),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.pagePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: AppDimensions.logoSizeLG / 2,
              backgroundColor: AppColors.primaryBlueLight,
              child: Icon(Icons.share,
                  size: AppDimensions.iconXXL, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: AppDimensions.spaceLG),
            Text(
              tr(AppStrings.shareAppTitle),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spaceMD),
            Text(
              tr(AppStrings.shareAppMessage),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spaceXXL),
            SizedBox(
              width: double.infinity,
              height: AppDimensions.buttonHeightLG,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.share),
                label: Text(tr(AppStrings.shareAppTitle)),
                onPressed: () => Share.share(tr(AppStrings.shareAppMessage)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
