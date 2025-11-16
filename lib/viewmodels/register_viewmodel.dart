import 'package:flutter/foundation.dart';
import '../services/dni_service.dart';

class RegisterViewModel with ChangeNotifier {
  // Campos del formulario
  String _dni = '';
  String _password = '';
  String _confirmPassword = '';
  String _email = '';
  String _telefono = '';

  // Estado de verificación DNI
  bool _dniVerified = false;
  bool _consultandoReniec = false;
  String _nombres = '';
  String _apellidoPaterno = '';
  String _apellidoMaterno = '';
  String _nombreCompleto = '';

  // Estado del servicio
  String _estadoServicio = '';
  String _errorMessage = '';

  // Getters
  String get dni => _dni;
  String get password => _password;
  String get confirmPassword => _confirmPassword;
  String get email => _email;
  String get telefono => _telefono;
  bool get dniVerified => _dniVerified;
  bool get consultandoReniec => _consultandoReniec;
  String get nombres => _nombres;
  String get apellidoPaterno => _apellidoPaterno;
  String get apellidoMaterno => _apellidoMaterno;
  String get nombreCompleto => _nombreCompleto;
  String get estadoServicio => _estadoServicio;
  String get errorMessage => _errorMessage;

  // Setters
  void setDni(String value) {
    _dni = value;
    if (value.length != 8) {
      _dniVerified = false;
      _nombres = '';
      _apellidoPaterno = '';
      _apellidoMaterno = '';
      _nombreCompleto = '';
    }
    clearError();
    notifyListeners();
  }

  void setPassword(String value) {
    _password = value;
    clearError();
    notifyListeners();
  }

  void setConfirmPassword(String value) {
    _confirmPassword = value;
    clearError();
    notifyListeners();
  }

  void setEmail(String value) {
    _email = value;
    clearError();
    notifyListeners();
  }

  void setTelefono(String value) {
    _telefono = value;
    clearError();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  // Verificar estado del servicio Decolecta
  Future<void> verificarEstadoDecolecta() async {
    _estadoServicio = 'Verificando estado del servicio...';
    notifyListeners();

    try {
      // Simulación de verificación - puedes implementar una llamada real
      await Future.delayed(const Duration(seconds: 1));
      _estadoServicio = 'Servicio Reniec disponible';
      notifyListeners();
    } catch (e) {
      _estadoServicio = 'Servicio Reniec no disponible';
      notifyListeners();
    }
  }

  // Consultar DNI con Decolecta
  Future<void> consultarDniDecolecta() async {
    if (_dni.length != 8) {
      _errorMessage = 'El DNI debe tener 8 dígitos';
      notifyListeners();
      return;
    }

    _consultandoReniec = true;
    _errorMessage = '';
    _dniVerified = false;
    notifyListeners();

    try {
      final response = await DniService.consultarDni(_dni);

      _consultandoReniec = false;

      if (response.success && response.data != null) {
        _nombres = response.data!.nombres;
        _apellidoPaterno = response.data!.apellidoPaterno;
        _apellidoMaterno = response.data!.apellidoMaterno;
        _nombreCompleto = response.data!.nombreCompleto;
        _dniVerified = true;
        _errorMessage = '';
      } else {
        _dniVerified = false;
        _errorMessage = response.error ?? 'Error al consultar el DNI';
      }
    } catch (e) {
      _consultandoReniec = false;
      _dniVerified = false;
      _errorMessage = 'Error de conexión: $e';
    }

    notifyListeners();
  }

  // Validar formulario
  bool validateForm() {
    if (!_dniVerified) {
      _errorMessage = 'Debe verificar su DNI primero';
      notifyListeners();
      return false;
    }

    if (_password.isEmpty) {
      _errorMessage = 'La contraseña es requerida';
      notifyListeners();
      return false;
    }

    if (_password.length < 6) {
      _errorMessage = 'La contraseña debe tener al menos 6 caracteres';
      notifyListeners();
      return false;
    }

    if (_password != _confirmPassword) {
      _errorMessage = 'Las contraseñas no coinciden';
      notifyListeners();
      return false;
    }

    if (_email.isNotEmpty && !_isValidEmail(_email)) {
      _errorMessage = 'El email no es válido';
      notifyListeners();
      return false;
    }

    _errorMessage = '';
    notifyListeners();
    return true;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Convertir a JSON para el registro
  Map<String, dynamic> toJson() {
    final json = {
      'dni': _dni,
      'password': _password,
      'nombres': _nombres,
      'apellido_paterno': _apellidoPaterno,
      'apellido_materno': _apellidoMaterno,
      'nombre_completo': _nombreCompleto,
    };

    // Agregar campos opcionales solo si tienen valor
    if (_email.isNotEmpty) {
      json['email'] = _email;
    }
    if (_telefono.isNotEmpty) {
      json['telefono'] = _telefono;
    }

    return json;
  }

  // Limpiar formulario
  void clearForm() {
    _dni = '';
    _password = '';
    _confirmPassword = '';
    _email = '';
    _telefono = '';
    _dniVerified = false;
    _nombres = '';
    _apellidoPaterno = '';
    _apellidoMaterno = '';
    _nombreCompleto = '';
    _errorMessage = '';
    notifyListeners();
  }
}
