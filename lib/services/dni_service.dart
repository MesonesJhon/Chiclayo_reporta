import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dni_response.dart';
import '../utils/constants.dart';

class DniService {
  static Future<DniResponse> consultarDni(String numeroDni) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.decolectaBaseUrl}${ApiConstants.consultaDni}?numero=$numeroDni',
      );

      print('🔍 Consultando DNI: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${ApiConstants.decolectaApiKey}',
          'Content-Type': 'application/json',
          'From': 'postman', // Agregar este header que pide la API
        },
      );

      print('📥 Status Code: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        // Verificar si la respuesta tiene datos válidos
        if (jsonResponse['document_number'] != null) {
          return DniResponse.fromJson(jsonResponse);
        } else {
          return DniResponse(success: false, error: 'DNI no encontrado');
        }
      } else if (response.statusCode == 404) {
        return DniResponse(
          success: false,
          error: 'DNI no encontrado en RENIEC',
        );
      } else {
        return DniResponse(
          success: false,
          error: 'Error HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error en DniService: $e');
      return DniResponse(success: false, error: 'Error de conexión: $e');
    }
  }
}
