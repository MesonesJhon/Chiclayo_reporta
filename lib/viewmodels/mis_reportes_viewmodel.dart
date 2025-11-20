import 'package:flutter/material.dart';
import '../models/reporte_model.dart';
import '../models/api_response.dart';
import '../services/reporte_service.dart';

class MisReportesViewModel extends ChangeNotifier {
  final ReporteService _service = ReporteService();

  List<ReporteModel> _reportes = [];
  List<ReporteModel> get reportes => _reportes;

  bool isLoading = false;
  String error = "";
  String filtro = "Todos";

  Future<void> cargarReportes() async {
    isLoading = true;
    error = "";
    notifyListeners();

    final response = await _service.obtenerMisReportes();

    if (response.success && response.data != null) {
      _reportes = response.data!;
    } else {
      error = response.message;
    }

    isLoading = false;
    notifyListeners();
  }

  List<ReporteModel> get reportesFiltrados {
    switch (filtro) {
      case "Activos":
        return _reportes.where((r) => r.estado != "resuelto").toList();
      case "Resueltos":
        return _reportes.where((r) => r.estado == "resuelto").toList();
      case "Pendientes":
        return _reportes.where((r) => r.estado == "pendiente").toList();
      default:
        return _reportes;
    }
  }

  void setFiltro(String valor) {
    filtro = valor;
    notifyListeners();
  }

  Future<ApiResponse<bool>> eliminarReporte(int reporteId) async {
    final response = await _service.eliminarReporte(reporteId);
    if (response.success) {
      _reportes.removeWhere((r) => r.id == reporteId);
      notifyListeners();
    }
    return response;
  }
}
