import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/cloudinary_service.dart';
import '../services/reporte_service.dart';
import '../models/archivo_multimedia_model.dart';
import '../models/categoria_model.dart';
import '../models/crear_reporte_response.dart';
import '../models/reporte_model.dart';
import '../models/api_response.dart';

class NuevoReporteViewModel with ChangeNotifier {
  final ReporteService _reporteService = ReporteService();
  final ImagePicker _imagePicker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Estado de carga
  bool _isLoading = false;
  bool _isLoadingCategorias = false;
  bool _isSubmitting = false;

  // Mensajes de error
  String _errorMessage = '';
  String _submitErrorMessage = '';

  // Categorías
  List<CategoriaModel> _categorias = [];
  CategoriaModel? _categoriaSeleccionada;

  // Formulario
  String _titulo = '';
  String _descripcion = '';
  String _prioridad = 'media'; // 'alta', 'media', 'baja'
  bool _esPublico = false;

  // Ubicación
  double? _latitud;
  double? _longitud;
  String _direccion = '';
  String _distrito = '';
  String _referencia = '';
  String _gmapsPlaceId = '';

  // Archivos
  final List<ReporteAdjunto> _adjuntos = [];
  final List<ArchivoMultimediaModel> _multimediaEliminados = [];
  final int _maxArchivos = 5;
  ReporteModel? _reporteEditando;
  int? _categoriaPendienteId;

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoadingCategorias => _isLoadingCategorias;
  bool get isSubmitting => _isSubmitting;
  String get errorMessage => _errorMessage;
  String get submitErrorMessage => _submitErrorMessage;
  List<CategoriaModel> get categorias => _categorias;
  CategoriaModel? get categoriaSeleccionada => _categoriaSeleccionada;
  String get titulo => _titulo;
  String get descripcion => _descripcion;
  String get prioridad => _prioridad;
  bool get esPublico => _esPublico;
  double? get latitud => _latitud;
  double? get longitud => _longitud;
  String get direccion => _direccion;
  String get distrito => _distrito;
  String get referencia => _referencia;
  String get gmapsPlaceId => _gmapsPlaceId;
  List<ReporteAdjunto> get adjuntos => List.unmodifiable(_adjuntos);
  int get maxArchivos => _maxArchivos;
  bool get puedeAgregarArchivos => _adjuntos.length < _maxArchivos;
  bool get esModoEdicion => _reporteEditando != null;

  // Validación del formulario
  bool get isFormValid {
    return _categoriaSeleccionada != null &&
        _titulo.trim().isNotEmpty &&
        _descripcion.trim().isNotEmpty &&
        _latitud != null &&
        _longitud != null;
  }

  /// Cargar categorías desde el servidor
  Future<void> cargarCategorias() async {
    if (_isLoadingCategorias) return; // Evitar múltiples llamadas simultáneas

    // Verificar que el token esté disponible
    final apiService = ApiService();
    if (!apiService.hasToken) {
      _errorMessage = 'No hay sesión activa. Por favor, inicia sesión.';
      _categorias = [];
      notifyListeners();
      print('Error: No hay token disponible');
      return;
    }

    _isLoadingCategorias = true;
    _errorMessage = '';
    notifyListeners();

    try {
      print('Cargando categorías...');
      final response = await _reporteService.obtenerCategorias();

      _isLoadingCategorias = false;

      if (response.success && response.data != null) {
        _categorias = response.data!;
        _errorMessage = '';
        print('Categorías cargadas: ${_categorias.length}');
        _aplicarCategoriaPendienteSiCorresponde();
      } else {
        _errorMessage = response.message.isNotEmpty
            ? response.message
            : 'No se pudieron cargar las categorías';
        _categorias = []; // Limpiar lista en caso de error
        print('Error cargando categorías: ${response.message}');
      }
    } catch (e) {
      _isLoadingCategorias = false;
      _errorMessage = 'Error al cargar categorías: ${e.toString()}';
      _categorias = [];
      print('Error cargando categorías: $e'); // Debug
    }

    notifyListeners();
  }

