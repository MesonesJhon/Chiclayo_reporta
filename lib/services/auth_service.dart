import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/auth_response.dart';

class AuthService {
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.backendBaseUrl}${ApiConstants.authRegistro}',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );

      // Manejar errores de parsing JSON
      Map<String, dynamic> data;
      try {
        data = json.decode(response.body) as Map<String, dynamic>;
      } catch (e) {
        return {
          'success': false,
          'error': 'Error al procesar la respuesta del servidor',
        };
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        // El backend devuelve { "code": 1, "data": {...}, "message": "..." }
        if (data['code'] == 1) {
          return {
            'success': true,
            'data': data['data'],
            'message': data['message'],
          };
        } else {
          // Limpiar mensajes de error técnicos del backend
          String errorMessage =
              data['message']?.toString() ?? 'Error en el registro';
          errorMessage = _cleanErrorMessage(errorMessage);

          return {'success': false, 'error': errorMessage};
        }
      } else {
        String errorMessage =
            data['message']?.toString() ?? 'Error en el registro';
        errorMessage = _cleanErrorMessage(errorMessage);

        return {'success': false, 'error': errorMessage};
      }
    } on http.ClientException {
      return {
        'success': false,
        'error':
            'Error de conexión. Verifica tu internet e intenta nuevamente.',
      };
    } catch (e) {
      // Log del error para debugging
      print('Error en registro: $e');
      return {
        'success': false,
        'error': 'Error inesperado. Por favor, intenta nuevamente.',
      };
    }
  }

  // Limpiar mensajes de error técnicos para mostrar mensajes amigables
  String _cleanErrorMessage(String error) {
    // Si el error contiene información técnica de Python, mostrar mensaje genérico
    if (error.contains('NameError') ||
        error.contains('generate_password_hash') ||
        error.contains('not defined') ||
        error.contains('Traceback') ||
        error.contains('File "') ||
        error.contains('line ')) {
      return 'Error en el servidor. Por favor, contacta al administrador o intenta más tarde.';
    }

    // Limpiar otros errores técnicos comunes
    if (error.contains('repr(') || error.contains('Exception')) {
      return 'Error en el servidor. Por favor, intenta nuevamente.';
    }

    return error;
  }

  Future<AuthResponse> login({
    required String dni,
    required String password,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.backendBaseUrl}${ApiConstants.authLogin}',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'dni': dni, 'password': password}),
      );

      final Map<String, dynamic> data = json.decode(response.body);

      // Debug: verificar la estructura del response
      print('📥 Response del login - Status: ${response.statusCode}');
      print('📥 Response body keys: ${data.keys}');
      if (data['data'] != null && data['data'] is Map) {
        print('📥 Data keys: ${(data['data'] as Map).keys}');
        if ((data['data'] as Map).containsKey('token')) {
          final token = (data['data'] as Map)['token'];
          print(
            '📥 Token encontrado en response: ${token.toString().substring(0, token.toString().length > 20 ? 20 : token.toString().length)}...',
          );
        } else {
          print('❌ ERROR: Token no encontrado en data');
        }
      }

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(data);
      } else {
        String errorMessage =
            data['message']?.toString() ?? 'Error en el login';
        errorMessage = _cleanErrorMessage(errorMessage);

        return AuthResponse(
          code: data['code'] ?? 0,
          data: null,
          message: errorMessage,
        );
      }
    } on http.ClientException {
      return AuthResponse(
        code: 0,
        data: null,
        message:
            'Error de conexión. Verifica tu internet e intenta nuevamente.',
      );
    } catch (e) {
      // Log del error para debugging
      print('Error en login: $e');
      return AuthResponse(
        code: 0,
        data: null,
        message: 'Error inesperado. Por favor, intenta nuevamente.',
      );
    }
  }

  Future<void> logout(String token) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.backendBaseUrl}${ApiConstants.authLogout}',
      );

      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      // Ignorar errores en logout
      print('Error en logout: $e');
    }
  }
}
