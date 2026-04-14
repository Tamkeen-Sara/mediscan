import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_strings.dart';
import '../../providers/scan_provider.dart';
import '../../services/translation_service.dart';

class ScanFailedScreen extends StatelessWidget {
  const ScanFailedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = TranslationService.instance.tr;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.sectionPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: AppDimensions.logoSizeLG,
                height: AppDimensions.logoSizeLG,
                decoration: BoxDecoration(
                  color: AppColors.statusRedTintDark,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.statusRed, width: 2),
                ),
                child: const Icon(Icons.error_outline,
                    size: AppDimensions.iconXXL,
                    color: AppColors.statusRed),
              ),
              const SizedBox(height: AppDimensions.spaceXL),
              Text(
                tr(AppStrings.scanFailedTitle),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spaceMD),
              Text(
                tr(AppStrings.scanFailedDesc),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondaryDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spaceXXL),
              // Retake
              SizedBox(
                width: double.infinity,
                height: AppDimensions.buttonHeightLG,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(tr(AppStrings.retakeScan)),
                  onPressed: () {
                    context.read<ScanProvider>().reset();
                    Navigator.popUntil(context, (r) => r.isFirst || r.settings.name == '/home');
                  },
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMD),
              // Gallery
              SizedBox(
                width: double.infinity,
                height: AppDimensions.buttonHeightLG,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.white,
                      side: const BorderSide(color: AppColors.white)),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(tr(AppStrings.chooseFromGallery)),
                  onPressed: () async {
                    final picker = ImagePicker();
                    final file =
                        await picker.pickImage(source: ImageSource.gallery);
                    if (file == null || !context.mounted) return;
                    Navigator.pushReplacementNamed(
                      context,
                      '/processing',
                      arguments: file.path,
                    );
                  },
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMD),
              // Manual entry
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/manual-edit'),
                child: Text(tr(AppStrings.enterManually),
                    style: const TextStyle(color: AppColors.primaryBlueDark)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
