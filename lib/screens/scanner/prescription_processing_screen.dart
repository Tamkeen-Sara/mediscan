import 'dart:io';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_strings.dart';
import '../../services/prescription_service.dart';
import '../../services/translation_service.dart';
import '../../utils/animation_utils.dart';
import '../../widgets/animated_cards.dart';

class PrescriptionProcessingScreen extends StatefulWidget {
  final String imagePath;

  const PrescriptionProcessingScreen({super.key, required this.imagePath});

  @override
  State<PrescriptionProcessingScreen> createState() => _PrescriptionProcessingScreenState();
}

class _PrescriptionProcessingScreenState extends State<PrescriptionProcessingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanCtrl;

  static const _steps = [
    AppStrings.extractingText,
    AppStrings.identifyingMedicine,
    AppStrings.generatingSummary,
    AppStrings.almostDone,
  ];

  String _stepKey = AppStrings.extractingText;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AppDimensions.scanLineDuration),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _start();
      }
    });
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      setState(() => _stepKey = AppStrings.extractingText);
      final result = await PrescriptionService.instance.analyzePrescriptionImage(widget.imagePath);
      if (!mounted) return;

      setState(() => _stepKey = AppStrings.almostDone);
      await PrescriptionService.instance.saveAnalysisToHistory(
        result,
        imagePath: widget.imagePath,
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/prescription-results',
        arguments: result,
      );
    } catch (e) {
      debugPrint('Prescription processing failed: $e');
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prescription analysis failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = TranslationService.instance.tr;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.white),
          tooltip: tr(AppStrings.cancel),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.sectionPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                      child: Image.file(
                        File(widget.imagePath),
                        width: 260,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 260,
                          height: 200,
                          color: AppColors.surfaceElevatedDark,
                          child: const Icon(Icons.text_fields,
                              size: AppDimensions.iconXXL, color: AppColors.textHintDark),
                        ),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _scanCtrl,
                      builder: (_, __) => Positioned(
                        top: 200 * _scanCtrl.value,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.scanLine.withValues(alpha: 0),
                                AppColors.scanLine,
                                AppColors.scanLine.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceXL),
                Text(
                  tr(AppStrings.processingTitle),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppDimensions.spaceSM),
                Text(
                  'Prescription analysis in progress...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                ),
                const SizedBox(height: AppDimensions.spaceMD),
                StaggeredAnimationBuilder(
                  staggerDelay: const Duration(milliseconds: 90),
                  duration: const Duration(milliseconds: 320),
                  children: _steps.map((step) {
                    final isCurrent = stepKey == step;
                    final stepIndex = _steps.indexOf(step);
                    final currentIndex = _steps.indexOf(stepKey);
                    final isDone = stepIndex < currentIndex;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceXS),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: AppDimensions.animNormal),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDone
                                  ? AppColors.statusGreen
                                  : isCurrent
                                      ? AppColors.primaryBlue
                                      : AppColors.dividerDark,
                            ),
                            child: isDone
                                ? const Icon(Icons.check, size: 12, color: AppColors.white)
                                : isCurrent
                                    ? const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.white,
                                        ),
                                      )
                                    : null,
                          ),
                          const SizedBox(width: AppDimensions.spaceSM),
                          Text(
                            tr(step),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isDone
                                      ? AppColors.statusGreen
                                      : isCurrent
                                          ? AppColors.white
                                          : AppColors.textHintDark,
                                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                                ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get stepKey => _stepKey;
}