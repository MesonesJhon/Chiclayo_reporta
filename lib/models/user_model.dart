class UserModel {
  final int id;
  final String dni;
  final String nombres;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final String nombreCompleto;
  final String? email;
  final String? telefono;
  final String tipo;
  final DateTime fechaRegistro;
  final DateTime? ultimoLogin;

  UserModel({
    required this.id,
    required this.dni,
    required this.nombres,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.nombreCompleto,
    this.email,
    this.telefono,
    required this.tipo,
    required this.fechaRegistro,
    this.ultimoLogin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      dni: json['dni'] as String,
      nombres: json['nombres'] as String,
      apellidoPaterno: json['apellido_paterno'] as String,
      apellidoMaterno: json['apellido_materno'] as String,
      nombreCompleto: json['nombre_completo'] as String,
      email: json['email'] as String?,
      telefono: json['telefono'] as String?,
      tipo: json['tipo'] as String? ?? 'ciudadano',
      fechaRegistro: json['fecha_registro'] != null
          ? DateTime.parse(json['fecha_registro'] as String)
          : DateTime.now(),
      ultimoLogin: json['ultimo_login'] != null
          ? DateTime.parse(json['ultimo_login'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dni': dni,
      'nombres': nombres,
      'apellido_paterno': apellidoPaterno,
      'apellido_materno': apellidoMaterno,
      'nombre_completo': nombreCompleto,
      'email': email,
      'telefono': telefono,
      'tipo': tipo,
      'fecha_registro': fechaRegistro.toIso8601String(),
      'ultimo_login': ultimoLogin?.toIso8601String(),
    };
  }

  String get nombresCompletos => '$nombres $apellidoPaterno $apellidoMaterno';

  // Verificar si el usuario es administrador
  bool get isAdmin {
    final userType = tipo.toLowerCase().trim();
    return userType == 'administrador' || userType == 'admin';
  }

  // Verificar si el usuario es ciudadano
  bool get isCiudadano {
    final userType = tipo.toLowerCase().trim();
    return userType == 'ciudadano' || userType == 'user';
  }
}
