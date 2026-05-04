import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_strings.dart';
import '../../providers/preferences_provider.dart';
import '../../providers/scan_provider.dart';
import '../../services/translation_service.dart';

class ProcessingScreen extends StatefulWidget {
  /// Null when the scan was triggered from manual text entry (no camera image).
  final String? imagePath;
  const ProcessingScreen({super.key, this.imagePath});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanCtrl;

  static const _steps = [
    AppStrings.extractingText,
    AppStrings.identifyingMedicine,
    AppStrings.fetchingInfo,
    AppStrings.generatingSummary,
    AppStrings.almostDone,
  ];

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
        vsync: this,
        duration: const Duration(
            milliseconds: AppDimensions.scanLineDuration));
    _scanCtrl.repeat();
    _start();
  }

  Future<void> _start() async {
    try {
      final provider = context.read<ScanProvider>();
      final autoSummarise =
          context.read<PreferencesProvider>().autoSummarise;
      // Manual-text scans have no image path — ScanProvider already has
      // processManualText() running; here we only call processImage when
      // a real file path was passed.
      if (widget.imagePath != null) {
        await provider.processImage(widget.imagePath!,
            autoSummarise: autoSummarise);
      } else {
        // Wait for the provider to finish processing (started by scanner screen)
        while (provider.phase == ScanPhase.processing) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
      if (!mounted) return;

      final phase = provider.phase;
      if (phase == ScanPhase.failed) {
        Navigator.pushReplacementNamed(context, '/scan-failed');
      } else if (phase == ScanPhase.result) {
        final result = provider.result;
        if (result != null && result.isMediumConfidence) {
          Navigator.pushReplacementNamed(context, '/confidence');
        } else {
          Navigator.pushReplacementNamed(context, '/results');
        }
      } else {
        // Unexpected state — treat as failed rather than staying stuck
        Navigator.pushReplacementNamed(context, '/scan-failed');
      }
    } catch (_) {
      if (mounted) Navigator.pushReplacementNamed(context, '/scan-failed');
    }
  }

  Widget _placeholder() => Container(
        width: 260,
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevatedDark,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        ),
        child: const Icon(Icons.text_fields,
            size: AppDimensions.iconXXL, color: AppColors.textHintDark),
      );

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = TranslationService.instance.tr;
    final stepKey = context.select<ScanProvider, String>(
        (p) => p.processingStep.isEmpty ? _steps[0] : p.processingStep);

    return PopScope(
      // Allow back navigation — user can cancel if something feels stuck
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) context.read<ScanProvider>().reset();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundDark,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.white),
            tooltip: tr(AppStrings.cancel),
            onPressed: () {
              context.read<ScanProvider>().reset();
              Navigator.pop(context);
            },
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.sectionPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Medicine image with scan line
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMD),
                        child: widget.imagePath != null
                            ? Image.file(
                                File(widget.imagePath!),
                                width: 260,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _placeholder(),
                              )
                            : _placeholder(),
                      ),
                      // Animated scan line
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
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppDimensions.spaceMD),
                  // Step indicators
                  ..._steps.map((step) {
                    final isCurrent = stepKey == step;
                    final stepIndex = _steps.indexOf(step);
                    final currentIndex = _steps.indexOf(stepKey);
                    final isDone = stepIndex < currentIndex;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.spaceXS),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(
                                milliseconds: AppDimensions.animNormal),
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
                                ? const Icon(Icons.check,
                                    size: 12, color: AppColors.white)
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
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: isDone
                                      ? AppColors.statusGreen
                                      : isCurrent
                                          ? AppColors.white
                                          : AppColors.textHintDark,
                                  fontWeight: isCurrent
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
