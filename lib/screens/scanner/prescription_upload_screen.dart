import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_strings.dart';
import '../../services/prescription_service.dart';
import '../../services/translation_service.dart';
import '../../widgets/animated_cards.dart';

class PrescriptionUploadScreen extends StatefulWidget {
  final String? initialImagePath;

  const PrescriptionUploadScreen({super.key, this.initialImagePath});

  @override
  State<PrescriptionUploadScreen> createState() => _PrescriptionUploadScreenState();
}

class _PrescriptionUploadScreenState extends State<PrescriptionUploadScreen>
  with TickerProviderStateMixin, WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  late TabController _tabCtrl;
  CameraController? _camCtrl;
  bool _camReady = false;
  bool _cameraPermissionDenied = false;
  String _cameraStatusMessage = 'Starting camera preview...';
  bool _capturing = false;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initializeCamera();
    });
    if (widget.initialImagePath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await Navigator.pushNamed(
          context,
          '/prescription-processing',
          arguments: widget.initialImagePath!,
        );
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camCtrl?.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    } else if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      // Release camera when app not active
      if (_camCtrl != null && _camCtrl!.value.isInitialized) {
        _camCtrl?.dispose();
        _camCtrl = null;
        _camReady = false;
      }
    }
  }

  Future<void> _initializeCamera() async {
    final oldCtrl = _camCtrl;
    if (oldCtrl != null) {
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
      final camera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _camCtrl = CameraController(camera, ResolutionPreset.medium);
      await _camCtrl!.initialize();
      if (mounted) {
        setState(() {
          _camReady = true;
          _cameraPermissionDenied = false;
          _cameraStatusMessage = '';
        });
      }
    } on CameraException catch (e) {
      debugPrint('Camera init failed: ${e.code} ${e.description}');
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
      debugPrint('Camera init failed: $e');
      if (mounted) {
        setState(() {
          _camReady = false;
          _cameraPermissionDenied = false;
          _cameraStatusMessage = 'Unable to start camera preview.';
        });
      }
    }
  }

  Future<void> _takePhoto() async {
    if (_capturing) return;
    try {
      setState(() => _capturing = true);

      if (!_camReady || _camCtrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera preview is not ready yet.')),
          );
        }
        await _initializeCamera();
        return;
      }

      final image = await _camCtrl!.takePicture();
      if (mounted) {
        setState(() => _capturing = false);
      }
      if (!mounted) return;
      await Navigator.pushNamed(
        context,
        '/prescription-processing',
        arguments: image.path,
      );
    } catch (e) {
      debugPrint('Take photo failed: $e');
      if (mounted) setState(() => _isAnalyzing = false);
      await _initializeCamera();
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 95);
    if (file == null || !mounted) return;
    await Navigator.pushNamed(
      context,
      '/prescription-processing',
      arguments: file.path,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = TranslationService.instance.tr;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(AppStrings.prescriptionTitle)),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(
              icon: Icon(Icons.camera_alt),
              text: 'Camera',
            ),
            Tab(
              icon: Icon(Icons.photo_library),
              text: 'Gallery',
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabCtrl,
            children: [
              // ── CAMERA TAB ──────────────────────────────────────────────
              _buildCameraTab(context, tr, isDark),
              // ── GALLERY TAB ──────────────────────────────────────────────
              _buildGalleryTab(context, tr),
            ],
          ),
          if (_isAnalyzing || _capturing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.75),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 34,
                        height: 34,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceMD),
                      Text(
                        _isAnalyzing ? 'Analyzing prescription...' : 'Capturing image...',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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

  Widget _buildCameraTab(BuildContext context, Function tr, bool isDark) {
    final iconColor = isDark ? AppColors.accentOrange : AppColors.primaryBlue;
    return Stack(
      children: [
        if (_camReady && _camCtrl != null)
          CameraPreview(_camCtrl!)
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
                    onPressed: _initializeCamera,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        // Hint text
        Positioned(
          top: 30,
          left: 0,
          right: 0,
          child: Text(
            'Point at the prescription',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
        ),
        // Capture button with label
        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeSlideIn(
                delay: Duration.zero,
                child: GestureDetector(
                  onTap: (_isAnalyzing || _capturing) ? null : () {
                    debugPrint('Camera button tapped');
                    _takePhoto();
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: iconColor,
                        width: 4,
                      ),
                      color: _isAnalyzing
                          ? iconColor.withValues(alpha: 0.1)
                          : AppColors.white.withValues(alpha: 0.2),
                      boxShadow: [
                        BoxShadow(
                          color: iconColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                        child: (_isAnalyzing || _capturing)
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  iconColor,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.camera_alt,
                              color: iconColor,
                              size: 40,
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _isAnalyzing ? 'Analyzing...' : 'Tap to capture',
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGalleryTab(BuildContext context, Function tr) {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.pagePadding),
      children: [
        FadeInCard(
          delay: Duration.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(AppStrings.prescriptionSubtitle),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppDimensions.spaceMD),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _pickFromGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(tr(AppStrings.pickFromGallery)),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceSM),
              Text(
                'Scanned prescription medicines will open in a separate results screen.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
