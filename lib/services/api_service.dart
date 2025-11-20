import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String _baseUrl = ApiConstants.backendBaseUrl;
  String? _token;

  void setToken(String token) {
    // Limpiar el token de espacios y caracteres no deseados
    _token = token.trim();
    print(
      '✅ Token configurado en ApiService: ${_token!.substring(0, _token!.length > 20 ? 20 : _token!.length)}...',
    );
  }

  void clearToken() {
    _token = null;
  }

  bool get hasToken => _token != null;

  String? get token => _token;

  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};

    if (_token != null && _token!.isNotEmpty) {
      // Asegurar que no haya espacios extra
      final cleanToken = _token!.trim();
      headers['Authorization'] = 'Bearer $cleanToken';
    } else {
      print('⚠️ ADVERTENCIA: _token es null o vacío en _headers');
    }

    return headers;
  }

  Map<String, String> get _headersWithoutContentType {
    final headers = <String, String>{};

    if (_token != null && _token!.isNotEmpty) {
      // Asegurar que no haya espacios extra
      final cleanToken = _token!.trim();
      headers['Authorization'] = 'Bearer $cleanToken';
    } else {
      print(
        '⚠️ ADVERTENCIA: _token es null o vacío en _headersWithoutContentType',
      );
    }

    return headers;
  }

  Future<http.Response> get(String endpoint) async {
    try {
      final headers = _headers;
      print('GET $endpoint');
      print('Headers: ${headers.keys}');
      if (headers.containsKey('Authorization')) {
        print(
          'Token presente: ${headers['Authorization']!.substring(0, 20)}...',
        );
      } else {
        print('⚠️ ADVERTENCIA: No hay token en los headers');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      if (response.statusCode == 401) {
        print('⚠️ Error 401: Token inválido o no autorizado');
        print('Response body: ${response.body}');
      }

      return response;
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
        body: json.encode(data),
      );
      return response;
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<http.Response> postMultipart(
    String endpoint,
    Map<String, String> fields,
    List<http.MultipartFile> files,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl$endpoint'),
      );

      // Agregar headers de autorización
      final headers = _headersWithoutContentType;
      request.headers.addAll(headers);

      // Log para debugging
      print('POST Multipart $endpoint');
      print('Headers: ${headers.keys}');
      if (headers.containsKey('Authorization')) {
        print(
          'Token presente: ${headers['Authorization']!.substring(0, 20)}...',
        );
      } else {
        print('⚠️ ADVERTENCIA: No hay token en los headers multipart');
      }

      // Agregar campos
      request.fields.addAll(fields);

      // Agregar archivos
      request.files.addAll(files);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      if (response.statusCode == 401) {
        print('⚠️ Error 401 en multipart: Token inválido o no autorizado');
        print('Response body: ${response.body}');
      }

      return response;
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
        body: json.encode(data),
      );
      return response;
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
