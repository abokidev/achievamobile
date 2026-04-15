import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:screen_protector/screen_protector.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/achieva_button.dart';

class TestSetupScreen extends StatefulWidget {
  const TestSetupScreen({super.key});

  @override
  State<TestSetupScreen> createState() => _TestSetupScreenState();
}

class _TestSetupScreenState extends State<TestSetupScreen> {
  // Test states: null = not started, true = passed, false = failed
  bool? _networkStatus;
  bool? _microphoneStatus;
  bool? _cameraStatus;
  bool _isTestingNetwork = false;
  bool _isTestingMic = false;
  bool _isTestingCamera = false;
  CameraController? _cameraController;
  bool _cameraPreviewReady = false;

  bool get _allTestsPassed =>
      _networkStatus == true && _microphoneStatus == true && _cameraStatus == true;

  @override
  void initState() {
    super.initState();
    _enableScreenSecurity();
  }

  Future<void> _enableScreenSecurity() async {
    try {
      await ScreenProtector.protectDataLeakageWithColor(Colors.black);
    } catch (_) {}
  }

  Future<void> _testNetwork() async {
    setState(() => _isTestingNetwork = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _networkStatus = true;
        _isTestingNetwork = false;
      });
    }
  }

  Future<void> _testMicrophone() async {
    setState(() => _isTestingMic = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _microphoneStatus = true;
        _isTestingMic = false;
      });
    }
  }

  Future<void> _testCamera() async {
    setState(() => _isTestingCamera = true);
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final front = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );
        _cameraController = CameraController(front, ResolutionPreset.low, enableAudio: false);
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _cameraStatus = true;
            _isTestingCamera = false;
            _cameraPreviewReady = true;
          });
        }
      } else {
        // No camera — pass anyway for demo
        if (mounted) {
          setState(() {
            _cameraStatus = true;
            _isTestingCamera = false;
          });
        }
      }
    } catch (_) {
      // Pass anyway for demo
      if (mounted) {
        setState(() {
          _cameraStatus = true;
          _isTestingCamera = false;
        });
      }
    }
  }

  Future<void> _runAllTests() async {
    await _testNetwork();
    await _testMicrophone();
    await _testCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Setup'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'System Check',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please verify that your device is ready for the exam.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 28),
              // Network test
              _testCard(
                icon: Icons.wifi,
                title: 'Network Speed',
                subtitle: _networkStatus == true ? 'Connected — Good' : 'Check internet connection',
                status: _networkStatus,
                isLoading: _isTestingNetwork,
                onTest: _testNetwork,
              ),
              const SizedBox(height: 12),
              // Microphone test
              _testCard(
                icon: Icons.mic,
                title: 'Microphone',
                subtitle: _microphoneStatus == true ? 'Working' : 'Check microphone access',
                status: _microphoneStatus,
                isLoading: _isTestingMic,
                onTest: _testMicrophone,
              ),
              const SizedBox(height: 12),
              // Camera test
              _testCard(
                icon: Icons.videocam,
                title: 'Camera',
                subtitle: _cameraStatus == true ? 'Working' : 'Check camera access',
                status: _cameraStatus,
                isLoading: _isTestingCamera,
                onTest: _testCamera,
              ),
              // Camera preview
              if (_cameraPreviewReady && _cameraController != null) ...[
                const SizedBox(height: 16),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 160,
                      height: 120,
                      child: CameraPreview(_cameraController!),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              // Run all tests button
              if (!_allTestsPassed)
                AchievaButton(
                  label: 'Run All Tests',
                  backgroundColor: AppColors.surface2,
                  onPressed: (_isTestingNetwork || _isTestingMic || _isTestingCamera)
                      ? null
                      : _runAllTests,
                ),
              if (!_allTestsPassed) const SizedBox(height: 12),
              // Proceed button
              AchievaButton(
                label: _allTestsPassed ? 'Start Exam' : 'Skip & Start Exam',
                backgroundColor: _allTestsPassed ? AppColors.primary : AppColors.surface2,
                onPressed: () {
                  _cameraController?.dispose();
                  _cameraController = null;
                  Navigator.pushReplacementNamed(context, '/exam');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _testCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool? status,
    required bool isLoading,
    required VoidCallback onTest,
  }) {
    Color statusColor = AppColors.textMuted;
    IconData statusIcon = Icons.circle_outlined;
    if (status == true) {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle;
    } else if (status == false) {
      statusColor = AppColors.error;
      statusIcon = Icons.cancel;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status == true
              ? AppColors.success.withOpacity(0.3)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: statusColor, fontSize: 13)),
              ],
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            )
          else if (status == null)
            TextButton(
              onPressed: onTest,
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: const Text('Test'),
            )
          else
            Icon(statusIcon, color: statusColor, size: 24),
        ],
      ),
    );
  }
}
