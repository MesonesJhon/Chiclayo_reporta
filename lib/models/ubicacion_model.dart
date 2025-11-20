class UbicacionModel {
  final int? id;
  final String? direccion;
  final double latitud;
  final double longitud;
  final String? distrito;
  final String? referencia;
  final String? gmapsPlaceId;

  UbicacionModel({
    this.id,
    this.direccion,
    required this.latitud,
    required this.longitud,
    this.distrito,
    this.referencia,
    this.gmapsPlaceId,
  });

  factory UbicacionModel.fromJson(Map<String, dynamic> json) {
    return UbicacionModel(
      id: (json['id'] as num?)?.toInt(),
      direccion: json['direccion'] as String?,
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      distrito: json['distrito'] as String?,
      referencia: json['referencia'] as String?,
      gmapsPlaceId: (json['gmaps_place_id'] ?? json['place_id']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'direccion': direccion,
      'latitud': latitud,
      'longitud': longitud,
      'distrito': distrito,
      'referencia': referencia,
      'gmaps_place_id': gmapsPlaceId,
    };
  }
}
