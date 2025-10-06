// lib/views/connexion/models/auth_model.dart
class User {
  final String id;
  final String name;
  final String email;
  final String role; 

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'visitor',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email, 'role': role};
  }
}

class AuthResponse {
  final bool success;
  final String? token;
  final User? user;
  final String? error;

  AuthResponse({required this.success, this.token, this.user, this.error});

  factory AuthResponse.fromService(Map<String, dynamic> data) {
    if (data['success']) {
      final responseData = data['data'];
      return AuthResponse(
        success: true,
        token: responseData['token'],
        user: User.fromJson(responseData['user'] ?? {}),
      );
    } else {
      return AuthResponse(success: false, error: data['error']);
    }
  }
}