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

  /// Actualizar el estado de un reporte
  Future<ApiResponse<bool>> actualizarEstadoReporte(
    int reporteId,
    String nuevoEstado,
  ) async {
    // Actualización optimista
    final index = _reportes.indexWhere((r) => r.id == reporteId);
    ReporteModel? reporteOriginal;

    if (index != -1) {
      reporteOriginal = _reportes[index];
      // Crear una copia con el nuevo estado
      _reportes[index] = ReporteModel(
        id: reporteOriginal.id,
        codigoSeguimiento: reporteOriginal.codigoSeguimiento,
        usuarioId: reporteOriginal.usuarioId,
        categoriaId: reporteOriginal.categoriaId,
        categoria: reporteOriginal.categoria,
        ubicacionId: reporteOriginal.ubicacionId,
        ubicacion: reporteOriginal.ubicacion,
        titulo: reporteOriginal.titulo,
        descripcion: reporteOriginal.descripcion,
        estado: nuevoEstado,
        prioridad: reporteOriginal.prioridad,
        esPublico: reporteOriginal.esPublico,
        fechaCreacion: reporteOriginal.fechaCreacion,
        fechaActualizacion: DateTime.now(),
        fechaCierre: reporteOriginal.fechaCierre,
        archivos: reporteOriginal.archivos,
      );
      notifyListeners();
    }

    // Llamar al servicio
    final response = await _service.actualizarEstadoReporte(
      reporteId: reporteId,
      nuevoEstado: nuevoEstado,
    );

    if (response.success && response.data != null) {
      // Actualizar con los datos del servidor
      if (index != -1) {
        _reportes[index] = response.data!;
        notifyListeners();
      }
      return ApiResponse.success(true, message: response.message);
    } else {
      // Revertir si falla
      if (index != -1 && reporteOriginal != null) {
        _reportes[index] = reporteOriginal;
        notifyListeners();
      }
      return ApiResponse.error(response.message);
    }
  }
}
