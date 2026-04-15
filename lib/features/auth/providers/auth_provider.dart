import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  final AuthService _authService;

  bool _isLoading = false;
  String? _error;
  String? _token;
  String? _userName;
  bool _isVerified = false;

  AuthProvider({
    ApiService? apiService,
    AuthService? authService,
  })  : _apiService = apiService ?? ApiService(),
        _authService = authService ?? AuthService();

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get token => _token;
  String? get userName => _userName;
  bool get isVerified => _isVerified;
  bool get isAuthenticated => _token != null;

  Future<void> init() async {
    _token = await _authService.getToken();
    final userData = await _authService.getUserData();
    if (userData != null) {
      _userName = userData['name'];
      _isVerified = userData['isVerified'] ?? false;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.login(email, password);
      _token = response['token'];
      _userName = response['name'];
      _isVerified = response['isVerified'] ?? false;

      await _authService.saveToken(_token!);
      await _authService.saveUserData({
        'name': _userName,
        'userId': response['userId'],
        'isVerified': _isVerified,
      });

      _isLoading = false;
      notifyListeners();
      return true;
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

  void setVerified(bool verified) {
    _isVerified = verified;
    _authService.saveUserData({
      'name': _userName,
      'isVerified': _isVerified,
    });
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.clearAll();
    _token = null;
    _userName = null;
    _isVerified = false;
    _error = null;
    notifyListeners();
  }
}
