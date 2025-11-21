import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../viewmodels/reportes_publicos_viewmodel.dart';
import '../../models/reporte_model.dart';
import '../../models/archivo_multimedia_model.dart';
import '../../utils/app_colors.dart';

class MapaReportesPublicosScreen extends StatefulWidget {
  const MapaReportesPublicosScreen({super.key});

  @override
  State<MapaReportesPublicosScreen> createState() =>
      _MapaReportesPublicosScreenState();
}

class _MapaReportesPublicosScreenState
    extends State<MapaReportesPublicosScreen> {
  GoogleMapController? _mapController;

  // Coordenadas de Chiclayo por defecto
  static const LatLng _chiclayoCenter = LatLng(-6.7713, -79.8409);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportesPublicosViewModel>().cargarReportesPublicos();
    });
  }

  Set<Marker> _buildMarkers(List<ReporteModel> reportes) {
    final markers = <Marker>{};

    for (final reporte in reportes) {
      final ubicacion = reporte.ubicacion;
      final latitud = ubicacion?.latitud;
      final longitud = ubicacion?.longitud;
      if (latitud == null || longitud == null) {
        continue;
      }

      final position = LatLng(latitud, longitud);
      final markerId = MarkerId('reporte_${reporte.id}');

      // Color del marcador según la prioridad
      BitmapDescriptor icono;
      switch (reporte.prioridad.toLowerCase()) {
        case 'alta':
          icono = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          );
          break;
        case 'media':
          icono = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          );
          break;
        case 'baja':
          icono = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          );
          break;
        default:
          icono = BitmapDescriptor.defaultMarker;
      }

      markers.add(
        Marker(
          markerId: markerId,
          position: position,
          icon: icono,
          infoWindow: InfoWindow(
            title: reporte.titulo,
            snippet: reporte.categoria?.nombre ?? 'Sin categoría',
          ),
          onTap: () {
            _mostrarDetalleReporte(reporte);
          },
        ),
      );
    }

    return markers;
  }

  void _mostrarDetalleReporte(ReporteModel reporte) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _DetalleReporteSheet(
          reporte: reporte,
          scrollController: scrollController,
          onVerMultimedia: () {
            Navigator.pop(context);
            _mostrarMultimedia(reporte);
          },
        ),
      ),
    );
  }

  void _mostrarMultimedia(ReporteModel reporte) {
    if (reporte.archivos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este reporte no tiene archivos multimedia'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReporteMultimediaViewer(reporte: reporte),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ReportesPublicosViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MAPA DE REPORTES',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: viewModel.isLoading ? null : () => viewModel.refrescar(),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
            },
            initialCameraPosition: const CameraPosition(
              target: _chiclayoCenter,
              zoom: 13,
            ),
            markers: _buildMarkers(viewModel.reportes),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
          ),
          if (viewModel.isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
          if (viewModel.errorMessage.isNotEmpty)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.criticalRed),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        viewModel.errorMessage,
                        style: TextStyle(color: AppColors.criticalRed),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        // El error se limpiará cuando se recargue
                      },
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildLeyendaItem(
                    'Alta',
                    BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildLeyendaItem(
                    'Media',
                    BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueOrange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildLeyendaItem(
                    'Baja',
                    BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${viewModel.reportes.length} reportes',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(_chiclayoCenter, 13),
            );
          }
        },
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.center_focus_strong),
        tooltip: 'Centrar en Chiclayo',
      ),
    );
  }

  Widget _buildLeyendaItem(String label, BitmapDescriptor icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: _getColorFromIcon(icon),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Color _getColorFromIcon(BitmapDescriptor icon) {
    // Esta es una aproximación, ya que no podemos obtener el color directamente
    // del BitmapDescriptor. En producción, podrías usar un mapa de colores.
    if (icon ==
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)) {
      return Colors.red;
    } else if (icon ==
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange)) {
      return Colors.orange;
    } else if (icon ==
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)) {
      return Colors.green;
    }
    return Colors.blue;
  }
}

class _DetalleReporteSheet extends StatelessWidget {
  final ReporteModel reporte;
  final ScrollController scrollController;
  final VoidCallback onVerMultimedia;

  const _DetalleReporteSheet({
    required this.reporte,
    required this.scrollController,
    required this.onVerMultimedia,
  });

