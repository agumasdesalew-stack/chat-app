import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final _authService = AuthService();
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  Future<void> signUp({
    required String firstName,
    String? secondName,
    required String username,
    required String email,
    required String password,
  }) async {
    await _authService.signUp(
      firstName: firstName,
      secondName: secondName,
      username: username,
      email: email,
      password: password,
    );
    _currentUser = await _authService.getCurrentUser();
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    await _authService.signIn(email, password);
    _currentUser = await _authService.getCurrentUser();
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }
}