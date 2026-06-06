import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _initialized = false;

  UserModel? get currentUser => _authService.currentUser;
  bool get isLoading => _authService.isLoading;
  bool get isLoggedIn => _authService.isLoggedIn;
  String get userId => _authService.userId;
  String get userName => _authService.userName;
  String get restaurantName => _authService.restaurantName;

  Future<void> init() async {
    if (!_initialized) {
      await _authService.init();
      _initialized = true;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    final result = await _authService.login(email, password);
    notifyListeners();
    return result;
  }

  Future<bool> register(
    String name,
    String email,
    String password,
    String phone,
    String restaurantName,
    String role,
  ) async {
    final result = await _authService.register(
      name,
      email,
      password,
      phone,
      restaurantName,
      role,
    );
    notifyListeners();
    return result;
  }

  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }
}
