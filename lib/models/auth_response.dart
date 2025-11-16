import 'package:chiclayo_reporte/models/user_model.dart';

class AuthResponse {
  final int code;
  final dynamic data;
  final String message;
  final String? token;
  final UserModel? user;

  AuthResponse({
    required this.code,
    required this.data,
    required this.message,
    this.token,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return AuthResponse(
      code: json['code'] ?? 0,
      data: data,
      message: json['message'] ?? '',
      token: data?['token'] as String?,
      user: data?['user'] != null
          ? UserModel.fromJson(data!['user'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isSuccess => code == 1;
}
