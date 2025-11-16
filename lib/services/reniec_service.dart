import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class ReniecService {
  static const String _baseUrl = 'https://api.decolecta.pe';
  static const String _apiKey = 'TU_API_KEY'; // Reemplazar con tu API Key
  static const String _apiSecret = 'TU_API_SECRET'; // Reemplazar con tu Secret

  // Método para generar el hash requerido por Decolecta
  String _generateHash(String timestamp, String method, String endpoint) {
    final data = '$timestamp$method$endpoint';
    final bytes = utf8.encode(data);
    final hmac = Hmac(sha256, utf8.encode(_apiSecret));
    final digest = hmac.convert(bytes);
    return digest.toString();
  }

  // Método para consultar DNI según documentación de Decolecta
  Future<Map<String, dynamic>> consultarDni(String dni) async {
    try {
      final timestamp = DateTime.now().toUtc().toIso8601String();
      final method = 'POST';
      final endpoint = '/v1/reniec/dni';

      // Generar hash de autenticación
      final hash = _generateHash(timestamp, method, endpoint);

      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: {
          'X-API-Key': _apiKey,
          'X-Timestamp': timestamp,
          'X-Hash': hash,
          'Content-Type': 'application/json',
        },
        body: json.encode({'dni': dni}),
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Procesar respuesta según estructura de Decolecta
        return _procesarRespuestaDecolecta(data);
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'error': 'DNI no encontrado en RENIEC',
          'codigo_error': 'DNI_NO_ENCONTRADO',
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Error de autenticación con Decolecta',
          'codigo_error': 'AUTH_ERROR',
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Error en la consulta',
          'codigo_error': errorData['code'] ?? 'UNKNOWN_ERROR',
        };
      }
    } on SocketException catch (e) {
      return {
        'success': false,
        'error': 'Error de conexión: ${e.message}',
        'codigo_error': 'CONNECTION_ERROR',
      };
    } on http.ClientException catch (e) {
      return {
        'success': false,
        'error': 'Error del cliente: $e',
        'codigo_error': 'CLIENT_ERROR',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error inesperado: $e',
        'codigo_error': 'UNEXPECTED_ERROR',
      };
    }
  }

  // Procesar la respuesta específica de Decolecta
  Map<String, dynamic> _procesarRespuestaDecolecta(Map<String, dynamic> data) {
    try {
      // Estructura esperada según documentación de Decolecta
      final persona = data['data'] ?? data;

      final nombres = persona['nombres'] ?? '';
      final apellidoPaterno =
          persona['apellidoPaterno'] ?? persona['apellido_paterno'] ?? '';
      final apellidoMaterno =
          persona['apellidoMaterno'] ?? persona['apellido_materno'] ?? '';
      final numeroDocumento =
          persona['dni'] ?? persona['numeroDocumento'] ?? '';

      // Validar que tengamos los datos mínimos
      if (nombres.isEmpty || apellidoPaterno.isEmpty) {
        return {
          'success': false,
          'error': 'Datos incompletos en la respuesta',
          'codigo_error': 'INCOMPLETE_DATA',
        };
      }

      // Construir nombre completo en el formato requerido
      final nombreCompleto = '$apellidoPaterno $apellidoMaterno $nombres'
          .trim();

      return {
        'success': true,
        'data': {
          'nombres': nombres,
          'apellido_paterno': apellidoPaterno,
          'apellido_materno': apellidoMaterno,
          'nombre_completo': nombreCompleto,
          'dni': numeroDocumento,
          'respuesta_raw': data, // Guardar respuesta completa para debugging
        },
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error procesando respuesta: $e',
        'codigo_error': 'PROCESSING_ERROR',
      };
    }
  }

  // Método para validar formato de DNI
  bool validarFormatoDni(String dni) {
    if (dni.length != 8) return false;

    // Verificar que sean solo números
    final regex = RegExp(r'^[0-9]+$');
    return regex.hasMatch(dni);
  }

  // Método para obtener estado del servicio Decolecta
  Future<Map<String, dynamic>> verificarEstadoServicio() async {
    try {
      final timestamp = DateTime.now().toUtc().toIso8601String();
      final method = 'GET';
      final endpoint = '/v1/status';

      final hash = _generateHash(timestamp, method, endpoint);

      final response = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: {
          'X-API-Key': _apiKey,
          'X-Timestamp': timestamp,
          'X-Hash': hash,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'estado': 'operativo',
          'mensaje': 'Servicio Decolecta disponible',
        };
      } else {
        return {
          'success': false,
          'estado': 'inactivo',
          'mensaje': 'Servicio Decolecta no disponible',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'estado': 'error',
        'mensaje': 'Error verificando servicio: $e',
      };
    }
  }
}
