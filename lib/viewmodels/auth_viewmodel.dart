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
        if (_token != null && _token!.isNotEmpty) {
          print(
            '🔑 Token recibido del servidor: ${_token!.substring(0, _token!.length > 20 ? 20 : _token!.length)}...',
          );

          // Configurar el token en ApiService PRIMERO
          ApiService().setToken(_token!);

          // Verificar que se configuró correctamente
          if (ApiService().hasToken) {
            print('✅ Token verificado en ApiService');
          } else {
            print('❌ ERROR: Token no se configuró correctamente en ApiService');
          }

          // Guardar token en SharedPreferences
          await _saveAuthData();

          // Guardar credenciales para login automático
          await saveCredentials(dni, password);
        } else {
          print('❌ ERROR: Token es null o vacío');
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

  // Login automático con credenciales guardadas
  Future<bool> autoLogin() async {
    try {
      final credentials = await getSavedCredentials();
      if (credentials == null) {
        print('ℹ️ No hay credenciales guardadas para login automático');
        return false;
      }

      print('🔄 Intentando login automático con DNI: ${credentials['dni']}');
      final success = await login(
        credentials['dni']!,
        credentials['password']!,
      );

      if (success) {
        print('✅ Login automático exitoso');
        // Verificar que el token esté configurado
        if (ApiService().hasToken) {
          print('✅ Token disponible después del login automático');
        } else {
          print(
            '❌ ADVERTENCIA: Token no disponible después del login automático',
          );
        }
      } else {
        print('❌ Login automático falló: $_errorMessage');
      }

      return success;
    } catch (e) {
      print('❌ Error en login automático: $e');
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
      try {
        await _authService.logout(_token!);
      } catch (e) {
        print('Error en logout del servidor: $e');
        // Continuar con el logout local aunque falle el servidor
      }
    }

    _currentUser = null;
    _token = null;
    _errorMessage = '';

    // Limpiar almacenamiento local, token de ApiService y credenciales
    await _clearAuthData();
    await clearSavedCredentials();

    notifyListeners();
  }

  // Métodos para persistencia
  Future<void> _saveAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_token != null) {
        await prefs.setString('auth_token', _token!);
        print('Token guardado: ${_token!.substring(0, 20)}...'); // Debug
      }
      if (_currentUser != null) {
        await prefs.setString('auth_user', json.encode(_currentUser!.toJson()));
      }
    } catch (e) {
      print('Error guardando datos de autenticación: $e');
    }
  }

  // Guardar credenciales para login automático
  Future<void> saveCredentials(String dni, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_dni', dni);
      // NOTA: En producción, deberías encriptar la contraseña
      // Por ahora la guardamos tal cual para login automático
      await prefs.setString('saved_password', password);
    } catch (e) {
      print('Error guardando credenciales: $e');
    }
  }

  // Obtener credenciales guardadas
  Future<Map<String, String>?> getSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dni = prefs.getString('saved_dni');
      final password = prefs.getString('saved_password');

      if (dni != null && password != null) {
        return {'dni': dni, 'password': password};
      }
      return null;
    } catch (e) {
      print('Error obteniendo credenciales: $e');
      return null;
    }
  }

  // Limpiar credenciales guardadas
  Future<void> clearSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_dni');
      await prefs.remove('saved_password');
    } catch (e) {
      print('Error limpiando credenciales: $e');
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
  // NO carga el token, solo verifica si hay credenciales guardadas
  Future<void> loadAuthData() async {
    try {
      // NO cargar token aquí - se hará login automático si hay credenciales
      // Esto asegura que el token sea válido y reciente
      print('loadAuthData: Verificando credenciales guardadas...');
    } catch (e) {
      print('Error cargando datos de autenticación: $e');
    }
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  // Método para actualizar usuario
  Future<bool> updateUser({String? email, String? telefono}) async {
    if (_token == null) return false;

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await _authService.updateUser(
        token: _token!,
        email: email,
        telefono: telefono,
      );

      _isLoading = false;

      if (result['success'] == true) {
        // Actualizar usuario localmente
        if (result['data'] != null) {
          // Crear nuevo objeto UserModel con los datos actualizados
          // Asumiendo que el backend devuelve el objeto usuario completo
          // Si no, actualizamos solo los campos cambiados en el objeto actual
          try {
            // Intentar parsear el usuario completo si viene en la respuesta
            // Nota: UserModel.fromJson podría necesitar ajustes si la estructura varía
            // Por ahora actualizamos manualmente los campos del usuario actual
            if (_currentUser != null) {
              _currentUser = _currentUser!.copyWith(
                email: email ?? _currentUser!.email,
                telefono: telefono ?? _currentUser!.telefono,
              );

              // Guardar cambios en SharedPreferences
              await _saveAuthData();
            }
          } catch (e) {
            print('Error actualizando usuario local: $e');
          }
        }

        _errorMessage = '';
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Error al actualizar perfil';
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

  // Método para cambiar contraseña
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (_token == null) return false;

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await _authService.changePassword(
        token: _token!,
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      _isLoading = false;

      if (result['success'] == true) {
        _errorMessage = '';
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Error al cambiar contraseña';
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
}
