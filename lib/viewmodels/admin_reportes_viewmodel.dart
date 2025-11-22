import 'package:flutter/foundation.dart';
import '../models/reporte_model.dart';
import '../models/user_model.dart';
import '../services/reporte_service.dart';
import '../services/user_service.dart';

class AdminReportesViewModel extends ChangeNotifier {
  final ReporteService _reporteService = ReporteService();
  final UserService _userService = UserService();

  List<ReporteModel> _todosReportes = [];
  List<ReporteModel> _reportesFiltrados = [];
  bool _isLoading = false;
  String _error = '';

  // Filtros
  String _filtroEstado = 'Todos';
  String _filtroPrioridad = 'Todas';
  String _searchQuery = '';

  // Getters
  List<ReporteModel> get reportes => _reportesFiltrados;
  List<ReporteModel> get todosReportes => _todosReportes;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get filtroEstado => _filtroEstado;
  String get filtroPrioridad => _filtroPrioridad;

  Future<void> cargarReportes() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _reporteService.obtenerTodosReportes();

      if (response.success && response.data != null) {
        _todosReportes = response.data!;

        // Enriquecer los reportes con información de usuario (si está disponible)
        await _enriquecerReportesConUsuarios();

        _aplicarFiltros();
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'Error al cargar reportes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFiltroEstado(String estado) {
    _filtroEstado = estado;
    _aplicarFiltros();
    notifyListeners();
  }

  void setFiltroPrioridad(String prioridad) {
    _filtroPrioridad = prioridad;
    _aplicarFiltros();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _aplicarFiltros();
    notifyListeners();
  }

  /// Cargar usuarios y asociarlos a los reportes por usuarioId
  Future<void> _enriquecerReportesConUsuarios() async {
    try {
      // Si ningún reporte tiene usuarioId, no hacemos llamada extra
      final tieneUsuarioId = _todosReportes.any(
        (reporte) => reporte.usuarioId != null,
      );
      if (!tieneUsuarioId) {
        if (kDebugMode) {
          print(
            'ℹ️ Ningún reporte tiene usuarioId, se omite la carga de usuarios.',
          );
        }
        return;
      }

      if (kDebugMode) {
        final idsConUsuario = _todosReportes
            .where((r) => r.usuarioId != null)
            .map((r) => r.usuarioId)
            .toSet();
        print(
          '📊 Reportes con usuarioId: ${idsConUsuario.length} -> $idsConUsuario',
        );
      }

      final usuariosResponse = await _userService.obtenerUsuarios();
      if (!usuariosResponse.success || usuariosResponse.data == null) {
        // No rompemos la vista, solo logueamos el error
        _error = usuariosResponse.message;
        if (kDebugMode) {
          print(
            '⚠️ No se pudieron cargar usuarios: ${usuariosResponse.message}',
          );
        }
        return;
      }

      final List<UserModel> usuarios = usuariosResponse.data!;
      if (kDebugMode) {
        print('👥 Usuarios cargados: ${usuarios.length}');
      }
      // Mapa por id para lookup rápido
      final Map<int, UserModel> usuariosMap = {
        for (final u in usuarios) u.id: u,
      };

      int asignados = 0;
      _todosReportes = _todosReportes.map((reporte) {
        // Si ya viene el usuario desde el backend, lo respetamos
        if (reporte.usuario != null) return reporte;

        final uid = reporte.usuarioId;
        if (uid != null && usuariosMap.containsKey(uid)) {
          final user = usuariosMap[uid]!;
          asignados++;
          return reporte.copyWith(usuarioId: user.id, usuario: user);
        }
        return reporte;
      }).toList();

      if (kDebugMode) {
        print('✅ Usuarios asignados a reportes: $asignados');
      }
    } catch (e) {
      // Log de error pero sin romper el flujo principal
      _error = 'Error al cargar usuarios para los reportes: $e';
      if (kDebugMode) {
        print('❌ Error al enriquecer reportes con usuarios: $e');
      }
    }
  }

  void _aplicarFiltros() {
    _reportesFiltrados = _todosReportes.where((reporte) {
      // Filtro de Estado
      if (_filtroEstado != 'Todos') {
        // Normalizar ambos estados para comparar (convertir espacios a guiones bajos)
        final reporteEstado = reporte.estado.toLowerCase().replaceAll(' ', '_');
        final filtroEstado = _filtroEstado.toLowerCase().replaceAll(' ', '_');
        if (reporteEstado != filtroEstado) {
          return false;
        }
      }

      // Filtro de Prioridad
      if (_filtroPrioridad != 'Todas') {
        if (reporte.prioridad.toLowerCase() != _filtroPrioridad.toLowerCase()) {
          return false;
        }
      }

      // Búsqueda (ID, Título, Descripción)
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final id = reporte.id?.toString() ?? '';
        final codigo = reporte.codigoSeguimiento.toLowerCase();
        final titulo = reporte.titulo.toLowerCase();

        return id.contains(query) ||
            codigo.contains(query) ||
            titulo.contains(query);
      }

      return true;
    }).toList();

    // Ordenar por fecha (más reciente primero)
    _reportesFiltrados.sort((a, b) {
      final fechaA = a.fechaCreacion ?? DateTime(2000);
      final fechaB = b.fechaCreacion ?? DateTime(2000);
      return fechaB.compareTo(fechaA);
    });
  }

  // Método para actualizar el estado de un reporte
  Future<bool> actualizarEstadoReporte(
    int reporteId,
    String nuevoEstado,
  ) async {
    try {
      // Llamar al servicio para actualizar el estado
      final response = await _reporteService.actualizarEstadoReporte(
        reporteId: reporteId,
        nuevoEstado: nuevoEstado,
      );

      if (response.success && response.data != null) {
        // Actualizar el reporte en la lista local con los datos del servidor
        final index = _todosReportes.indexWhere((r) => r.id == reporteId);
        if (index != -1) {
          _todosReportes[index] = response.data!;
          _aplicarFiltros();
          notifyListeners();
        } else {
          // Si no está en la lista, recargar todos los reportes
          await cargarReportes();
        }
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error al actualizar el estado: $e';
      notifyListeners();
      return false;
    }
  }

  // Estadísticas para el dashboard
  int get totalReportes => _todosReportes.length;

  int get reportesPendientes =>
      _todosReportes.where((r) => r.estado.toLowerCase() == 'pendiente').length;

  int get reportesEnProceso => _todosReportes
      .where((r) => r.estado.toLowerCase().replaceAll(' ', '_') == 'en_proceso')
      .length;

  int get reportesResueltos =>
      _todosReportes.where((r) => r.estado.toLowerCase() == 'resuelto').length;

  int get reportesRechazados =>
      _todosReportes.where((r) => r.estado.toLowerCase() == 'rechazado').length;

  int get reportesPrioridadAlta =>
      _todosReportes.where((r) => r.prioridad.toLowerCase() == 'alta').length;

  int get reportesPrioridadMedia =>
      _todosReportes.where((r) => r.prioridad.toLowerCase() == 'media').length;

  int get reportesPrioridadBaja =>
      _todosReportes.where((r) => r.prioridad.toLowerCase() == 'baja').length;

  List<ReporteModel> get listaReportesPrioridadAlta {
    final lista = _todosReportes
        .where((r) => r.prioridad.toLowerCase() == 'alta')
        .toList();
    // Ordenar por fecha descendente (más reciente primero)
    lista.sort((a, b) {
      final fechaA = a.fechaCreacion ?? DateTime(2000);
      final fechaB = b.fechaCreacion ?? DateTime(2000);
      return fechaB.compareTo(fechaA);
    });
    return lista;
  }
}
