class AuthResponse {
  final String accessToken;

  AuthResponse({required this.accessToken});

  // Crear AuthResponse desde JSON
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(accessToken: json['access_token'] ?? '');
  }

  // Convertir a JSON si fuera necesario
  Map<String, dynamic> toJson() {
    return {'access_token': accessToken};
  }
}