  /// Establecer categoría seleccionada
  void setCategoria(CategoriaModel? categoria) {
    _categoriaSeleccionada = categoria;
    if (categoria != null) {
      _categoriaPendienteId = categoria.id;
    }
    _errorMessage = '';
    notifyListeners();
  }

  /// Establecer título
  void setTitulo(String value) {
    _titulo = value;
    _errorMessage = '';
    notifyListeners();
  }

  /// Establecer descripción
  void setDescripcion(String value) {
    _descripcion = value;
    _errorMessage = '';
    notifyListeners();
  }

  /// Establecer prioridad
  void setPrioridad(String value) {
    if (['alta', 'media', 'baja'].contains(value)) {
      _prioridad = value;
      notifyListeners();
    }
  }

  /// Toggle es público
  void toggleEsPublico() {
    _esPublico = !_esPublico;
    notifyListeners();
  }

  /// Establecer ubicación
  void setUbicacion({
    required double latitud,
    required double longitud,
    String? direccion,
    String? distrito,
    String? referencia,
    String? gmapsPlaceId,
  }) {
    _latitud = latitud;
    _longitud = longitud;
    _direccion = direccion ?? '';
    _distrito = distrito ?? '';
    _referencia = referencia ?? '';
    _gmapsPlaceId = gmapsPlaceId ?? '';
    _errorMessage = '';
    notifyListeners();
  }

  /// Establecer referencia
  void setReferencia(String value) {
    _referencia = value;
    notifyListeners();
  }

  /// Agregar archivo desde galería
  Future<void> agregarArchivoDesdeGaleria() async {
    if (!puedeAgregarArchivos) {
      _errorMessage = 'Has alcanzado el límite de archivos ($_maxArchivos)';
      notifyListeners();
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        _adjuntos.add(ReporteAdjunto.local(File(image.path)));
        _errorMessage = '';
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error al seleccionar imagen: $e';
      notifyListeners();
    }
  }

  /// Agregar archivo desde cámara
  Future<void> agregarArchivoDesdeCamara() async {
    if (!puedeAgregarArchivos) {
      _errorMessage = 'Has alcanzado el límite de archivos ($_maxArchivos)';
      notifyListeners();
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        _adjuntos.add(ReporteAdjunto.local(File(image.path)));
        _errorMessage = '';
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error al tomar foto: $e';
      notifyListeners();
    }
  }

  /// Agregar video desde galería
  Future<void> agregarVideoDesdeGaleria() async {
    if (!puedeAgregarArchivos) {
      _errorMessage = 'Has alcanzado el límite de archivos ($_maxArchivos)';
      notifyListeners();
      return;
    }

    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );

