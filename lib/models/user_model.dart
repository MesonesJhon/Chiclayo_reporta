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
  final DateTime? fechaRegistro;
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
    this.fechaRegistro,
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
      fechaRegistro: _parseDateTime(json['fecha_registro']),
      ultimoLogin: _parseDateTime(json['ultimo_login']),
    );
  }

  /// Función auxiliar para parsear fechas en diferentes formatos
  static DateTime? _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return null;

    try {
      final dateString = dateValue.toString();

      // Intentar parsear como ISO 8601 primero
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        // Si falla, intentar parsear formato HTTP (RFC 7231)
        // Ejemplo: "Sat, 15 Nov 2025 19:20:11 GMT"
        if (dateString.contains('GMT') || dateString.contains('UTC')) {
          // Reemplazar nombres de días y zonas horarias comunes
          String cleaned = dateString
              .replaceAll(RegExp(r'^(Mon|Tue|Wed|Thu|Fri|Sat|Sun),?\s*'), '')
              .replaceAll(' GMT', '')
              .replaceAll(' UTC', '');

          // Mapear nombres de meses
          final monthMap = {
            'Jan': '01',
            'Feb': '02',
            'Mar': '03',
            'Apr': '04',
            'May': '05',
            'Jun': '06',
            'Jul': '07',
            'Aug': '08',
            'Sep': '09',
            'Oct': '10',
            'Nov': '11',
            'Dec': '12',
          };

          // Formato esperado: "15 Nov 2025 19:20:11"
          final parts = cleaned.split(' ');
          if (parts.length >= 4) {
            final day = parts[0].padLeft(2, '0');
            final month = monthMap[parts[1]] ?? '01';
            final year = parts[2];
            final time = parts.length > 3 ? parts[3] : '00:00:00';

            final isoString = '$year-$month-$day $time';
            return DateTime.parse(isoString);
          }
        }

        // Si todo falla, retornar null
        print('⚠️ No se pudo parsear la fecha: $dateString');
        return null;
      }
    } catch (e) {
      print('⚠️ Error parseando fecha: $e');
      return null;
    }
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
      'fecha_registro': fechaRegistro?.toIso8601String(),
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
