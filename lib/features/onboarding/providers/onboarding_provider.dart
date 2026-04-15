import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

class OnboardingProvider extends ChangeNotifier {
  final ApiService _apiService;

  bool _isLoading = false;
  String? _error;
  String? _verifiedName;
  bool _ninVerified = false;
  bool _faceVerified = false;

  OnboardingProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get verifiedName => _verifiedName;
  bool get ninVerified => _ninVerified;
  bool get faceVerified => _faceVerified;

  Future<bool> verifyNin(String nin, String dob, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.verifyNin(nin, dob, token);
      if (response['success'] == true) {
        _verifiedName = response['name'];
        _ninVerified = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Verification failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Network error. Please check your connection and try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyFace(String imageBase64, String nin, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.verifyFace(imageBase64, nin, token);
      if (response['match'] == true || response['verified'] == true) {
        _faceVerified = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Face verification failed. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Network error. Please check your connection and try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _isLoading = false;
    _error = null;
    _verifiedName = null;
    _ninVerified = false;
    _faceVerified = false;
    notifyListeners();
  }
}
