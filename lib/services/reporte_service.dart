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

        return ApiResponse.error(errorMsg, statusCode: response.statusCode);
      }
    } on FormatException catch (e) {
      return ApiResponse.error('Error al procesar la respuesta: $e');
    } catch (e) {
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

  /// Editar un reporte existente
  Future<ApiResponse<CrearReporteResponse>> editarReporte({
    required int reporteId,
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
      final ubicacionData = {
        'direccion': direccion ?? '',
        'latitud': latitud,
        'longitud': longitud,
        'distrito': distrito ?? '',
        'referencia': referencia ?? '',
        'gmaps_place_id': gmapsPlaceId ?? '',
      };

      final response = await _apiService
          .put('${ApiConstants.reportesEditar}/$reporteId', {
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
          message: data['message'] as String? ?? 'Reporte actualizado',
        );
      } else {
        return ApiResponse.error(
          data['message'] as String? ?? 'Error al actualizar el reporte',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  /// Eliminar un reporte
  Future<ApiResponse<bool>> eliminarReporte(int reporteId) async {
    try {
      final response = await _apiService.delete(
        '${ApiConstants.reportesEliminar}/$reporteId',
      );
      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['code'] == 1) {
        return ApiResponse.success(
          true,
          message: data['message'] as String? ?? 'Reporte eliminado',
        );
      } else {
        return ApiResponse.error(
          data['message'] as String? ?? 'Error al eliminar el reporte',
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

        return ApiResponse.error(errorMsg, statusCode: response.statusCode);
      }
    } on FormatException catch (e) {
      return ApiResponse.error('Error al procesar la respuesta: $e');
    } catch (e) {
      return ApiResponse.error('Error de conexión: ${e.toString()}');
    }
  }

  /// Obtener todos los reportes públicos
  Future<ApiResponse<List<ReporteModel>>> obtenerReportesPublicos() async {
    try {
      final response = await _apiService.get(ApiConstants.reportesPublicos);

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

        return ApiResponse.error(errorMsg, statusCode: response.statusCode);
      }
    } on FormatException catch (e) {
      return ApiResponse.error('Error al procesar la respuesta: $e');
    } catch (e) {
      return ApiResponse.error('Error de conexión: ${e.toString()}');
    }
  }

  /// Obtener todos los reportes (para administradores)
  Future<ApiResponse<List<ReporteModel>>> obtenerTodosReportes() async {
    try {
      final response = await _apiService.get(ApiConstants.reportesTodos);

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
            final reportesList = <ReporteModel>[];
            final items = data['data'] as List;

            print('📦 Procesando ${items.length} reportes...');

            for (var item in items) {
              try {
                if (item is Map<String, dynamic>) {
                  final reporte = ReporteModel.fromJson(item);
                  reportesList.add(reporte);
                }
              } catch (e, stackTrace) {
                // Log del error pero continuar con los demás reportes
                print('⚠️ Error al parsear un reporte: $e');
                print('   Stack trace: $stackTrace');
                // Continuar con el siguiente reporte en lugar de fallar todo
              }
            }

            print(
              '✅ Reportes parseados correctamente: ${reportesList.length} de ${items.length}',
            );

            return ApiResponse.success(
              reportesList,
              message: data['message'] as String? ?? '',
            );
          } catch (e) {
            print('❌ Error general al procesar los reportes: $e');
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

        return ApiResponse.error(errorMsg, statusCode: response.statusCode);
      }
    } on FormatException catch (e) {
      return ApiResponse.error('Error al procesar la respuesta: $e');
    } catch (e) {
      return ApiResponse.error('Error de conexión: ${e.toString()}');
    }
  }

  /// Actualizar el estado de un reporte
  Future<ApiResponse<ReporteModel>> actualizarEstadoReporte({
    required int reporteId,
    required String nuevoEstado,
  }) async {
    try {
      // Validar estados permitidos (deben coincidir con el ENUM de la BD)
      const estadosValidos = [
        'pendiente',
        'en_proceso', // Con guión bajo, no espacio
        'resuelto',
        'cerrado', // No 'rechazado'
      ];
      if (!estadosValidos.contains(nuevoEstado.toLowerCase())) {
        return ApiResponse.error(
          'Estado no válido. Valores permitidos: ${estadosValidos.join(", ")}',
        );
      }

      final endpoint =
          '${ApiConstants.reportesActualizarEstado}/estado/$reporteId';
      final body = {'estado': nuevoEstado.toLowerCase()};

      print('🔄 Actualizando estado del reporte:');
      print('   Endpoint: $endpoint');
      print('   Body: $body');
      print('   Reporte ID: $reporteId');
      print('   Nuevo Estado: $nuevoEstado');

      final response = await _apiService.put(endpoint, body);

      print('📥 Respuesta del servidor:');
      print('   Status Code: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.body.isEmpty) {
        return ApiResponse.error(
          'Respuesta vacía del servidor',
          statusCode: response.statusCode,
        );
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['code'] == 1) {
        // El API devuelve el reporte actualizado
        if (data['data'] != null) {
          try {
            final reporteActualizado = ReporteModel.fromJson(
              data['data'] as Map<String, dynamic>,
            );

            return ApiResponse.success(
              reporteActualizado,
              message:
                  data['message'] as String? ??
                  'Estado actualizado correctamente',
            );
          } catch (e) {
            return ApiResponse.error(
              'Error al procesar el reporte actualizado: $e',
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
            'Error al actualizar estado (Status: ${response.statusCode})';
        return ApiResponse.error(errorMsg, statusCode: response.statusCode);
      }
    } on FormatException catch (e) {
      return ApiResponse.error('Error al procesar la respuesta: $e');
    } catch (e) {
      return ApiResponse.error('Error de conexión: ${e.toString()}');
    }
  }
}
