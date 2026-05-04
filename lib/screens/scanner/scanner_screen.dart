import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_strings.dart';
import '../../providers/preferences_provider.dart';
import '../../providers/scan_provider.dart';
import '../../services/translation_service.dart';
import '../../widgets/scan_overlay_painter.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  CameraController? _camCtrl;
  bool _camReady = false;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _pulse = Tween(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _pulseCtrl.repeat(reverse: true);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final ctrl = CameraController(
        cameras.first,
        // medium = 720×480 for preview — enough for live view, far less GPU
        // pressure than high (1280×720) which caused cascading buffer drops.
        ResolutionPreset.medium,
        enableAudio: false,
        // iOS requires bgra8888 for the preview stream; Android uses jpeg.
        // takePicture() always returns JPEG on both platforms regardless.
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.jpeg,
      );
      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      ctrl.addListener(_onCameraValue);
      setState(() {
        _camCtrl = ctrl;
        _camReady = true;
      });
    } catch (_) {}
  }

  void _onCameraValue() {
    if (_camCtrl != null && _camCtrl!.value.hasError) {
      final ctrl = _camCtrl;
      setState(() {
        _camCtrl = null;
        _camReady = false;
      });
      ctrl?.dispose();
    }
  }

  Future<void> _releaseCamera() async {
    final ctrl = _camCtrl;
    if (ctrl != null) {
      ctrl.removeListener(_onCameraValue);
      setState(() {
        _camCtrl = null;
        _camReady = false;
      });
      await ctrl.dispose();
    }
  }

  @override
  void dispose() {
    _camCtrl?.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (_capturing) return;
    setState(() => _capturing = true);

    if (_camReady && _camCtrl != null) {
      try {
        final file = await _camCtrl!.takePicture();
        await _releaseCamera();
        if (!mounted) return;
        await Navigator.pushNamed(context, '/processing', arguments: file.path);
        if (mounted) {
          setState(() => _capturing = false);
          _initCamera();
        }
        return;
      } catch (_) {
        await _releaseCamera();
      }
    }

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (file == null) {
      if (mounted) {
        setState(() => _capturing = false);
        _initCamera();
      }
      return;
    }
    if (!mounted) return;
    await Navigator.pushNamed(context, '/processing', arguments: file.path);
    if (mounted) {
      setState(() => _capturing = false);
      _initCamera();
    }
  }

  Future<void> _showManualEntry(BuildContext ctx) async {
    final scanProvider = ctx.read<ScanProvider>();
    final autoSummarise = ctx.read<PreferencesProvider>().autoSummarise;
    final navigator = Navigator.of(ctx);

    final controller = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(sheetCtx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radiusXL)),
          ),
          padding: const EdgeInsets.fromLTRB(
              AppDimensions.pagePadding,
              AppDimensions.spaceMD,
              AppDimensions.pagePadding,
              AppDimensions.spaceLG),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(sheetCtx).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMD),
              Text(
                TranslationService.instance.tr(AppStrings.scannerTitle),
                style: Theme.of(sheetCtx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppDimensions.spaceXS),
              Text(
                'Type the medicine name or text from the packet',
                style: Theme.of(sheetCtx).textTheme.bodySmall,
              ),
              const SizedBox(height: AppDimensions.spaceMD),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: 'e.g. Panadol 500mg, Augmentin, Metformin…',
                  prefixIcon: Icon(Icons.medication_outlined),
                ),
                onSubmitted: (v) => Navigator.pop(sheetCtx, v.trim()),
              ),
              const SizedBox(height: AppDimensions.spaceMD),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.search),
                  label: const Text('Find Medicine'),
                  onPressed: () =>
                      Navigator.pop(sheetCtx, controller.text.trim()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    controller.dispose();

    if (result == null || result.isEmpty || !mounted) return;
    scanProvider.processManualText(result, autoSummarise: autoSummarise);
    navigator.pushNamed('/processing');
  }

  Future<void> _pickFromGallery() async {
    if (_capturing) return;
    setState(() => _capturing = true);

    await _releaseCamera();
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (file == null) {
      if (mounted) {
        setState(() => _capturing = false);
        _initCamera();
      }
      return;
    }
    if (!mounted) return;
    await Navigator.pushNamed(context, '/processing', arguments: file.path);
    if (mounted) {
      setState(() => _capturing = false);
      _initCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tr = TranslationService.instance.tr;

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: Text(tr(AppStrings.scannerTitle),
            style: const TextStyle(color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: Column(
        children: [
          // ── Camera viewport ──────────────────────────────────────────────
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_camReady && _camCtrl != null)
                  ClipRect(child: CameraPreview(_camCtrl!))
                else
                  Container(color: AppColors.black),

                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => CustomPaint(
                    painter: ScanOverlayPainter(animationValue: _pulse.value),
                    child: const SizedBox.expand(),
                  ),
                ),

                // Hint text
                Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: Text(
                    tr(AppStrings.scannerHint),
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: AppColors.white, fontSize: 14),
                  ),
                ),

                // Tip text
                Positioned(
                  bottom: 56,
                  left: 0,
                  right: 0,
                  child: Text(
                    tr(AppStrings.scanTip),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.6),
                        fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom controls ──────────────────────────────────────────────
          Container(
            color: AppColors.black,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ControlButton(
                  icon: Icons.photo_library_outlined,
                  label: tr(AppStrings.galleryButton),
                  isDark: isDark,
                  onPressed: _capturing ? null : _pickFromGallery,
                ),

                // Shutter
                GestureDetector(
                  onTap: _capturing ? null : _takePhoto,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.white, width: 3),
                      color: _capturing
                          ? AppColors.white.withValues(alpha: 0.05)
                          : AppColors.white.withValues(alpha: 0.15),
                    ),
                    child: _capturing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white),
                            ),
                          )
                        : const Icon(Icons.camera_alt,
                            color: AppColors.white, size: 34),
                  ),
                ),

                _ControlButton(
                  icon: Icons.keyboard_outlined,
                  label: 'Type',
                  isDark: isDark,
                  onPressed: _capturing
                      ? null
                      : () => _showManualEntry(context),
                ),
              ],
            ),
          ),

          // ── "What Do I Have?" symptom checker entry card ─────────────────
          Container(
            color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
            padding: const EdgeInsets.fromLTRB(
                AppDimensions.pagePadding, 0,
                AppDimensions.pagePadding, AppDimensions.spaceMD),
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, '/symptom-checker'),
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusMD),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceMD,
                    vertical: AppDimensions.spaceSM + 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceElevatedDark
                      : AppColors.surfaceLight,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMD),
                  border: const Border(
                    left: BorderSide(
                        color: AppColors.chipGreen, width: 4),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowLight,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr(AppStrings.whatDoIHave),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tr(AppStrings.pointAtMedicine),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceSM),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.chipGreen.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.health_and_safety_outlined,
                        color: AppColors.chipGreen,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback? onPressed;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight,
        foregroundColor: AppColors.primaryBlue,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}
