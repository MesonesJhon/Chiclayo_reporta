import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class LoginViewModel with ChangeNotifier {
  final AuthService _authService = AuthService();

  String _dni = '';
  String _password = '';
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _errorMessage = '';
  UserModel? _currentUser;

  // Getters
  String get dni => _dni;
  String get password => _password;
  bool get isLoading => _isLoading;
  bool get obscurePassword => _obscurePassword;
  String get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  bool get isFormValid => _dni.length == 8 && _password.isNotEmpty;

  // Setters
  void setDni(String value) {
    _dni = value;
    clearError();
    notifyListeners();
  }

  void setPassword(String value) {
    _password = value;
    clearError();
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  void setCurrentUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  // Validaciones
  String? validateDni(String? value) {
    if (value == null || value.isEmpty) {
      return 'El DNI es requerido';
    }
    if (value.length != 8) {
      return 'El DNI debe tener 8 dígitos';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'El DNI debe contener solo números';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  // Método de login
  Future<bool> login() async {
    if (!isFormValid) {
      setError('Complete todos los campos correctamente');
      return false;
    }

    setLoading(true);
    clearError();

    try {
      final response = await _authService.login(dni: _dni, password: _password);

      setLoading(false);

      if (response.isSuccess && response.user != null) {
        _currentUser = response.user;
        notifyListeners();
        return true;
      } else {
        setError(response.message);
        return false;
      }
    } catch (e) {
      setLoading(false);
      setError('Error de conexión: $e');
      return false;
    }
  }

  // Método para recuperar contraseña
  Future<bool> recuperarPassword(String dni) async {
    if (dni.length != 8) {
      setError('El DNI debe tener 8 dígitos');
      return false;
    }

    setLoading(true);
    clearError();

    // Aquí implementarías la lógica de recuperación de contraseña
    await Future.delayed(const Duration(seconds: 2)); // Simulación

    setLoading(false);
    setError('Función de recuperación no implementada');
    return false;
  }

  // Limpiar formulario
  void clearForm() {
    _dni = '';
    _password = '';
    _errorMessage = '';
    _obscurePassword = true;
    notifyListeners();
  }

  // Verificar si el usuario está autenticado
  Future<bool> checkAuthStatus() async {
    // Aquí podrías verificar si hay un token válido en SharedPreferences
    // y cargar los datos del usuario
    return _currentUser != null;
  }
}
