import 'package:flutter/services.dart';

class ScreenSecurity {
  static const _channel = MethodChannel('ng.achieva.achievamobile/security');

  static Future<void> enableSecureMode() async {
    try {
      await _channel.invokeMethod('enableSecureMode');
    } catch (_) {
      // Fallback: silently fail on unsupported platforms
    }
  }
}
