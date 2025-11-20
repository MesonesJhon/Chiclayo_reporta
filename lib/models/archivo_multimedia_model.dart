class ArchivoMultimediaModel {
  final int? id;
  final String nombre;
  final String tipo; // 'foto' o 'video'
  final String url;
  final String? mimeType;
  final int? tamano;
  final bool esPrincipal;

  ArchivoMultimediaModel({
    this.id,
    required this.nombre,
    required this.tipo,
    required this.url,
    this.mimeType,
    this.tamano,
    this.esPrincipal = false,
  });

  factory ArchivoMultimediaModel.fromJson(Map<String, dynamic> json) {
    final rawTamano = json['tamano'] ?? json['tamaño'];
    bool esPrincipal = false;
    final rawPrincipal = json['es_principal'];
    if (rawPrincipal is bool) {
      esPrincipal = rawPrincipal;
    } else if (rawPrincipal is num) {
      esPrincipal = rawPrincipal != 0;
    } else if (rawPrincipal != null) {
      esPrincipal =
          rawPrincipal.toString().toLowerCase() == 'true' ||
          rawPrincipal.toString() == '1';
    }

    return ArchivoMultimediaModel(
      id: (json['id'] as num?)?.toInt(),
      nombre:
          (json['nombre'] ??
                  json['nombre_archivo'] ??
                  json['original_filename'])
              as String? ??
          '',
      tipo: json['tipo'] as String? ?? 'foto',
      url: (json['url'] ?? json['ruta_almacenamiento']) as String? ?? '',
      mimeType: (json['mime_type'] ?? json['formato']) as String?,
      tamano: rawTamano == null
          ? null
          : (rawTamano is num ? rawTamano.toInt() : int.tryParse('$rawTamano')),
      esPrincipal: esPrincipal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo,
      'nombre': nombre,
      'nombre_archivo': nombre,
      'url': url,
      'ruta_almacenamiento': url,
      'mime_type': mimeType,
      'tamano': tamano,
      'es_principal': esPrincipal,
    };
  }
}
