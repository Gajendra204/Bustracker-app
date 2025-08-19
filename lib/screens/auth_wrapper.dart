import 'package:flutter/material.dart';
import '../services/token_service.dart';
import 'mobile_number_screen.dart';
import 'route_details_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final isLoggedIn = await TokenService.isLoggedIn();
    String? userRole;

    if (isLoggedIn) {
      userRole = await TokenService.getDriverRole();
    }

    setState(() {
      _isLoggedIn = isLoggedIn;
      _userRole = userRole;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isLoggedIn) {
      if (_userRole?.toLowerCase() == 'driver') {
        return const RouteDetailsScreen();
      } else {
        TokenService.clearAllTokens();
        return const MobileNumberScreen(userType: 'driver');
      }
    } else {
      return const MobileNumberScreen(userType: 'driver');
    }
  }
}
