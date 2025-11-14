import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:chiclayo_reporte/models/authResponse_model.dart';
import 'package:chiclayo_reporte/models/user_model.dart';

class UserService {
  final String baseUrl = 'https://jhonmm.pythonanywhere.com/auth';

  Future<AuthResponse> login(UserModel user) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': user.username,
          'password': user.password,
        }),
      );

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al hacer login');
      }
    } catch (e) {
      throw Exception('Error en la conexión: $e');
    }
  }
}
