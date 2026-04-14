import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
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
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      // Listen for async camera errors (e.g. hardware onError after init)
      ctrl.addListener(_onCameraValue);
      setState(() {
        _camCtrl = ctrl;
        _camReady = true;
      });
    } catch (_) {
      // Camera unavailable — fall back to black background + image_picker
    }
  }

  void _onCameraValue() {
    if (_camCtrl != null && _camCtrl!.value.hasError) {
      // Camera hardware error — release and fall back to image_picker
      final ctrl = _camCtrl;
      setState(() {
        _camCtrl = null;
        _camReady = false;
      });
      ctrl?.dispose();
    }
  }

  /// Releases the camera BEFORE navigating so it doesn't keep running
  /// throughout the OCR + Gemini pipeline (was causing onError in logs).
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

    // Capture directly from controller if available
    if (_camReady && _camCtrl != null) {
      try {
        final file = await _camCtrl!.takePicture();
        await _releaseCamera(); // Free camera BEFORE pushing processing screen
        if (!mounted) return;
        Navigator.pushNamed(context, '/processing', arguments: file.path);
        return;
      } catch (_) {
        // Hardware error — release and fall through to image_picker
        await _releaseCamera();
      }
    }

    // Fallback: open system camera via image_picker
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (mounted) setState(() => _capturing = false);
    if (file == null || !mounted) return;
    Navigator.pushNamed(context, '/processing', arguments: file.path);
  }

  Future<void> _pickFromGallery() async {
    if (_capturing) return;
    setState(() => _capturing = true);

    await _releaseCamera(); // Release camera while gallery picker is open
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (mounted) setState(() => _capturing = false);
    if (file == null || !mounted) return;
    Navigator.pushNamed(context, '/processing', arguments: file.path);
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Live camera preview or black fallback
          if (_camReady && _camCtrl != null)
            ClipRect(child: CameraPreview(_camCtrl!))
          else
            Container(color: AppColors.black),

          // Animated corner brackets overlay
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => CustomPaint(
              painter: ScanOverlayPainter(animationValue: _pulse.value),
              child: const SizedBox.expand(),
            ),
          ),

          // Hint text
          Positioned(
            bottom: 200,
            left: 0,
            right: 0,
            child: Text(
              tr(AppStrings.scannerHint),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.white, fontSize: 14),
            ),
          ),

          // Tip below hint
          Positioned(
            bottom: 175,
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

          // Bottom controls: gallery | camera shutter | (spacer)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ControlButton(
                  icon: Icons.photo_library_outlined,
                  label: tr(AppStrings.galleryButton),
                  isDark: isDark,
                  onPressed: _capturing ? null : _pickFromGallery,
                ),

                // Camera shutter button
                GestureDetector(
                  onTap: _capturing ? null : _takePhoto,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 3),
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

                const SizedBox(width: 80),
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
        // Override global theme's Size(double.infinity, 48) which causes
        // BoxConstraints crash when this button is inside a Row.
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}
