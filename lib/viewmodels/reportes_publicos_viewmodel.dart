import 'package:flutter/foundation.dart';
import '../services/reporte_service.dart';
import '../models/reporte_model.dart';

class ReportesPublicosViewModel with ChangeNotifier {
  final ReporteService _reporteService = ReporteService();

  bool _isLoading = false;
  String _errorMessage = '';
  List<ReporteModel> _reportes = [];

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<ReporteModel> get reportes => List.unmodifiable(_reportes);

  /// Cargar reportes públicos desde el servidor
  Future<void> cargarReportesPublicos() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _reporteService.obtenerReportesPublicos();

      _isLoading = false;

      if (response.success) {
        _reportes = response.data ?? [];
        _errorMessage = '';
      } else {
        _errorMessage = response.message;
        _reportes = [];
      }

      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al cargar reportes: $e';
      _reportes = [];
      notifyListeners();
    }
  }

  /// Refrescar la lista de reportes
  Future<void> refrescar() async {
    await cargarReportesPublicos();
  }
}