      if (video != null) {
        _adjuntos.add(ReporteAdjunto.local(File(video.path)));
        _errorMessage = '';
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error al seleccionar video: $e';
      notifyListeners();
    }
  }

  /// Grabar video desde cámara
  Future<void> grabarVideoDesdeCamara() async {
    if (!puedeAgregarArchivos) {
      _errorMessage = 'Has alcanzado el límite de archivos ($_maxArchivos)';
      notifyListeners();
      return;
    }

    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
      );

      if (video != null) {
        _adjuntos.add(ReporteAdjunto.local(File(video.path)));
        _errorMessage = '';
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error al grabar video: $e';
      notifyListeners();
    }
  }

  /// Eliminar archivo
  void eliminarArchivo(int index) {
    if (index >= 0 && index < _adjuntos.length) {
      final item = _adjuntos.removeAt(index);
      if (item.remoto != null) {
        _multimediaEliminados.add(item.remoto!);
      }
      notifyListeners();
    }
  }

  /// Limpiar todos los archivos
  void limpiarArchivos() {
    _adjuntos.clear();
    _multimediaEliminados.clear();
    notifyListeners();
  }

  /// Crear reporte
  Future<ApiResponse<CrearReporteResponse>?> crearReporte() async {
    // Validar formulario
    if (!isFormValid) {
      _submitErrorMessage = 'Por favor, completa todos los campos obligatorios';
      notifyListeners();
      return ApiResponse.error(_submitErrorMessage);
    }

    _isSubmitting = true;
    _submitErrorMessage = '';
    notifyListeners();

    try {
      final multimediaPayload = await _prepararMultimediaParaEnvio();

      final response = await _reporteService.crearReporte(
        categoriaId: _categoriaSeleccionada!.id,
        titulo: _titulo.trim(),
        descripcion: _descripcion.trim(),
        latitud: _latitud!,
        longitud: _longitud!,
        direccion: _direccion.trim().isNotEmpty ? _direccion.trim() : null,
        distrito: _distrito.trim().isNotEmpty ? _distrito.trim() : null,
        referencia: _referencia.trim().isNotEmpty ? _referencia.trim() : null,
        gmapsPlaceId: _gmapsPlaceId.trim().isNotEmpty
            ? _gmapsPlaceId.trim()
            : null,
        prioridad: _prioridad,
        esPublico: _esPublico,
        multimedia: multimediaPayload,
      );

      _isSubmitting = false;

      if (response.success) {
        _submitErrorMessage = '';
        // Limpiar formulario después de éxito
        limpiarFormulario();
      } else {
        _submitErrorMessage = response.message;
      }

      notifyListeners();
      return response;
    } catch (e) {
      _isSubmitting = false;
      _submitErrorMessage = 'Error al crear el reporte: $e';
      notifyListeners();
      return ApiResponse.error(_submitErrorMessage);
    }
  }

  Future<List<Map<String, dynamic>>> _prepararMultimediaParaEnvio() async {
    if (_adjuntos.isEmpty) return [];

    final List<Map<String, dynamic>> multimedia = [];

    for (var i = 0; i < _adjuntos.length; i++) {
      final adjunto = _adjuntos[i];
      final esPrincipal = i == 0;
      if (adjunto.remoto != null) {
        final data = Map<String, dynamic>.from(adjunto.remoto!.toJson());
        data['es_principal'] = esPrincipal;
        multimedia.add(data);
      } else if (adjunto.archivoLocal != null) {
        final uploadResult = await _cloudinaryService.uploadFile(
          adjunto.archivoLocal!,
        );
        multimedia.add(
          uploadResult.toMultimediaPayload(esPrincipal: esPrincipal),
        );
      }
    }

    return multimedia;
  }

  /// Limpiar formulario
  void limpiarFormulario() {
    _categoriaSeleccionada = null;
    _categoriaPendienteId = null;
    _titulo = '';
    _descripcion = '';
    _prioridad = 'media';
    _esPublico = false;
    _latitud = null;
    _longitud = null;
    _direccion = '';
    _distrito = '';
    _referencia = '';
    _gmapsPlaceId = '';
    _adjuntos.clear();
    _multimediaEliminados.clear();
    _reporteEditando = null;
    _errorMessage = '';
    _submitErrorMessage = '';
    notifyListeners();
  }

  /// Limpiar errores
  void limpiarErrores() {
    _errorMessage = '';
    _submitErrorMessage = '';
    notifyListeners();
  }

  void prepararNuevoReporte() {
    limpiarFormulario();
  }

  void cargarDesdeReporte(ReporteModel reporte) {
    _reporteEditando = reporte;
    _titulo = reporte.titulo;
    _descripcion = reporte.descripcion;
    _prioridad = reporte.prioridad;
    _esPublico = reporte.esPublico;
    _latitud = reporte.ubicacion?.latitud;
    _longitud = reporte.ubicacion?.longitud;
    _direccion = reporte.ubicacion?.direccion ?? '';
    _distrito = reporte.ubicacion?.distrito ?? '';
    _referencia = reporte.ubicacion?.referencia ?? '';
    _gmapsPlaceId = reporte.ubicacion?.gmapsPlaceId ?? '';
    _adjuntos
      ..clear()
      ..addAll(reporte.archivos.map(ReporteAdjunto.remoto));
    _multimediaEliminados.clear();
    _categoriaPendienteId = reporte.categoriaId;
    _aplicarCategoriaPendienteSiCorresponde();
    notifyListeners();
  }

  Future<ApiResponse<CrearReporteResponse>?> guardarCambios() async {
    if (_reporteEditando == null) {
      return ApiResponse.error('No hay un reporte para editar');
    }

    final reporteId = _reporteEditando!.id;
    if (reporteId == null) {
      _submitErrorMessage = 'El reporte no tiene un identificador válido';
      notifyListeners();
      return ApiResponse.error(_submitErrorMessage);
    }

    if (!isFormValid) {
      _submitErrorMessage = 'Por favor, completa todos los campos obligatorios';
      notifyListeners();
      return ApiResponse.error(_submitErrorMessage);
    }

    _isSubmitting = true;
    _submitErrorMessage = '';
    notifyListeners();

    try {
      final multimediaPayload = await _prepararMultimediaParaEnvio();
      final response = await _reporteService.editarReporte(
        reporteId: reporteId,
        categoriaId: _categoriaSeleccionada!.id,
        titulo: _titulo.trim(),
        descripcion: _descripcion.trim(),
        latitud: _latitud!,
        longitud: _longitud!,
        direccion: _direccion.trim().isNotEmpty ? _direccion.trim() : null,
        distrito: _distrito.trim().isNotEmpty ? _distrito.trim() : null,
        referencia: _referencia.trim().isNotEmpty ? _referencia.trim() : null,
        gmapsPlaceId: _gmapsPlaceId.trim().isNotEmpty
            ? _gmapsPlaceId.trim()
            : null,
        prioridad: _prioridad,
        esPublico: _esPublico,
        multimedia: multimediaPayload,
      );

      _isSubmitting = false;

      if (response.success) {
        await _eliminarMultimediaPendiente();
        _submitErrorMessage = '';
        limpiarFormulario();
      } else {
        _submitErrorMessage = response.message;
      }

      notifyListeners();
      return response;
    } catch (e) {
      _isSubmitting = false;
      _submitErrorMessage = 'Error al actualizar el reporte: $e';
      notifyListeners();
      return ApiResponse.error(_submitErrorMessage);
    }
  }

  Future<void> _eliminarMultimediaPendiente() async {
    for (final media in _multimediaEliminados) {
      if (media.url.isEmpty) continue;
      try {
        final isVideo = (media.mimeType ?? media.tipo).toLowerCase().contains(
          'video',
        );
        await _cloudinaryService.deleteAssetByUrl(
          media.url,
          resourceType: isVideo ? 'video' : 'image',
        );
      } catch (e) {
        if (kDebugMode) {
          print('Error eliminando archivo en Cloudinary: $e');
        }
      }
    }
    _multimediaEliminados.clear();
  }

  void _aplicarCategoriaPendienteSiCorresponde() {
    if (_categoriaPendienteId == null || _categorias.isEmpty) return;
    try {
      final categoria = _categorias.firstWhere(
        (element) => element.id == _categoriaPendienteId,
      );
      _categoriaSeleccionada = categoria;
      _categoriaPendienteId = null;
    } catch (_) {}
  }
}

class ReporteAdjunto {
  final File? archivoLocal;
  final ArchivoMultimediaModel? remoto;

  ReporteAdjunto.local(File file) : archivoLocal = file, remoto = null;

  ReporteAdjunto.remoto(ArchivoMultimediaModel media)
    : archivoLocal = null,
      remoto = media;

  bool get esRemoto => remoto != null;
  bool get esVideo {
    if (archivoLocal != null) {
      final path = archivoLocal!.path.toLowerCase();
      return path.endsWith('.mp4') ||
          path.endsWith('.mov') ||
          path.endsWith('.avi');
    }
    final mime = remoto?.mimeType ?? remoto?.tipo ?? '';
    return mime.toLowerCase().contains('video');
  }
}
