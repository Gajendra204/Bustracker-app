import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../repositories/auth_repository.dart';
import '../repositories/parent_auth_repository.dart';
import '../services/token_service.dart';
import 'route_details_screen.dart';
import 'parent_home_screen.dart';
import 'mobile_number_screen.dart';

class OTPScreen extends StatefulWidget {
  final String phoneNumber;
  final String userType;

  const OTPScreen({
    super.key,
    required this.phoneNumber,
    required this.userType,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;

  void _verifyOTP() async {
    String otp = _otpControllers.map((controller) => controller.text).join();

    if (otp.length != 6) {
      _showSnackBar('Please enter complete OTP');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final otpToken = await TokenService.getOTPToken();
      print('Retrieved OTP Token: $otpToken');
      if (otpToken == null) {
        throw Exception('OTP token not found. Please try sending OTP again.');
      }

      // Decode and validate token type
      final tokenParts = otpToken.split('.');
      if (tokenParts.length == 3) {
        final payload = tokenParts[1];
        final decoded = utf8.decode(
          base64Url.decode(base64Url.normalize(payload)),
        );
        final tokenData = jsonDecode(decoded);
        final tokenType = tokenData['type'] as String?;

        print('Token type: $tokenType, Expected user type: ${widget.userType}');

        // Check if token type matches expected user type
        if ((widget.userType == 'driver' && tokenType != 'driver_otp') ||
            (widget.userType == 'parent' && tokenType != 'parent_otp')) {
          setState(() {
            _isLoading = false;
          });
          _showSnackBar(
            'Token type mismatch. Please go back and request a new OTP for ${widget.userType} login.',
            isError: true,
          );
          return;
        }
      }

      // Use appropriate repository based on user type
      dynamic result;
      if (widget.userType == 'parent') {
        final parentAuthRepository = ParentAuthRepository();
        result = await parentAuthRepository.verifyOtp(otp);
      } else {
        final authRepository = AuthRepository();
        result = await authRepository.verifyOtp(otp);
      }

      if (!result.success) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar(result.message, isError: true);
        return;
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        final userRole = await TokenService.getUserRole();

        if (widget.userType == 'parent' &&
            userRole?.toLowerCase() == 'parent') {
          _showSnackBar('Login successful!', isError: false);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ParentHomeScreen()),
          );
        } else if (widget.userType == 'driver' &&
            userRole?.toLowerCase() == 'driver') {
          _showSnackBar('Login successful!', isError: false);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const RouteDetailsScreen()),
          );
        } else {
          await TokenService.clearAllTokens();
          _showSnackBar(
            'Authentication failed. Please try again.',
            isError: true,
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  MobileNumberScreen(userType: widget.userType),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        _showSnackBar('Failed to verify OTP: ${e.toString()}');
      }
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _onOTPChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Verify OTP',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),

            // Header
            const Text(
              'Enter Verification Code',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We sent a 6-digit code to +91 ${widget.phoneNumber}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),

            const SizedBox(height: 40),

            // OTP Input Fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 45,
                  height: 56,
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: widget.userType == 'driver'
                              ? Colors.blue
                              : Colors.green,
                          width: 2,
                        ),
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    onChanged: (value) => _onOTPChanged(value, index),
                  ),
                );
              }),
            ),

            const SizedBox(height: 40),

            // Verify Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.userType == 'driver'
                      ? Colors.blue
                      : Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Verify OTP',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
}
