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
import '../../widgets/animated_cards.dart';
import '../../widgets/scan_overlay_painter.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
  with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  CameraController? _camCtrl;
  bool _camReady = false;
  bool _capturing = false;
  bool _cameraPermissionDenied = false;
  String _cameraStatusMessage = 'Starting camera preview...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _pulse = Tween(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _pulseCtrl.repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initCamera();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camCtrl?.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _initCamera();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _releaseCamera();
    }
  }

  Future<void> _initCamera() async {
    final oldCtrl = _camCtrl;
    if (oldCtrl != null) {
      oldCtrl.removeListener(_onCameraValue);
      await oldCtrl.dispose();
      _camCtrl = null;
    }

    if (mounted) {
      setState(() {
        _camReady = false;
        _cameraPermissionDenied = false;
        _cameraStatusMessage = 'Starting camera preview...';
      });
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _cameraStatusMessage = 'No camera available on this device.';
          });
        }
        return;
      }
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final ctrl = CameraController(
        backCamera,
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
        _cameraPermissionDenied = false;
        _cameraStatusMessage = '';
      });
    } on CameraException catch (e) {
      debugPrint('Scanner camera init failed: ${e.code} ${e.description}');
      final denied = e.code.toLowerCase().contains('accessdenied');
      if (mounted) {
        setState(() {
          _camReady = false;
          _cameraPermissionDenied = denied;
          _cameraStatusMessage = denied
              ? 'Camera permission required'
              : 'Unable to start camera preview.';
        });
      }
    } catch (e) {
      debugPrint('Scanner camera init failed: $e');
      if (mounted) {
        setState(() {
          _camReady = false;
          _cameraPermissionDenied = false;
          _cameraStatusMessage = 'Unable to start camera preview.';
        });
      }
    }
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

  Future<void> _takePhoto() async {
    if (_capturing) return;
    setState(() => _capturing = true);

    if (!_camReady || _camCtrl == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera preview is not ready yet.')),
        );
      }
      await _initCamera();
      if (mounted) setState(() => _capturing = false);
      return;
    }

    try {
      final file = await _camCtrl!.takePicture();
      await _releaseCamera();
      if (!mounted) return;
      await Navigator.pushNamed(context, '/processing', arguments: file.path);
      if (mounted) {
        setState(() => _capturing = false);
        _initCamera();
      }
    } catch (_) {
      await _releaseCamera();
      if (mounted) {
        setState(() => _capturing = false);
      }
      await _initCamera();
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
                  Container(
                    color: AppColors.black,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_cameraPermissionDenied)
                            const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          else
                            Icon(
                              Icons.camera_alt_outlined,
                              color: AppColors.white.withValues(alpha: 0.75),
                              size: 40,
                            ),
                          const SizedBox(height: 12),
                          Text(
                            _cameraStatusMessage,
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _initCamera,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),

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
          SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  color: AppColors.black,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: AppDimensions.spaceXS),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 2,
                        child: FadeSlideIn(
                          delay: Duration.zero,
                          child: _ControlButton(
                            icon: Icons.photo_library_outlined,
                            label: tr(AppStrings.galleryButton),
                            isDark: isDark,
                            onPressed: _capturing ? null : _pickFromGallery,
                            compact: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceSM),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 75),
                        child: GestureDetector(
                          onTap: _capturing ? null : _takePhoto,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.white, width: 3),
                              color: _capturing
                                  ? AppColors.white.withValues(alpha: 0.05)
                                  : AppColors.white.withValues(alpha: 0.15),
                            ),
                            child: Center(
                              child: _capturing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: AppColors.white),
                                    )
                                  : const Icon(Icons.camera_alt,
                                      color: AppColors.white, size: 28),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceSM),
                      Expanded(
                        flex: 1,
                        child: FadeSlideIn(
                          delay: const Duration(milliseconds: 150),
                          child: _ControlButton(
                            icon: Icons.keyboard_outlined,
                            label: 'Type',
                            isDark: isDark,
                            onPressed: _capturing ? null : () => _showManualEntry(context),
                            compact: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
  final bool compact;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight,
        foregroundColor: AppColors.primaryBlue,
         padding: EdgeInsets.symmetric(
           horizontal: compact ? 12 : 20,
           vertical: compact ? 10 : 14,
         ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon, size: compact ? 18 : 20),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall,
      ),
      onPressed: onPressed,
    );
  }
}
