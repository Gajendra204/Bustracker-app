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

  // Send OTP (supports both driver and parent)
  static Future<Map<String, dynamic>> sendOTP(
    String phoneNumber,
    String userType,
  ) async {
    final endpoint = userType == 'driver'
        ? AppConfig.sendDriverOtpEndpoint
        : AppConfig.sendParentOtpEndpoint;

    final fullUrl = '${AppConfig.baseUrl}$endpoint';

    print('Phone: +91$phoneNumber');
    print('User Type: $userType');
    print('Attempting to connect to: $fullUrl');
    print('Platform: ${AppConfig.configInfo}');

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

      print(' Response received!');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('OTP request successful!');
        return responseData;
      } else {
        print('Server returned error: ${response.statusCode}');
        throw Exception(
          'Server error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Network Error Details: $e');
      if (e.toString().contains('timeout')) {
        throw Exception(
          'Connection timeout - Check if server is running and accessible',
        );
      } else if (e.toString().contains('connection refused')) {
        throw Exception(
          'Connection refused - Server may be down or wrong IP address',
        );
      } else {
        throw Exception('Network error: $e');
      }
    }
  }

  // Verify OTP (supports both driver and parent)
  static Future<Map<String, dynamic>> verifyOTP(
    String otpToken,
    String otp,
    String userType,
  ) async {
    try {
      final endpoint = userType == 'driver'
          ? AppConfig.verifyDriverOtpEndpoint
          : AppConfig.verifyParentOtpEndpoint;

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'otpToken': otpToken, 'otp': otp}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Verify OTP Response Status: ${response.statusCode}');
        print('Verify OTP Response Body: ${response.body}');
        print('Verify OTP Response Data: $responseData');
        return responseData;
      } else {
        print('Verify OTP Error Status: ${response.statusCode}');
        print('Verify OTP Error Body: ${response.body}');
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
        print('Driver Route Response: $responseData');
        return responseData;
      } else {
        print('Driver Route Error Status: ${response.statusCode}');
        print('Driver Route Error Body: ${response.body}');
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
        print('Driver Profile Response: $responseData');
        return responseData;
      } else {
        print('Driver Profile Error Status: ${response.statusCode}');
        print('Driver Profile Error Body: ${response.body}');
        throw Exception('Failed to get driver profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
