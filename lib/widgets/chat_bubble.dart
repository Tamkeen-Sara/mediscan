import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../models/chat_message.dart';
import '../services/translation_service.dart';
import '../constants/app_strings.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = message.isUser;

    final bgColor = isUser
        ? AppColors.primaryBlue
        : (isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight);

    final textColor = isUser
        ? AppColors.textOnPrimary
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);

    final maxWidth = MediaQuery.of(context).size.width *
        AppDimensions.bubbleMaxWidthFraction;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (message.isTemplateResponse)
            Padding(
              padding: const EdgeInsets.only(
                  left: AppDimensions.spaceSM,
                  bottom: AppDimensions.spaceXXS),
              child: Text(
                TranslationService.instance.tr(AppStrings.chatTemplateLabel),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.textHintDark
                        : AppColors.textHintLight),
              ),
            ),
          Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.bubblePaddingH,
              vertical: AppDimensions.bubblePaddingV,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppDimensions.radiusMD),
                topRight: const Radius.circular(AppDimensions.radiusMD),
                bottomLeft: isUser
                    ? const Radius.circular(AppDimensions.radiusMD)
                    : const Radius.circular(AppDimensions.radiusXS),
                bottomRight: isUser
                    ? const Radius.circular(AppDimensions.radiusXS)
                    : const Radius.circular(AppDimensions.radiusMD),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? AppColors.shadowDark
                      : AppColors.shadowLight,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message.text,
              style:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(color: textColor),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
                top: AppDimensions.spaceXXS,
                left: AppDimensions.spaceSM,
                right: AppDimensions.spaceSM),
            child: Text(
              _formatTime(message.timestamp),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.textHintDark
                        : AppColors.textHintLight,
                    fontSize: 10,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
