// ignore_for_file: unused_field

import '../services/api_service.dart';
import '../services/token_service.dart';
import '../models/auth_models.dart';

//parent authentication 
class ParentAuthRepository {
  final ApiService _apiService;
  final TokenService _tokenService;

  ParentAuthRepository({ApiService? apiService, TokenService? tokenService})
    : _apiService = apiService ?? ApiService(),
      _tokenService = tokenService ?? TokenService();

  // Send OTP to parent's phone number
  Future<OtpResponse> sendOtp(String phoneNumber) async {
    try {
      final response = await ApiService.sendOTP(phoneNumber, 'parent');

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

  // Verify OTP and get parent access token
  Future<AuthResult> verifyOtp(String otp) async {
    try {
      final otpToken = await TokenService.getOTPToken();
      if (otpToken == null) {
        return AuthResult(
          success: false,
          message: 'OTP token not found. Please try sending OTP again.',
        );
      }

      final response = await ApiService.verifyOTP(otpToken, otp, 'parent');

      if (response['success'] == true) {
        final accessToken = response['data']?['token'] as String?;

        if (accessToken != null) {
          await TokenService.storeAccessToken(accessToken);
          await TokenService.clearOTPToken();

          // Extract role from the stored token 
          final userRole = await TokenService.getUserRole();
          if (userRole != null) {
            await TokenService.storeUserRole(userRole);
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

  // Check if parent is authenticated
  Future<bool> isAuthenticated() async {
    final token = await TokenService.getAccessToken();
    if (token == null) return false;

    // Verify it's a parent token
    return await TokenService.isParent();
  }

  // Get current parent's role
  Future<String?> getCurrentUserRole() async {
    return await TokenService.getUserRole();
  }

  // Get parent ID
  Future<String?> getParentId() async {
    return await TokenService.getParentId();
  }

  // Get student ID associated with parent
  Future<String?> getStudentId() async {
    return await TokenService.getStudentId();
  }

  // Get parent phone number
  Future<String?> getParentPhone() async {
    return await TokenService.getParentPhone();
  }

  // Logout parent user
  Future<void> logout() async {
    await TokenService.clearAllTokens();
  }
}
