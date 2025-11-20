import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../viewmodels/mis_reportes_viewmodel.dart';
import '../../models/reporte_model.dart';
import '../../models/archivo_multimedia_model.dart';
import '../../utils/app_colors.dart';
import '../widgets/report_location_map.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  final List<String> _filters = ['Todos', 'Activos', 'Resueltos', 'Pendientes'];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();

    // Cargar reportes al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MisReportesViewModel>().cargarReportes();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: _buildAppBar(context),
      body: _buildAnimatedBody(context),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: const Text(
              'MIS REPORTES',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0),
            ),
          );
        },
      ),
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildAnimatedBody(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: _buildBody(context),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de búsqueda y filtro
          _buildSearchAndFilter(),
          const SizedBox(height: 24),

          // Lista de reportes
          Expanded(child: _buildReportsList()),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: AppColors.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Buscar por ID o fecha',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Campo de búsqueda
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: InputBorder.none,
                hintText: 'Ej: #1234 o 03/01/2023',
                hintStyle: TextStyle(color: Colors.grey[600]),
                suffixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Filtro
          Row(
            children: [
              Icon(
                Icons.filter_list_rounded,
                color: AppColors.primaryBlue,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Filtro:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Consumer<MisReportesViewModel>(
                  builder: (context, viewModel, child) {
                    return DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: viewModel.filtro,
                        icon: Icon(
                          Icons.arrow_drop_down_rounded,
                          color: AppColors.primaryBlue,
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            viewModel.setFiltro(newValue);
                          }
                        },
                        items: _filters.map<DropdownMenuItem<String>>((
                          String value,
                        ) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList() {
    return Consumer<MisReportesViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (viewModel.error.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  viewModel.error,
                  style: TextStyle(color: Colors.red[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => viewModel.cargarReportes(),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final reports = viewModel.reportesFiltrados;

        if (reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  "No tienes reportes todavía.",
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.list_alt_rounded,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Mis Reportes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  '${reports.length} reportes',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  return _ReporteCard(reporte: reports[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReporteCard extends StatelessWidget {
  final ReporteModel reporte;

  const _ReporteCard({required this.reporte});

  @override
  Widget build(BuildContext context) {
    ArchivoMultimediaModel? archivoPrincipal;
    try {
      archivoPrincipal = reporte.archivos.firstWhere((a) => a.esPrincipal);
    } catch (e) {
      if (reporte.archivos.isNotEmpty) {
        archivoPrincipal = reporte.archivos.first;
      }
    }

    final urlImagen = archivoPrincipal?.url;

    // Determinar color del estado
    Color estadoColor;
    IconData estadoIcon;
    switch (reporte.estado.toLowerCase()) {
      case 'resuelto':
        estadoColor = AppColors.actionGreen;
        estadoIcon = Icons.check_circle_rounded;
        break;
      case 'en_proceso':
        estadoColor = AppColors.warningYellow;
        estadoIcon = Icons.pending_actions_rounded;
        break;
      case 'pendiente':
        estadoColor = AppColors.infoBlue;
        estadoIcon = Icons.schedule_rounded;
        break;
      default:
        estadoColor = Colors.grey;
        estadoIcon = Icons.help_outline_rounded;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ID y título
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "#${reporte.id ?? reporte.codigoSeguimiento}",
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    reporte.titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Imagen
            if (urlImagen != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  urlImagen,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      color: Colors.grey[200],
                      child: Icon(Icons.broken_image, color: Colors.grey[400]),
                    );
                  },
                ),
              ),

            if (urlImagen != null) const SizedBox(height: 12),

            // Estado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: estadoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(estadoIcon, color: estadoColor, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    reporte.estado.toUpperCase(),
                    style: TextStyle(
                      color: estadoColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Fecha y ubicación
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.grey[600],
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  reporte.fechaCreacion != null
                      ? reporte.fechaCreacion!.toString().substring(0, 10)
                      : 'Sin fecha',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.location_on_rounded,
                  color: Colors.grey[600],
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    reporte.ubicacion?.direccion ?? "Sin dirección",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Botones de acción
            Row(
              children: [
                // Ver fotos
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openMultimediaGallery(context, reporte),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      side: BorderSide(color: AppColors.primaryBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.collections_rounded, size: 16),
                    label: const Text(
                      'Multimedia',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Ver mapa
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReportLocationMap(
                            reportId:
                                reporte.id?.toString() ??
                                reporte.codigoSeguimiento,
                            reportTitle: reporte.titulo,
                            zone: reporte.ubicacion?.distrito,
                            direccion: reporte.ubicacion?.direccion,
                            latitude: reporte.ubicacion?.latitud,
                            longitude: reporte.ubicacion?.longitud,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.chiclayoOrange,
                      side: BorderSide(color: AppColors.chiclayoOrange),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.map_rounded, size: 16),
                    label: const Text(
                      'Mapa',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openMultimediaGallery(BuildContext context, ReporteModel reporte) {
    if (reporte.archivos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este reporte no tiene archivos aún')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReporteMultimediaViewer(reporte: reporte),
    );
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

  List<ArchivoMultimediaModel> get _archivos => widget.reporte.archivos;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _isVideo(ArchivoMultimediaModel archivo) {
    final type = archivo.mimeType ?? archivo.tipo;
    return type.toLowerCase().contains('video');
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el archivo'),
          backgroundColor: AppColors.criticalRed,
        ),
      );
    }
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
              onPageChanged: (index) => setState(() {
                _currentIndex = index;
              }),
              itemBuilder: (context, index) {
                final archivo = _archivos[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _isVideo(archivo)
                      ? _buildVideoPreview(archivo)
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
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.insert_drive_file, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _archivos[_currentIndex].nombre,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _archivos[_currentIndex].mimeType ?? '',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
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

  Widget _buildVideoPreview(ArchivoMultimediaModel archivo) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.play_circle_fill_rounded,
            color: Colors.white,
            size: 72,
          ),
          const SizedBox(height: 16),
          Text(
            archivo.nombre,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Tipo: ${archivo.mimeType ?? archivo.tipo}',
            style: TextStyle(color: Colors.grey[300]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openExternal(archivo.url),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Reproducir video'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