  @override
  Widget build(BuildContext context) {
    final categoria = reporte.categoria;
    final ubicacion = reporte.ubicacion;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle para arrastrar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                // Título
                Text(
                  reporte.titulo,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Categoría y Estado
                Row(
                  children: [
                    if (categoria != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (categoria.icono != null)
                              Icon(
                                _getIconData(categoria.icono!),
                                size: 18,
                                color: AppColors.primaryBlue,
                              ),
                            if (categoria.icono != null)
                              const SizedBox(width: 4),
                            Text(
                              categoria.nombre,
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getEstadoColor(reporte.estado).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getEstadoLabel(reporte.estado),
                        style: TextStyle(
                          color: _getEstadoColor(reporte.estado),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Descripción
                const Text(
                  'Descripción',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  reporte.descripcion,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),

                // Ubicación
                if (ubicacion != null) ...[
                  const Text(
                    'Ubicación',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  if (ubicacion.direccion != null &&
                      ubicacion.direccion!.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            ubicacion.direccion!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (ubicacion.distrito != null &&
                      ubicacion.distrito!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.map, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          ubicacion.distrito!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (ubicacion.referencia != null &&
                      ubicacion.referencia!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            ubicacion.referencia!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                ],

                // Multimedia
                if (reporte.archivos.isNotEmpty &&
                    (reporte.estado.toLowerCase() == 'en_proceso' ||
                        reporte.estado.toLowerCase() == 'resuelto')) ...[
                  const Text(
                    'Multimedia',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onVerMultimedia,
                      icon: const Icon(Icons.collections_rounded),
                      label: Text(
                        'Ver ${reporte.archivos.length} ${reporte.archivos.length == 1 ? 'archivo' : 'archivos'}',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                        side: BorderSide(color: AppColors.primaryBlue),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Prioridad
                Row(
                  children: [
                    const Text(
                      'Prioridad: ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getPrioridadColor(
                          reporte.prioridad,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getPrioridadLabel(reporte.prioridad),
                        style: TextStyle(
                          color: _getPrioridadColor(reporte.prioridad),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Fecha de creación
                if (reporte.fechaCreacion != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Creado: ${_formatearFecha(reporte.fechaCreacion!)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Código de seguimiento
                if (reporte.codigoSeguimiento.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.qr_code, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Código: ${reporte.codigoSeguimiento}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'water':
      case 'agua':
        return Icons.water_drop;
      case 'fire':
      case 'fuego':
        return Icons.local_fire_department;
      case 'trash':
      case 'basura':
        return Icons.delete;
      case 'light':
      case 'luz':
      case 'alumbrado':
        return Icons.lightbulb;
      case 'road':
      case 'pista':
      case 'bache':
        return Icons.add_road;
      case 'park':
      case 'parque':
      case 'arbol':
        return Icons.park;
      case 'security':
      case 'seguridad':
      case 'robo':
        return Icons.security;
      case 'noise':
      case 'ruido':
        return Icons.volume_up;
      default:
        return Icons.category;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'resuelto':
        return AppColors.actionGreen;
      case 'en_proceso':
        return AppColors.warningYellow;
      case 'cancelado':
        return AppColors.criticalRed;
      default:
        return Colors.grey;
    }
  }

  String _getEstadoLabel(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return 'Pendiente';
      case 'en_proceso':
        return 'En Proceso';
      case 'resuelto':
        return 'Resuelto';
      case 'cancelado':
        return 'Cancelado';
      default:
        return estado;
    }
  }

  Color _getPrioridadColor(String prioridad) {
    switch (prioridad.toLowerCase()) {
      case 'alta':
        return AppColors.criticalRed;
      case 'media':
        return AppColors.warningYellow;
      case 'baja':
        return AppColors.actionGreen;
      default:
        return Colors.grey;
    }
  }

  String _getPrioridadLabel(String prioridad) {
    switch (prioridad.toLowerCase()) {
      case 'alta':
        return 'Alta';
      case 'media':
        return 'Media';
      case 'baja':
        return 'Baja';
      default:
        return prioridad;
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year} '
        '${fecha.hour.toString().padLeft(2, '0')}:'
        '${fecha.minute.toString().padLeft(2, '0')}';
  }
}

class _ReporteMultimediaViewer extends StatefulWidget {
  final ReporteModel reporte;

  const _ReporteMultimediaViewer({required this.reporte});

  @override
  State<_ReporteMultimediaViewer> createState() =>
      _ReporteMultimediaViewerState();
}

class _ReporteMultimediaViewerState extends State<_ReporteMultimediaViewer> {
  late final PageController _pageController;
  int _currentIndex = 0;
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<int, Future<void>> _videoInitFutures = {};

  List<ArchivoMultimediaModel> get _archivos => widget.reporte.archivos;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _isVideo(ArchivoMultimediaModel archivo) {
    final type = archivo.mimeType ?? archivo.tipo;
    return type.toLowerCase().contains('video');
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.8;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            height: 5,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Archivos - #${widget.reporte.id ?? widget.reporte.codigoSeguimiento}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '${_archivos.length} ${_archivos.length == 1 ? 'archivo' : 'archivos'}',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _archivos.length,
              onPageChanged: (index) {
                _pauseVideo(_currentIndex);
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final archivo = _archivos[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _isVideo(archivo)
                      ? _buildVideoPreview(archivo, index)
                      : _buildImagePreview(archivo),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _archivos.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _currentIndex == i ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: _currentIndex == i
                      ? AppColors.primaryBlue
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildImagePreview(ArchivoMultimediaModel archivo) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: InteractiveViewer(
        child: Image.network(
          archivo.url,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: Colors.grey[500]),
                  const SizedBox(height: 8),
                  const Text('No se pudo cargar la imagen'),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideoPreview(ArchivoMultimediaModel archivo, int index) {
    final controller =
        _videoControllers[index] ??
        VideoPlayerController.networkUrl(Uri.parse(archivo.url));
    if (!_videoControllers.containsKey(index)) {
      _videoControllers[index] = controller
        ..setLooping(true)
        ..setVolume(1.0);
      _videoInitFutures[index] = controller.initialize();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          FutureBuilder(
            future: _videoInitFutures[index],
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                final aspectRatio = controller.value.aspectRatio == 0
                    ? 16 / 9
                    : controller.value.aspectRatio;
                return AspectRatio(
                  aspectRatio: aspectRatio,
                  child: VideoPlayer(controller),
                );
              }
              return Container(
                color: Colors.black,
                child: const Center(child: CircularProgressIndicator()),
              );
            },
          ),
          IconButton(
            iconSize: 64,
            color: Colors.white,
            icon: Icon(
              controller.value.isPlaying
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_fill_rounded,
            ),
            onPressed: () {
              setState(() {
                if (controller.value.isPlaying) {
                  controller.pause();
                } else {
                  controller.play();
                }
              });
            },
          ),
        ],
      ),
    );
  }

  void _pauseVideo(int index) {
    final controller = _videoControllers[index];
    if (controller != null && controller.value.isPlaying) {
      controller.pause();
    }
  }
}
