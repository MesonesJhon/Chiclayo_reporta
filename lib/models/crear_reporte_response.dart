class CrearReporteResponse {
  final int? reporteId;
  final String codigoSeguimiento;
  final String categoria;
  final String titulo;
  final String estado;
  final String fechaCreacion;
  final List<Map<String, dynamic>> archivos;

  CrearReporteResponse({
    required this.reporteId,
    required this.codigoSeguimiento,
    required this.categoria,
    required this.titulo,
    required this.estado,
    required this.fechaCreacion,
    required this.archivos,
  });

  factory CrearReporteResponse.fromJson(Map<String, dynamic> json) {
    return CrearReporteResponse(
      reporteId: (json['reporte_id'] as num?)?.toInt(),
      codigoSeguimiento: json['codigo_seguimiento'] as String? ?? '',
      categoria: json['categoria'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      estado: json['estado'] as String? ?? '',
      fechaCreacion: json['fecha_creacion'] as String? ?? '',
      archivos: json['archivos'] != null
          ? (json['archivos'] as List)
                .map(
                  (item) =>
                      item is Map<String, dynamic> ? item : <String, dynamic>{},
                )
                .toList()
          : [],
    );
  }
}
