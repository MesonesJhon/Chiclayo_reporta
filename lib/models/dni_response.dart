class DniResponse {
  final bool success;
  final DniData? data;
  final String? error;

  DniResponse({required this.success, this.data, this.error});

  factory DniResponse.fromJson(Map<String, dynamic> json) {
    return DniResponse(
      success:
          json['success'] ??
          true, // La API no devuelve 'success', asumimos true
      data: json.isNotEmpty
          ? DniData.fromJson(json)
          : null, // La respuesta ES los datos directamente
      error: null,
    );
  }
}

class DniData {
  final String dni;
  final String nombres;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final String nombreCompleto;

  DniData({
    required this.dni,
    required this.nombres,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.nombreCompleto,
  });

  factory DniData.fromJson(Map<String, dynamic> json) {
    return DniData(
      dni: json['document_number']?.toString() ?? '',
      nombres: json['first_name'] ?? '',
      apellidoPaterno: json['first_last_name'] ?? '',
      apellidoMaterno: json['second_last_name'] ?? '',
      nombreCompleto: json['full_name'] ?? '',
    );
  }
}
