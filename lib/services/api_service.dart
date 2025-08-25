import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'token_service.dart';

class ApiService {
  // Get authorization headers with token
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await TokenService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Send OTP
  static Future<Map<String, dynamic>> sendOTP(
    String phoneNumber,
    String userType,
  ) async {
    final endpoint = userType == 'driver'
        ? AppConfig.sendDriverOtpEndpoint
        : AppConfig.sendParentOtpEndpoint;

    final fullUrl = '${AppConfig.baseUrl}$endpoint';

    try {
      final response = await http
          .post(
            Uri.parse(fullUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phoneNumber': '+91$phoneNumber'}),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception(
                'Request timeout - server not responding after 15 seconds',
              );
            },
          );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else {
        throw Exception(
          'Server error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (e.toString().contains('timeout')) {
        throw Exception('Connection timeout error');
      } else {
        throw Exception('Network error: $e');
      }
    }
  }

  // Verify OTP
  static Future<Map<String, dynamic>> verifyOTP(
    String otpToken,
    String otp,
    String userType,
  ) async {
    try {
      final endpoint = userType == 'driver'
          ? AppConfig.verifyDriverOtpEndpoint
          : AppConfig.verifyParentOtpEndpoint;

      final fullUrl = '${AppConfig.baseUrl}$endpoint';

      final response = await http.post(
        Uri.parse(fullUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'otpToken': otpToken, 'otp': otp}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else {
        throw Exception('Failed to verify OTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get driver's assigned route
  static Future<Map<String, dynamic>> getDriverRoute() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/driver/route'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else {
        throw Exception('Failed to get driver route: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get driver profile
  static Future<Map<String, dynamic>> getDriverProfile() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/driver/profile'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else {
        throw Exception('Failed to get driver profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get parent's child route information
  static Future<Map<String, dynamic>> getParentRoute() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/parent/route'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else {
        throw Exception('Failed to get parent route: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get driver ID for parent's child route
  static Future<String?> getDriverIdForParent() async {
    try {
      final routeData = await getParentRoute();
      return routeData['data']?['driverId']?.toString();
    } catch (e) {
      throw Exception('Failed to get driver ID: $e');
    }
  }
}
