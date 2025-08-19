import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TokenService {
  static const String _accessTokenKey = 'access_token';
  static const String _otpTokenKey = 'otp_token';
  static const String _driverRoleKey = 'driver_role';

  // Store access token
  static Future<void> storeAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, token);
  }

  // Get access token
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  // Store OTP token (temporary)
  static Future<void> storeOTPToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_otpTokenKey, token);
    print('TokenService: OTP token stored successfully');
  }

  // Get OTP token
  static Future<String?> getOTPToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_otpTokenKey);
    print('TokenService: Retrieved OTP token: $token');
    return token;
  }

  // Clear OTP token after successful verification
  static Future<void> clearOTPToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_otpTokenKey);
  }

  // Clear all tokens (logout)
  static Future<void> clearAllTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_otpTokenKey);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // Decode JWT token to get driver information
  static Map<String, dynamic>? decodeToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        print('Invalid token format');
        return null;
      }

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return json.decode(decoded);
    } catch (e) {
      print('Error decoding token: $e');
      return null;
    }
  }

  // Get driver ID from stored token
  static Future<String?> getDriverId() async {
    final token = await getAccessToken();
    if (token == null) return null;

    final decoded = decodeToken(token);
    return decoded?['userId'];
  }

  // Get driver phone from stored token
  static Future<String?> getDriverPhone() async {
    final token = await getAccessToken();
    if (token == null) return null;

    final decoded = decodeToken(token);
    return decoded?['phone'];
  }

  // Get driver role from stored token
  static Future<String?> getDriverRole() async {
    final token = await getAccessToken();
    print('TokenService: Retrieved token: ${token?.substring(0, 50)}...');
    if (token == null) return null;

    final decoded = decodeToken(token);
    print('TokenService: Decoded token: $decoded');
    final role = decoded?['role'];
    print('TokenService: Extracted role: $role');
    return role;
  }

  static Future<void> storeDriverRole(String userRole) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_driverRoleKey, userRole);
  }
}
