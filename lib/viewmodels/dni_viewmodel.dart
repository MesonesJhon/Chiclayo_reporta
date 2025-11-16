import 'package:flutter/material.dart';
import 'package:chiclayo_reporte/models/dni_response.dart';
import 'package:chiclayo_reporte/services/dni_service.dart';

class DniViewModel with ChangeNotifier {
  DniData? _dniData;
  bool _loading = false;
  String? _error;

  DniData? get dniData => _dniData;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> consultarDni(String dni) async {
    _loading = true;
    _error = null;
    notifyListeners();

    final response = await DniService.consultarDni(dni);

    _loading = false;

    if (response.success && response.data != null) {
      _dniData = response.data;
      _error = null;
    } else {
      _dniData = null;
      _error = response.error ?? 'Error desconocido';
    }

    notifyListeners();
  }

  void clear() {
    _dniData = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }
}
