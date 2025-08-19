import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _localIP = '192.168.1.13';
  static const String _localhost = 'localhost';
  static const int _port = 5000;

  // Dynamic base URL based on platform
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://$_localhost:$_port/api';
    } else if (Platform.isAndroid) {
      return 'http://$_localIP:$_port/api';
    } else if (Platform.isIOS) {
      return 'http://$_localIP:$_port/api';
    } else {
      return 'http://$_localhost:$_port/api';
    }
  }

  // API Endpoints
  static const String sendDriverOtpEndpoint = '/auth/driver/send-otp';
  static const String verifyDriverOtpEndpoint = '/auth/driver/verify-otp';
  static const String sendParentOtpEndpoint = '/auth/parent/send-otp';
  static const String verifyParentOtpEndpoint = '/auth/parent/verify-otp';
  static const String busesEndpoint = '/buses';
  static const String driverRouteEndpoint = '/driver/route';
  static const String driverProfileEndpoint = '/driver/profile';

  // App Settings
  static const String appName = 'Driver App';

  static String get configInfo {
    return 'Platform: ${_getPlatformName()}, Base URL: $baseUrl';
  }

  static String _getPlatformName() {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }
}
