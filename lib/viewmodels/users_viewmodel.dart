import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UsersViewModel extends ChangeNotifier {
  final UserService _userService = UserService();

  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _searchQuery = '';

  List<UserModel> get users => _filteredUsers;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  /// Cargar usuarios
  Future<void> loadUsers() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    final response = await _userService.obtenerUsuarios();

    if (response.success && response.data != null) {
      _users = response.data!;
      _applyFilter();
    } else {
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Actualizar estado de usuario
  Future<bool> updateUserStatus(UserModel user, String newStatus) async {
    // if (user.id == null) return false; // id is non-nullable

    // Optimistic update
    // final oldStatus = user.estado; // Unused
    final userIndex = _users.indexWhere((u) => u.id == user.id);

    if (userIndex != -1) {
      // Crear copia modificada del usuario (ya que los campos son final)
      // Nota: Esto asume que UserModel tiene copyWith o creamos uno nuevo manualmente
      // Como no tiene copyWith, usaremos el constructor
      final updatedUser = UserModel(
        id: user.id,
        dni: user.dni,
        nombres: user.nombres,
        apellidoPaterno: user.apellidoPaterno,
        apellidoMaterno: user.apellidoMaterno,
        nombreCompleto: user.nombreCompleto,
        email: user.email,
        telefono: user.telefono,
        tipo: user.tipo,
        estado: newStatus,
        fechaRegistro: user.fechaRegistro,
        ultimoLogin: user.ultimoLogin,
      );

      _users[userIndex] = updatedUser;
      _applyFilter();
      notifyListeners();
    }

    final response = await _userService.actualizarEstadoUsuario(
      usuarioId: user.id,
      nuevoEstado: newStatus,
    );

    if (!response.success) {
      // Revertir si falla
      if (userIndex != -1) {
        _users[userIndex] = user; // user tiene el estado original
        _applyFilter();
        notifyListeners();
      }
      _errorMessage = 'Error al actualizar estado';
      return false;
    }

    return true;
  }

  /// Buscar usuarios
  void searchUsers(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredUsers = List.from(_users);
    } else {
      _filteredUsers = _userService.searchUsers(_users, _searchQuery);
    }
  }

  void clearSearch() {
    _searchQuery = '';
    _applyFilter();
    notifyListeners();
  }

  int get activeUsersCount =>
      _users.where((u) => u.estado.toLowerCase() == 'activo').length;
}
