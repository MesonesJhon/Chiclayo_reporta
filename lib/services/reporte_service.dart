import 'dart:convert';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../models/categoria_model.dart';
import '../models/crear_reporte_response.dart';
import '../models/api_response.dart';
import '../models/reporte_model.dart';

class ReporteService {
  final ApiService _apiService = ApiService();

  /// Obtener todas las categorías activas
  Future<ApiResponse<List<CategoriaModel>>> obtenerCategorias() async {
    try {
      final response = await _apiService.get(ApiConstants.reportesCategorias);

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Verificar si la respuesta es válida
      if (response.body.isEmpty) {
        return ApiResponse.error(
          'Respuesta vacía del servidor',
          statusCode: response.statusCode,
        );
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['code'] == 1) {
        // Verificar que data['data'] existe y es una lista
        if (data['data'] != null && data['data'] is List) {
          try {
            final categoriasList = (data['data'] as List)
                .map((item) {
                  try {
                    return CategoriaModel.fromJson(
                      item as Map<String, dynamic>,
                    );
                  } catch (e) {
                    print('Error parseando categoría: $e');
                    return null;
                  }
                })
                .whereType<CategoriaModel>()
                .toList();

            return ApiResponse.success(
              categoriasList,
              message: data['message'] as String? ?? '',
            );
          } catch (e) {
            return ApiResponse.error(
              'Error al procesar las categorías: $e',
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
            'Error al obtener categorías (Status: ${response.statusCode})';
        print('Error en respuesta: $errorMsg');
        return ApiResponse.error(errorMsg, statusCode: response.statusCode);
      }
    } on FormatException catch (e) {
      print('FormatException: $e');
      return ApiResponse.error('Error al procesar la respuesta: $e');
    } catch (e) {
      print('Error obteniendo categorías: $e');
      return ApiResponse.error('Error de conexión: ${e.toString()}');
    }
  }

  /// Crear un nuevo reporte con archivos
  Future<ApiResponse<CrearReporteResponse>> crearReporte({
    required int categoriaId,
    required String titulo,
    required String descripcion,
    required double latitud,
    required double longitud,
    String? direccion,
    String? distrito,
    String? referencia,
    String? gmapsPlaceId,
    String prioridad = 'media',
    bool esPublico = false,
    List<Map<String, dynamic>>? multimedia,
  }) async {
    try {
      // Preparar datos de ubicación
      final ubicacionData = {
        'direccion': direccion ?? '',
        'latitud': latitud,
        'longitud': longitud,
        'distrito': distrito ?? '',
        'referencia': referencia ?? '',
        'gmaps_place_id': gmapsPlaceId ?? '',
      };

      final response = await _apiService.post(ApiConstants.reportesCrear, {
        'categoria_id': categoriaId,
        'titulo': titulo,
        'descripcion': descripcion,
        'prioridad': prioridad,
        'es_publico': esPublico,
        'ubicacion': ubicacionData,
        'multimedia': multimedia ?? [],
      });

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['code'] == 1) {
        final reporteResponse = CrearReporteResponse.fromJson(
          data['data'] as Map<String, dynamic>,
        );

        return ApiResponse.success(
          reporteResponse,
          message: data['message'] as String? ?? 'Reporte creado exitosamente',
        );
      } else {
        return ApiResponse.error(
          data['message'] as String? ?? 'Error al crear el reporte',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  /// Obtener los reportes del usuario actual
  Future<ApiResponse<List<ReporteModel>>> obtenerMisReportes() async {
    try {
      final response = await _apiService.get(ApiConstants.reportesMisReportes);

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

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
            final reportesList = (data['data'] as List)
                .map((item) {
                  try {
                    return ReporteModel.fromJson(item as Map<String, dynamic>);
                  } catch (e) {
                    print('Error parseando reporte: $e');
                    return null;
                  }
                })
                .whereType<ReporteModel>()
                .toList();

            return ApiResponse.success(
              reportesList,
              message: data['message'] as String? ?? '',
            );
          } catch (e) {
            return ApiResponse.error(
              'Error al procesar los reportes: $e',
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
            'Error al obtener reportes (Status: ${response.statusCode})';
        print('Error en respuesta: $errorMsg');
        return ApiResponse.error(errorMsg, statusCode: response.statusCode);
      }
    } on FormatException catch (e) {
      print('FormatException: $e');
      return ApiResponse.error('Error al procesar la respuesta: $e');
    } catch (e) {
      print('Error obteniendo reportes: $e');
      return ApiResponse.error('Error de conexión: ${e.toString()}');
    }
  }
}
