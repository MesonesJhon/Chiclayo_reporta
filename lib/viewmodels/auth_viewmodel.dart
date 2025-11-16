import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

class AuthViewModel with ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String _errorMessage = '';
  UserModel? _currentUser;
  String? _token;

  // Getters
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _currentUser != null && _token != null;

  // Método de Login
  Future<bool> login(String dni, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await _authService.login(dni: dni, password: password);

      _isLoading = false;

      if (result.isSuccess && result.user != null) {
        _currentUser = result.user;
        _token = result.token;
        _errorMessage = '';

        // Guardar token en SharedPreferences y configurar en ApiService
        if (_token != null) {
          await _saveAuthData();
          // Configurar el token en ApiService para uso automático
          ApiService().setToken(_token!);
        }

        notifyListeners();
        return true;
      } else {
        _errorMessage = result.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error de conexión: $e';
      notifyListeners();
      return false;
    }
  }

  // Método de Registro (mejorado)
  Future<bool> registerWithData(Map<String, dynamic> userData) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await _authService.register(userData);

      _isLoading = false;

      if (result['success'] == true) {
        _errorMessage = '';
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['error'] ?? 'Error en el registro';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error de conexión: $e';
      notifyListeners();
      return false;
    }
  }

  // Método de registro por campos individuales (compatibilidad)
  Future<bool> register({
    required String dni,
    required String password,
    required String nombres,
    required String apellidoPaterno,
    required String apellidoMaterno,
    required String nombreCompleto,
    String? email,
    String? telefono,
  }) async {
    final userData = {
      'dni': dni,
      'password': password,
      'nombres': nombres,
      'apellido_paterno': apellidoPaterno,
      'apellido_materno': apellidoMaterno,
      'nombre_completo': nombreCompleto,
      'email': email,
      'telefono': telefono,
    };

    return await registerWithData(userData);
  }

  // Método para logout
  Future<void> logout() async {
    if (_token != null) {
      await _authService.logout(_token!);
    }

    _currentUser = null;
    _token = null;
    _errorMessage = '';

    // Limpiar almacenamiento local y token de ApiService
    await _clearAuthData();

    notifyListeners();
  }

  // Métodos para persistencia
  Future<void> _saveAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_token != null) {
        await prefs.setString('auth_token', _token!);
      }
      if (_currentUser != null) {
        await prefs.setString('auth_user', json.encode(_currentUser!.toJson()));
      }
    } catch (e) {
      print('Error guardando datos de autenticación: $e');
    }
  }

  Future<void> _clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('auth_user');
      // Limpiar token de ApiService
      ApiService().clearToken();
    } catch (e) {
      print('Error limpiando datos de autenticación: $e');
    }
  }

  // Método para cargar datos de autenticación al iniciar la app
  Future<void> loadAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userJson = prefs.getString('auth_user');

      if (token != null && userJson != null) {
        _token = token;
        _currentUser = UserModel.fromJson(json.decode(userJson));

        // Configurar el token en ApiService para uso automático
        ApiService().setToken(token);

        notifyListeners();
      }
    } catch (e) {
      print('Error cargando datos de autenticación: $e');
    }
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}
