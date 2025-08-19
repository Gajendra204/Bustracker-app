// Data models for authentication

class OtpResponse {
  final bool success;
  final String message;
  final String? otpToken;

  OtpResponse({
    required this.success,
    required this.message,
    this.otpToken,
  });
}

class AuthResult {
  final bool success;
  final String message;
  final String? accessToken;
  final String? userRole;

  AuthResult({
    required this.success,
    required this.message,
    this.accessToken,
    this.userRole,
  });
}

class User {
  final String id;
  final String phone;
  final String role;
  final String? name;

  User({
    required this.id,
    required this.phone,
    required this.role,
    this.name,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? '',
      name: json['name'],
    );
  }
}
