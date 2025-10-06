// lib/views/connexion/providers/auth_provider.dart
import 'package:VarXPro/views/connexion/models/auth_model.dart';
import 'package:VarXPro/views/connexion/service/auth_service.dart';
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null && _user!.role != 'visitor';

  Future<AuthResponse> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await AuthService.login(email: email, password: password);
    final response = AuthResponse.fromService(result);

    if (response.success) {
      _user = response.user; // from immediate login response
      notifyListeners();

      // Refresh from server & recache
      await _fetchUserDetails();
    } else {
      _error = response.error;
    }

    _isLoading = false;
    notifyListeners();
    return response;
  }

  Future<void> _fetchUserDetails() async {
    final result = await AuthService.getUserProfile();
    if (result['success']) {
      final data = result['data'] as Map<String, dynamic>;
      _user = User(
        id: (data['id'] ?? '').toString(),
        name: (data['name'] ?? '') as String,
        email: (data['email'] ?? '') as String,
        role: (data['role'] ?? 'user') as String,
      );
    } else {
      // keep cached user if API fails
      // debug: print('Error fetching user details: ${result['error']}');
    }
    notifyListeners();
  }

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String role = 'user',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await AuthService.register(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
      role: role,
    );
    final response = AuthResponse.fromService(result);

    _isLoading = false;
    notifyListeners();
    return response;
  }

  Future<Map<String, dynamic>> sendEmailOtp(String email) async {
    return await AuthService.sendEmailOtp(email: email);
  }

  Future<Map<String, dynamic>> verifyEmailOtp(String email, String code) async {
    return await AuthService.verifyEmailOtp(email: email, code: code);
  }

  Future<Map<String, dynamic>> sendForgotPasswordOtp(String email) async {
    return await AuthService.sendForgotPasswordOtp(email: email);
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) async {
    return await AuthService.resetPassword(
      email: email,
      code: code,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
  }

  void setAsVisitor() {
    _user = User(id: '', name: 'Visitor', email: '', role: 'visitor');
    notifyListeners();
  }

  Future<void> logout() async {
    await AuthService.logout();
    _user = null;
    _error = null;
    notifyListeners();
  }

  /// Call once on app launch.
  Future<void> checkAuthStatus() async {
    // 1) If token exists, hydrate from local cache FIRST (instant UI)
    final logged = await AuthService.isLoggedIn();
    if (logged) {
      final cached = await AuthService.getCachedUser();
      if (cached != null) {
        _user = User.fromJson(cached); // instant name/email/role
        notifyListeners();
      } else {
        // fallback (very rare): read role only
        final role = await AuthService.getUserRole() ?? 'visitor';
        _user = User(id: '', name: ' ', email: '', role: role); // empty name instead of "Loading..."
        notifyListeners();
      }

      // 2) Then refresh from API (keeps UI fresh if network OK)
      await _fetchUserDetails();
    } else {
      setAsVisitor();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
