import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'api_service.dart';

class ProctorService {
  final ApiService _apiService;
  Timer? _periodicTimer;
  CameraController? _cameraController;
  String? _token;
  bool _isMonitoring = false;

  ProctorService({required ApiService apiService}) : _apiService = apiService;

  bool get isMonitoring => _isMonitoring;

  void configure({required CameraController cameraController, required String token}) {
    _cameraController = cameraController;
    _token = token;
  }

  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _periodicTimer = Timer.periodic(
      const Duration(seconds: 90),
      (_) => captureAndSend('periodic'),
    );
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  Future<void> captureAndSend(String eventType) async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _token == null) {
      return;
    }
    try {
      final image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      await _apiService.sendProctorSnapshot(base64Image, eventType, _token!);
    } catch (_) {
      // Silently fail - proctoring should not interrupt exam
    }
  }

  Future<void> logEvent(String type) async {
    if (_token == null) return;
    try {
      await _apiService.sendProctorEvent(
        type,
        DateTime.now().toIso8601String(),
        _token!,
      );
    } catch (_) {
      // Silently fail
    }
  }

  void dispose() {
    stopMonitoring();
  }
}
