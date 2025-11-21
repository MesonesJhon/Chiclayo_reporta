import 'categoria_model.dart';
import 'ubicacion_model.dart';
import 'archivo_multimedia_model.dart';
import 'user_model.dart';

class ReporteModel {
  final int? id;
  final String codigoSeguimiento;
  final int? usuarioId;
  final UserModel? usuario; // Información del usuario que creó el reporte
  final int categoriaId;
  final CategoriaModel? categoria;
  final int? ubicacionId;
  final UbicacionModel? ubicacion;
  final String titulo;
  final String descripcion;
  final String estado; // 'pendiente', 'en_proceso', 'resuelto', 'cancelado'
  final String prioridad; // 'alta', 'media', 'baja'
  final bool esPublico;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;
  final DateTime? fechaCierre;
  final List<ArchivoMultimediaModel> archivos;

  ReporteModel({
    this.id,
    required this.codigoSeguimiento,
    this.usuarioId,
    this.usuario,
    required this.categoriaId,
    this.categoria,
    this.ubicacionId,
    this.ubicacion,
    required this.titulo,
    required this.descripcion,
    this.estado = 'pendiente',
    this.prioridad = 'media',
    this.esPublico = false,
    this.fechaCreacion,
    this.fechaActualizacion,
    this.fechaCierre,
    this.archivos = const [],
  });

  factory ReporteModel.fromJson(Map<String, dynamic> json) {
    final categoriaData = json['categoria'] as Map<String, dynamic>?;
    final ubicacionData = json['ubicacion'] as Map<String, dynamic>?;

    // Algunos backends pueden usar otros nombres para el usuario
    final dynamic rawUsuario =
        json['usuario'] ?? json['user'] ?? json['ciudadano'];
    final Map<String, dynamic>? usuarioData = rawUsuario is Map<String, dynamic>
        ? rawUsuario
        : null;

    final multimediaData = json['multimedia'] ?? json['archivos'];

    // Parsear usuario de forma segura (si falla, el reporte se crea sin usuario)
    UserModel? usuario;
    if (usuarioData != null) {
      try {
        // Caso 1: estructura completa como en /api/usuarios
        if (usuarioData.containsKey('dni') &&
            usuarioData.containsKey('nombres') &&
            usuarioData.containsKey('apellido_paterno') &&
            usuarioData.containsKey('apellido_materno')) {
          usuario = UserModel.fromJson(usuarioData);
        }
        // Caso 2: estructura reducida de /api/reportes/todos
        else if (usuarioData.containsKey('nombre_completo')) {
          final String nombreCompleto =
              usuarioData['nombre_completo'] as String? ?? '';

          usuario = UserModel(
            id: _parseInt(usuarioData['id']) ?? 0,
            dni: (usuarioData['dni'] as String?) ?? '',
            nombres: usuarioData['nombres'] as String? ?? nombreCompleto,
            apellidoPaterno: usuarioData['apellido_paterno'] as String? ?? '',
            apellidoMaterno: usuarioData['apellido_materno'] as String? ?? '',
            nombreCompleto: nombreCompleto,
            email: usuarioData['email'] as String?,
            telefono: usuarioData['telefono'] as String?,
            tipo: usuarioData['tipo'] as String? ?? 'ciudadano',
            estado: usuarioData['estado'] as String? ?? 'activo',
            fechaRegistro: null,
            ultimoLogin: null,
          );
        } else {
          print(
            '⚠️ Usuario en reporte no tiene campos esperados: ${usuarioData.keys}',
          );
        }
      } catch (e, stackTrace) {
        // Si falla el parsing del usuario, continuar sin él
        print('⚠️ Error al parsear usuario en reporte: $e');
        print('   Stack trace: $stackTrace');
        print(
          '   Datos del usuario: ${usuarioData.toString().substring(0, usuarioData.toString().length > 200 ? 200 : usuarioData.toString().length)}',
        );
        usuario = null;
      }
    }

    // Obtener usuarioId desde varios posibles campos o desde el propio usuario
    final int? usuarioId = _parseInt(
      json['usuario_id'] ??
          json['user_id'] ??
          json['usuarioId'] ??
          (usuarioData != null ? usuarioData['id'] : null),
    );

    return ReporteModel(
      id: _parseInt(json['reporte_id']) ?? _parseInt(json['id']),
      codigoSeguimiento: json['codigo_seguimiento'] as String? ?? '',
      usuarioId: usuarioId,
      usuario: usuario,
      categoriaId:
          _parseInt(json['categoria_id']) ??
          _parseInt(categoriaData != null ? categoriaData['id'] : null) ??
          0,
      categoria: categoriaData != null
          ? CategoriaModel.fromJson(categoriaData)
          : null,
      ubicacionId:
          _parseInt(json['ubicacion_id']) ??
          _parseInt(ubicacionData != null ? ubicacionData['id'] : null),
      ubicacion: ubicacionData != null
          ? UbicacionModel.fromJson(ubicacionData)
          : null,
      titulo: json['titulo'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      estado: json['estado'] as String? ?? 'pendiente',
      prioridad: json['prioridad'] as String? ?? 'media',
      esPublico: _parseBool(json['es_publico']),
      fechaCreacion: _parseDate(json['fecha_creacion']),
      fechaActualizacion: _parseDate(json['fecha_actualizacion']),
      fechaCierre: _parseDate(json['fecha_cierre']),
      archivos: multimediaData is List
          ? multimediaData
                .whereType<Map<String, dynamic>>()
                .map(ArchivoMultimediaModel.fromJson)
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo_seguimiento': codigoSeguimiento,
      'usuario_id': usuarioId,
      'categoria_id': categoriaId,
      'ubicacion_id': ubicacionId,
      'titulo': titulo,
      'descripcion': descripcion,
      'estado': estado,
      'prioridad': prioridad,
      'es_publico': esPublico,
      'fecha_creacion': fechaCreacion?.toIso8601String(),
      'fecha_actualizacion': fechaActualizacion?.toIso8601String(),
      'fecha_cierre': fechaCierre?.toIso8601String(),
      'multimedia': archivos.map((e) => e.toJson()).toList(),
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final lower = value.toString().toLowerCase();
    return lower == 'true' || lower == '1';
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  ReporteModel copyWith({
    int? id,
    String? codigoSeguimiento,
    int? usuarioId,
    UserModel? usuario,
    int? categoriaId,
    CategoriaModel? categoria,
    int? ubicacionId,
    UbicacionModel? ubicacion,
    String? titulo,
    String? descripcion,
    String? estado,
    String? prioridad,
    bool? esPublico,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    DateTime? fechaCierre,
    List<ArchivoMultimediaModel>? archivos,
  }) {
    return ReporteModel(
      id: id ?? this.id,
      codigoSeguimiento: codigoSeguimiento ?? this.codigoSeguimiento,
      usuarioId: usuarioId ?? this.usuarioId,
      usuario: usuario ?? this.usuario,
      categoriaId: categoriaId ?? this.categoriaId,
      categoria: categoria ?? this.categoria,
      ubicacionId: ubicacionId ?? this.ubicacionId,
      ubicacion: ubicacion ?? this.ubicacion,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      estado: estado ?? this.estado,
      prioridad: prioridad ?? this.prioridad,
      esPublico: esPublico ?? this.esPublico,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      fechaCierre: fechaCierre ?? this.fechaCierre,
      archivos: archivos ?? this.archivos,
    );
  }
}
