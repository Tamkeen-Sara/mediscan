import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../services/gemini_service.dart';
import '../services/translation_service.dart';
import '../constants/app_strings.dart';

class OfflineAiBanner extends StatelessWidget {
  final bool visible;

  const OfflineAiBanner({super.key, required this.visible});

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    // Show a specific message if we know why Gemini failed
    final error = GeminiService.instance.lastError;
    final isApiKeyError = error == GeminiError.apiKeyInvalid;
    final isModelError = error == GeminiError.modelUnavailable;

    final bannerColor = isApiKeyError || isModelError
        ? AppColors.statusRed
        : AppColors.accentOrange;

    final message = isApiKeyError
        ? 'AI key invalid or Gemini API not enabled — check aistudio.google.com'
        : isModelError
            ? 'AI model unavailable — using offline responses'
            : TranslationService.instance.tr(AppStrings.chatOfflineBanner);

    return AnimatedContainer(
      duration: const Duration(milliseconds: AppDimensions.animNormal),
      color: bannerColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.pagePadding,
          vertical: AppDimensions.spaceXS,
        ),
        child: Row(
          children: [
            Icon(
              isApiKeyError || isModelError
                  ? Icons.error_outline
                  : Icons.wifi_off,
              size: AppDimensions.iconSM,
              color: AppColors.textOnPrimary,
            ),
            const SizedBox(width: AppDimensions.spaceSM),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textOnPrimary,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
