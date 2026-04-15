import 'dart:convert';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../shared/widgets/achieva_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';

class FacialVerificationScreen extends StatefulWidget {
  const FacialVerificationScreen({super.key});

  @override
  State<FacialVerificationScreen> createState() =>
      _FacialVerificationScreenState();
}

class _FacialVerificationScreenState extends State<FacialVerificationScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  late AnimationController _pulseController;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _livenessConfirmed = false;
  bool _verificationSuccess = false;
  bool _verificationFailed = false;
  int _blinkCount = 0;
  bool _wasEyeOpen = true;
  String _instruction = AppStrings.faceInstruction;

  @override
  void initState() {
    super.initState();
    _enableScreenSecurity();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _initCamera();
  }

  Future<void> _enableScreenSecurity() async {
    try {
      await ScreenProtector.protectDataLeakageWithColor(Colors.black);
    } catch (_) {}
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
        _startLivenessDetection();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _instruction = 'Camera not available. Please grant camera permission.';
        });
      }
    }
  }

  void _startLivenessDetection() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    _cameraController!.startImageStream((CameraImage image) async {
      if (_isProcessing || _livenessConfirmed) return;
      _isProcessing = true;

      try {
        final inputImage = _convertCameraImage(image);
        if (inputImage == null) {
          _isProcessing = false;
          return;
        }

        final faces = await _faceDetector.processImage(inputImage);
        if (faces.isNotEmpty) {
          final face = faces.first;
          final leftEye = face.leftEyeOpenProbability ?? 1.0;
          final rightEye = face.rightEyeOpenProbability ?? 1.0;

          final eyesOpen = leftEye > 0.5 && rightEye > 0.5;
          final eyesClosed = leftEye < 0.3 && rightEye < 0.3;

          if (_wasEyeOpen && eyesClosed) {
            _blinkCount++;
          }
          _wasEyeOpen = eyesOpen;

          if (_blinkCount >= 2) {
            setState(() {
              _livenessConfirmed = true;
              _instruction = 'Liveness confirmed. Capturing...';
            });
            await _cameraController!.stopImageStream();
            await _captureAndVerify();
          } else {
            if (mounted) {
              setState(() {
                _instruction = 'Please blink naturally (${_blinkCount}/2 blinks detected)';
              });
            }
          }
        }
      } catch (_) {
        // Continue processing
      }

      _isProcessing = false;
    });
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final rotation = InputImageRotationValue.fromRawValue(
        _cameraController!.description.sensorOrientation,
      );
      if (rotation == null) return null;

      final format = InputImageFormatValue.fromRawValue(image.format.raw as int);
      if (format == null) return null;

      final plane = image.planes.first;
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _captureAndVerify() async {
    try {
      final image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      if (!mounted) return;

      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;
      if (token == null) return;

      final success = await context.read<OnboardingProvider>().verifyFace(
            base64Image,
            '',
            token,
          );

      if (!mounted) return;

      if (success) {
        authProvider.setVerified(true);
        setState(() {
          _verificationSuccess = true;
          _instruction = AppStrings.identityConfirmed;
        });
      } else {
        setState(() {
          _verificationFailed = true;
          _instruction = AppStrings.faceVerificationFailed;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _verificationFailed = true;
          _instruction = AppStrings.faceVerificationFailed;
        });
      }
    }
  }

  void _retry() {
    setState(() {
      _livenessConfirmed = false;
      _verificationFailed = false;
      _verificationSuccess = false;
      _blinkCount = 0;
      _wasEyeOpen = true;
      _instruction = AppStrings.faceInstruction;
    });
    _startLivenessDetection();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _pulseController.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.faceStepTitle),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step indicator
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  AppStrings.faceStepIndicator,
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Camera with oval frame
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 280,
                  height: 360,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Camera preview
                      if (_isCameraInitialized && _cameraController != null)
                        ClipOval(
                          child: SizedBox(
                            width: 260,
                            height: 340,
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _cameraController!.value.previewSize!.height,
                                height: _cameraController!.value.previewSize!.width,
                                child: CameraPreview(_cameraController!),
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 260,
                          height: 340,
                          decoration: BoxDecoration(
                            color: AppColors.surface2,
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(130),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      // Animated oval border
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final borderColor = _verificationSuccess
                              ? AppColors.success
                              : _verificationFailed
                                  ? AppColors.error
                                  : AppColors.accent;
                          return Container(
                            width: 260 + (_pulseController.value * 8),
                            height: 340 + (_pulseController.value * 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.circular(135),
                              border: Border.all(
                                color: borderColor.withOpacity(
                                  0.5 + _pulseController.value * 0.5,
                                ),
                                width: 3,
                              ),
                            ),
                          );
                        },
                      ),
                      // Success checkmark
                      if (_verificationSuccess)
                        Container(
                          width: 260,
                          height: 340,
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(130),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 80,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Instruction text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: Text(
                _instruction,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _verificationSuccess
                      ? AppColors.success
                      : _verificationFailed
                          ? AppColors.error
                          : AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ),
            if (_verificationSuccess) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  context.read<OnboardingProvider>().verifiedName ?? '',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            // CTA buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: _verificationSuccess
                  ? AchievaButton(
                      label: AppStrings.proceedToExam,
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/exam');
                      },
                    )
                  : _verificationFailed
                      ? AchievaButton(
                          label: AppStrings.retryVerification,
                          onPressed: _retry,
                        )
                      : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
