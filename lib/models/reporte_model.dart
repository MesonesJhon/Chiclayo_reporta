import 'categoria_model.dart';
import 'ubicacion_model.dart';
import 'archivo_multimedia_model.dart';

class ReporteModel {
  final int? id;
  final String codigoSeguimiento;
  final int? usuarioId;
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
    final multimediaData = json['multimedia'] ?? json['archivos'];

    return ReporteModel(
      id: _parseInt(json['reporte_id']) ?? _parseInt(json['id']),
      codigoSeguimiento: json['codigo_seguimiento'] as String? ?? '',
      usuarioId: _parseInt(json['usuario_id']),
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
}
