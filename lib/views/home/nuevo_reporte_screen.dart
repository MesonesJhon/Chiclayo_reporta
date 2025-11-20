import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/nuevo_reporte_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../services/api_service.dart';
import '../../models/categoria_model.dart';
import '../../models/reporte_model.dart';
import '../../utils/app_colors.dart';
import '../widgets/seleccionar_ubicacion_map.dart';

class NuevoReporteScreen extends StatefulWidget {
  final ReporteModel? reporteAEditar;

  const NuevoReporteScreen({super.key, this.reporteAEditar});

  @override
  State<NuevoReporteScreen> createState() => _NuevoReporteScreenState();
}

class _NuevoReporteScreenState extends State<NuevoReporteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _referenciaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Cargar categorías al iniciar, pero asegurar que el token esté disponible
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final viewModel = context.read<NuevoReporteViewModel>();
      if (widget.reporteAEditar == null) {
        viewModel.prepararNuevoReporte();
      } else {
        viewModel.cargarDesdeReporte(widget.reporteAEditar!);
      }
      // Verificar que el token esté disponible antes de cargar categorías
      final apiService = ApiService();
      if (!apiService.hasToken) {
        // Si no hay token, intentar obtenerlo del AuthViewModel
        final authViewModel = context.read<AuthViewModel>();
        if (authViewModel.token != null) {
          print('🔄 Configurando token desde AuthViewModel...');
          apiService.setToken(authViewModel.token!);
        } else {
          print(
            '❌ ERROR: No hay token disponible en ApiService ni en AuthViewModel',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'No hay sesión activa. Por favor, inicia sesión.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // Esperar un momento para asegurar que el token esté disponible
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        print('📋 Cargando categorías...');
        context.read<NuevoReporteViewModel>().cargarCategorias();
      }
    });
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _referenciaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<NuevoReporteViewModel>();
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: Text(
          viewModel.esModoEdicion ? 'EDITAR REPORTE' : 'NUEVO REPORTE',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (_tituloController.text != viewModel.titulo) {
            _tituloController.text = viewModel.titulo;
          }
          if (_descripcionController.text != viewModel.descripcion) {
            _descripcionController.text = viewModel.descripcion;
          }
          if (_referenciaController.text != viewModel.referencia) {
            _referenciaController.text = viewModel.referencia;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategoriaSection(viewModel),
                  const SizedBox(height: 24),
                  _buildTituloSection(viewModel),
                  const SizedBox(height: 24),
                  _buildDescripcionSection(viewModel),
                  const SizedBox(height: 24),
                  const Divider(),
                  _buildUbicacionSection(viewModel),
                  const SizedBox(height: 24),
                  _buildReferenciaSection(viewModel),
                  const SizedBox(height: 24),
                  _buildArchivosSection(viewModel),
                  const SizedBox(height: 24),
                  _buildPrioridadSection(viewModel),
                  const SizedBox(height: 24),
                  _buildEsPublicoSection(viewModel),
                  const SizedBox(height: 32),
                  if (viewModel.submitErrorMessage.isNotEmpty)
                    _buildErrorMessage(viewModel.submitErrorMessage),
                  _buildButtons(viewModel),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoriaSection(NuevoReporteViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categoría *',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: _boxDecoration(),
          child: viewModel.isLoadingCategorias
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              : viewModel.categorias.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (viewModel.errorMessage.isNotEmpty)
                        Text(
                          viewModel.errorMessage,
                          style: TextStyle(
                            color: AppColors.criticalRed,
                            fontSize: 12,
                          ),
                        )
                      else
                        const Text(
                          'No hay categorías disponibles',
                          style: TextStyle(color: Colors.grey),
                        ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => viewModel.cargarCategorias(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<CategoriaModel>(
                    value: _categoriaSeleccionadaValida(viewModel),
                    isExpanded: true,
                    hint: const Text('Selecciona una categoría'),
                    items: viewModel.categorias.map((categoria) {
                      return DropdownMenuItem<CategoriaModel>(
                        value: categoria,
                        child: Text(categoria.nombre),
                      );
                    }).toList(),
                    onChanged: (CategoriaModel? categoria) {
                      viewModel.setCategoria(categoria);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  CategoriaModel? _categoriaSeleccionadaValida(
    NuevoReporteViewModel viewModel,
  ) {
    final seleccionada = viewModel.categoriaSeleccionada;
    if (seleccionada == null) return null;
    final existe = viewModel.categorias.any(
      (categoria) => categoria.id == seleccionada.id,
    );
    return existe ? seleccionada : null;
  }

  Widget _buildTituloSection(NuevoReporteViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Título *',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: _boxDecoration(),
          child: TextFormField(
            controller: _tituloController,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
              hintText: 'Ej: Poste de luz dañado',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El título es obligatorio';
              }
              return null;
            },
            onChanged: (value) => viewModel.setTitulo(value),
          ),
        ),
      ],
    );
  }

  Widget _buildDescripcionSection(NuevoReporteViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Descripción *',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: _boxDecoration(),
          child: TextFormField(
            controller: _descripcionController,
            maxLines: 4,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
              hintText: 'Describe el problema en detalle...',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La descripción es obligatoria';
              }
              return null;
            },
            onChanged: (value) => viewModel.setDescripcion(value),
          ),
        ),
      ],
    );
  }

  Widget _buildUbicacionSection(NuevoReporteViewModel viewModel) {
    final tieneUbicacion =
        viewModel.latitud != null && viewModel.longitud != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ubicación *',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _boxDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tieneUbicacion) ...[
                Row(
                  children: [
                    Icon(Icons.location_on, color: AppColors.primaryBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (viewModel.direccion.isNotEmpty)
                            Text(
                              viewModel.direccion,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (viewModel.distrito.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              viewModel.distrito,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            'Lat: ${viewModel.latitud!.toStringAsFixed(6)}, '
                            'Lng: ${viewModel.longitud!.toStringAsFixed(6)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Icon(Icons.location_off, color: Colors.grey[400]),
                    const SizedBox(width: 8),
                    const Text(
                      'No se ha seleccionado ubicación',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _seleccionarUbicacion(viewModel),
                  icon: const Icon(Icons.map),
                  label: Text(
                    tieneUbicacion
                        ? 'Cambiar Ubicación'
                        : 'Seleccionar Ubicación',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReferenciaSection(NuevoReporteViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Referencia (opcional)',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: _boxDecoration(),
          child: TextFormField(
            controller: _referenciaController,
            maxLines: 2,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
              hintText: 'Ej: Frente al mercado, cerca del parque...',
            ),
            onChanged: (value) => viewModel.setReferencia(value),
          ),
        ),
      ],
    );
  }

  Widget _buildArchivosSection(NuevoReporteViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Archivos (fotos/videos)',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            Text(
              '${viewModel.adjuntos.length}/${viewModel.maxArchivos}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (viewModel.adjuntos.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: _boxDecoration(),
            child: Column(
              children: [
                Icon(Icons.photo_library, size: 40, color: Colors.grey[400]),
                const SizedBox(height: 12),
                const Text(
                  'No hay archivos agregados',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: viewModel.puedeAgregarArchivos
                          ? () => _mostrarOpcionesArchivo(viewModel)
                          : null,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Agregar'),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount:
                    viewModel.adjuntos.length +
                    (viewModel.puedeAgregarArchivos ? 1 : 0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  if (index < viewModel.adjuntos.length) {
                    return _buildArchivoTile(viewModel, index);
                  }
                  return _buildAgregarArchivoTile(viewModel);
                },
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildArchivoTile(NuevoReporteViewModel viewModel, int index) {
    final adjunto = viewModel.adjuntos[index];
    final isVideo = adjunto.esVideo;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[300],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildMediaPreview(adjunto, isVideo),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => viewModel.eliminarArchivo(index),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgregarArchivoTile(NuevoReporteViewModel viewModel) {
    return GestureDetector(
      onTap: () => _mostrarOpcionesArchivo(viewModel),
      child: Container(
        decoration: _boxDecoration(),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate, size: 30),
              SizedBox(height: 4),
              Text('Agregar', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPreview(ReporteAdjunto adjunto, bool isVideo) {
    if (adjunto.archivoLocal != null) {
      return isVideo
          ? Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  adjunto.archivoLocal!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Icon(Icons.videocam, size: 30));
                  },
                ),
                const Center(
                  child: Icon(
                    Icons.play_circle_filled,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ],
            )
          : Image.file(
              adjunto.archivoLocal!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(Icons.photo, size: 30, color: Colors.white),
                );
              },
            );
    } else if (adjunto.remoto != null) {
      if (isVideo) {
        return Container(
          color: Colors.black54,
          child: const Center(
            child: Icon(
              Icons.play_circle_filled,
              color: Colors.white,
              size: 40,
            ),
          ),
        );
      }
      return Image.network(
        adjunto.remoto!.url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.photo, size: 30, color: Colors.white),
          );
        },
      );
    }
    return const SizedBox();
  }

  Widget _buildPrioridadSection(NuevoReporteViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prioridad',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: [
            _buildPrioridadChip(
              viewModel,
              'alta',
              'Alta',
              AppColors.criticalRed,
            ),
            _buildPrioridadChip(
              viewModel,
              'media',
              'Media',
              AppColors.warningYellow,
            ),
            _buildPrioridadChip(
              viewModel,
              'baja',
              'Baja',
              AppColors.actionGreen,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrioridadChip(
    NuevoReporteViewModel viewModel,
    String value,
    String label,
    Color color,
  ) {
    final isSelected = viewModel.prioridad == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => viewModel.setPrioridad(value),
      selectedColor: color.withOpacity(0.2),
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildEsPublicoSection(NuevoReporteViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _boxDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reporte público',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Otros usuarios podrán ver este reporte',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: viewModel.esPublico,
            onChanged: (_) => viewModel.toggleEsPublico(),
            activeColor: AppColors.actionGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.criticalRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.criticalRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.criticalRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: AppColors.criticalRed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(NuevoReporteViewModel viewModel) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: viewModel.isSubmitting
                ? null
                : () {
                    viewModel.limpiarFormulario();
                    Navigator.pop(context);
                  },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: viewModel.isSubmitting || !viewModel.isFormValid
                ? null
                : () => _guardarReporte(viewModel),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.actionGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: viewModel.isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    viewModel.esModoEdicion
                        ? 'Guardar cambios'
                        : 'Crear reporte',
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _seleccionarUbicacion(NuevoReporteViewModel viewModel) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeleccionarUbicacionMap(
          latitudInicial: viewModel.latitud,
          longitudInicial: viewModel.longitud,
          direccionInicial: viewModel.direccion,
          distritoInicial: viewModel.distrito,
        ),
      ),
    );

    if (result != null) {
      viewModel.setUbicacion(
        latitud: result['latitud'] as double,
        longitud: result['longitud'] as double,
        direccion: result['direccion'] as String?,
        distrito: result['distrito'] as String?,
      );
    }
  }

  void _mostrarOpcionesArchivo(NuevoReporteViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Seleccionar archivo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColors.primaryBlue,
              ),
              title: const Text('Galería de fotos'),
              subtitle: const Text('Seleccionar foto desde galería'),
              onTap: () {
                Navigator.pop(context);
                viewModel.agregarArchivoDesdeGaleria();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: AppColors.actionGreen,
              ),
              title: const Text('Tomar foto'),
              subtitle: const Text('Capturar foto con la cámara'),
              onTap: () {
                Navigator.pop(context);
                viewModel.agregarArchivoDesdeCamara();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.video_library,
                color: AppColors.chiclayoOrange,
              ),
              title: const Text('Galería de videos'),
              subtitle: const Text('Seleccionar video desde galería'),
              onTap: () {
                Navigator.pop(context);
                viewModel.agregarVideoDesdeGaleria();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: AppColors.criticalRed),
              title: const Text('Grabar video'),
              subtitle: const Text('Grabar video con la cámara'),
              onTap: () {
                Navigator.pop(context);
                viewModel.grabarVideoDesdeCamara();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _guardarReporte(NuevoReporteViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!viewModel.isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, completa todos los campos obligatorios'),
          backgroundColor: AppColors.criticalRed,
        ),
      );
      return;
    }

    final response = viewModel.esModoEdicion
        ? await viewModel.guardarCambios()
        : await viewModel.crearReporte();

    if (response != null && response.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: AppColors.actionGreen,
          ),
        );
        Navigator.pop(context, true); // Retornar true para indicar éxito
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response?.message ?? 'Error al crear el reporte'),
            backgroundColor: AppColors.criticalRed,
          ),
        );
      }
    }
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300),
    );
  }
}
