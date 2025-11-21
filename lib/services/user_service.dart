import 'dart:convert';
import '../models/user_model.dart';
import '../models/api_response.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class UserService {
  final ApiService _apiService = ApiService();

  /// Obtener todos los usuarios (solo administradores)
  Future<ApiResponse<List<UserModel>>> obtenerUsuarios() async {
    try {
      final response = await _apiService.get(ApiConstants.usuarios);

      if (response.body.isEmpty) {
        return ApiResponse.error(
          'Respuesta vacía del servidor',
          statusCode: response.statusCode,
        );
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['code'] == 1) {
        if (data['data'] != null && data['data'] is List) {
          try {
            final usuariosList = (data['data'] as List)
                .map((item) {
                  try {
                    return UserModel.fromJson(item as Map<String, dynamic>);
                  } catch (e) {
                    return null;
                  }
                })
                .whereType<UserModel>()
                .toList();

            return ApiResponse.success(
              usuariosList,
              message: data['message'] as String? ?? '',
            );
          } catch (e) {
            return ApiResponse.error(
              'Error al procesar los usuarios: $e',
              statusCode: response.statusCode,
            );
          }
        } else {
          return ApiResponse.error(
            'Formato de respuesta inválido',
            statusCode: response.statusCode,
          );
        }
      } else {
        final errorMsg =
            data['message'] as String? ??
            'Error al obtener usuarios (Status: ${response.statusCode})';
        return ApiResponse.error(errorMsg, statusCode: response.statusCode);
      }
    } on FormatException catch (e) {
      return ApiResponse.error('Error al procesar la respuesta: $e');
    } catch (e) {
      return ApiResponse.error('Error de conexión: ${e.toString()}');
    }
  }

  /// Actualizar estado de un usuario (solo administradores)
  Future<ApiResponse<Map<String, dynamic>>> actualizarEstadoUsuario({
    required int usuarioId,
    required String nuevoEstado,
  }) async {
    try {
      // Validar estado
      final estadosPermitidos = ['activo', 'inactivo', 'bloqueado'];
      final estadoNormalizado = nuevoEstado.toLowerCase();

      if (!estadosPermitidos.contains(estadoNormalizado)) {
        return ApiResponse.error(
          'Estado inválido. Valores permitidos: ${estadosPermitidos.join(", ")}',
        );
      }

      final response = await _apiService.patch(
        '${ApiConstants.usuariosDetalle}estado/$usuarioId',
        {'estado': estadoNormalizado},
      );

      if (response.body.isEmpty) {
        return ApiResponse.error(
          'Respuesta vacía del servidor',
          statusCode: response.statusCode,
        );
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['code'] == 1) {
        return ApiResponse.success(
          data['data'] as Map<String, dynamic>? ?? {},
          message:
              data['message'] as String? ?? 'Estado actualizado correctamente',
        );
      } else {
        final errorMsg =
            data['message'] as String? ??
            'Error al actualizar estado (Status: ${response.statusCode})';
        return ApiResponse.error(errorMsg, statusCode: response.statusCode);
      }
    } on FormatException catch (e) {
      return ApiResponse.error('Error al procesar la respuesta: $e');
    } catch (e) {
      return ApiResponse.error('Error de conexión: ${e.toString()}');
    }
  }

  /// Buscar usuarios localmente (filtrado)
  List<UserModel> searchUsers(List<UserModel> users, String query) {
    if (query.isEmpty) return users;

    final lowerQuery = query.toLowerCase();
    return users.where((user) {
      return (user.nombres.toLowerCase().contains(lowerQuery)) ||
          (user.apellidoPaterno.toLowerCase().contains(lowerQuery)) ||
          (user.apellidoMaterno.toLowerCase().contains(lowerQuery)) ||
          (user.dni.contains(lowerQuery)) ||
          (user.email?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }
}
