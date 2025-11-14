import 'package:flutter/material.dart';
import 'package:chiclayo_reporte/models/user_model.dart';
import 'package:chiclayo_reporte/models/authResponse_model.dart';
import 'package:chiclayo_reporte/services/user_service.dart';

class UserViewModel extends ChangeNotifier {
  final UserService _userService = UserService();
  AuthResponse? _authResponse;

  String _errorMessage = '';
  bool _isLoading = false;

  AuthResponse? get authResponse => _authResponse;
  String get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  Future<void> login(String username, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      UserModel user = UserModel(username: username, password: password);
      _authResponse = await _userService.login(user);
      _errorMessage = '';
    } catch (e) {
      _errorMessage = e.toString();
      _authResponse = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
