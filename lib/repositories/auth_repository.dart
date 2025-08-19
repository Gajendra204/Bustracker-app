// ignore_for_file: unused_field

import '../services/api_service.dart';
import '../services/token_service.dart';
import '../models/auth_models.dart';

class AuthRepository {
  final ApiService _apiService;
  final TokenService _tokenService;

  AuthRepository({
    ApiService? apiService,
    TokenService? tokenService,
  })  : _apiService = apiService ?? ApiService(),
        _tokenService = tokenService ?? TokenService();

  /// Send OTP to phone number
  Future<OtpResponse> sendOtp(String phoneNumber, String userType) async {
    try {
      final response = await ApiService.sendOTP(phoneNumber, userType);
      
      if (response['success'] == true) {
        final otpToken = response['data']?['otpToken'] as String?;
        if (otpToken != null) {
          await TokenService.storeOTPToken(otpToken);
        }
        
        return OtpResponse(
          success: true,
          message: response['message'] ?? 'OTP sent successfully',
          otpToken: otpToken,
        );
      } else {
        return OtpResponse(
          success: false,
          message: response['message'] ?? 'Failed to send OTP',
        );
      }
    } catch (e) {
      return OtpResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Verify OTP and get access token
  Future<AuthResult> verifyOtp(String otp) async {
    try {
      final otpToken = await TokenService.getOTPToken();
      if (otpToken == null) {
        return AuthResult(
          success: false,
          message: 'OTP token not found. Please try sending OTP again.',
        );
      }

      final response = await ApiService.verifyOTP(otpToken, otp, 'driver');
      
      if (response['success'] == true) {
        final accessToken = response['data']?['token'] as String?;
        final userRole = response['data']?['role'] as String?;
        
        if (accessToken != null) {
          await TokenService.storeAccessToken(accessToken);
          await TokenService.clearOTPToken();
          
          if (userRole != null) {
            await TokenService.storeDriverRole(userRole);
          }
          
          return AuthResult(
            success: true,
            message: 'Login successful',
            accessToken: accessToken,
            userRole: userRole,
          );
        }
      }
      
      return AuthResult(
        success: false,
        message: response['message'] ?? 'Invalid OTP',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Verification failed: ${e.toString()}',
      );
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await TokenService.getAccessToken();
    return token != null;
  }

  // Get current user role
  Future<String?> getCurrentUserRole() async {
    return await TokenService.getDriverRole();
  }

  // Logout user
  Future<void> logout() async {
    await TokenService.clearAllTokens();
  }
}
