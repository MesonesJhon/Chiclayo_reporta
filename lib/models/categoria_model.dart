class CategoriaModel {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? icono;
  final String? color;
  final String? prioridad;
  final String? tiempoResolucionEsperado;
  final bool activo;

  CategoriaModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.icono,
    this.color,
    this.prioridad,
    this.tiempoResolucionEsperado,
    required this.activo,
  });

  factory CategoriaModel.fromJson(Map<String, dynamic> json) {
    // tiempo_resolucion_esperado puede venir como int o String
    String? tiempoResolucion;
    final tiempoResolucionValue = json['tiempo_resolucion_esperado'];
    if (tiempoResolucionValue != null) {
      if (tiempoResolucionValue is int) {
        tiempoResolucion = tiempoResolucionValue.toString();
      } else if (tiempoResolucionValue is String) {
        tiempoResolucion = tiempoResolucionValue;
      }
    }

    // Parsear 'activo' que puede venir como bool, int (0/1), o String ('true'/'false')
    bool activoValue = true;
    final activoData = json['activo'];
    if (activoData != null) {
      if (activoData is bool) {
        activoValue = activoData;
      } else if (activoData is int) {
        activoValue = activoData == 1;
      } else if (activoData is String) {
        activoValue = activoData.toLowerCase() == 'true' || activoData == '1';
      }
    }

    return CategoriaModel(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      icono: json['icono'] as String?,
      color: json['color'] as String?,
      prioridad: json['prioridad'] as String?,
      tiempoResolucionEsperado: tiempoResolucion,
      activo: activoValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'icono': icono,
      'color': color,
      'prioridad': prioridad,
      'tiempo_resolucion_esperado': tiempoResolucionEsperado,
      'activo': activo,
    };
  }
}
