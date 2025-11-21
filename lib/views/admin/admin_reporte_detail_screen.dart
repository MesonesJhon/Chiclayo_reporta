// Removed unused imports
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/admin_reportes_viewmodel.dart';
import 'package:intl/intl.dart';
import '../../models/reporte_model.dart';
import '../../utils/app_colors.dart';
import '../widgets/report_multimedia_viewer.dart';
import '../widgets/report_location_map.dart';

class AdminReporteDetailScreen extends StatefulWidget {
  final ReporteModel reporte;

  const AdminReporteDetailScreen({super.key, required this.reporte});

  @override
  State<AdminReporteDetailScreen> createState() =>
      _AdminReporteDetailScreenState();
}

class _AdminReporteDetailScreenState extends State<AdminReporteDetailScreen> {
  late String _currentStatus;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    // Convertir el estado de API a formato Display
    _currentStatus = _apiStatusToDisplay(widget.reporte.estado);
  }

  // Convertir estado de API a formato Display
  String _apiStatusToDisplay(String apiStatus) {
    switch (apiStatus.toLowerCase()) {
      case 'pendiente':
        return 'Pendiente';
      case 'en_proceso':
        return 'En Proceso';
      case 'resuelto':
        return 'Resuelto';
      case 'cerrado':
        return 'Cerrado';
      default:
        return apiStatus; // Si no coincide, devolver el original
    }
  }

  // Convertir estado de Display a formato API
  String _displayStatusToApi(String displayStatus) {
    switch (displayStatus) {
      case 'Pendiente':
        return 'pendiente';
      case 'En Proceso':
        return 'en_proceso';
      case 'Resuelto':
        return 'resuelto';
      case 'Cerrado':
        return 'cerrado';
      default:
        return displayStatus.toLowerCase();
    }
  }

  // Method to update status via API
  Future<void> _updateStatus(String newStatus) async {
    if (newStatus == _currentStatus) return;
    setState(() {
      _isUpdating = true;
    });

    // Convertir estado de display a formato API
    final apiStatus = _displayStatusToApi(newStatus);

    final viewModel = Provider.of<AdminReportesViewModel>(
      context,
      listen: false,
    );
    final success = await viewModel.actualizarEstadoReporte(
      widget.reporte.id!,
      apiStatus,
    );

    if (mounted) {
      setState(() {
        _isUpdating = false;
        if (success) {
          _currentStatus = newStatus;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Estado actualizado a $newStatus'),
              backgroundColor: AppColors.actionGreen,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error al actualizar el estado: ${viewModel.error}',
              ),
              backgroundColor: AppColors.criticalRed,
            ),
          );
        }
      });
    }
  }

  Color _getStatusColor(String status) {
    // Manejar tanto formato API como Display
    final statusLower = status.toLowerCase().replaceAll('_', ' ');
    switch (statusLower) {
      case 'pendiente':
        return AppColors.warningYellow;
      case 'en proceso':
        return AppColors.infoBlue;
      case 'resuelto':
        return AppColors.actionGreen;
      case 'cerrado':
        return AppColors.criticalRed;
      default:
        return Colors.grey;
    }
  }

  void _showStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Actualizar Estado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusOption('Pendiente', AppColors.warningYellow),
            _buildStatusOption('En Proceso', AppColors.infoBlue),
            _buildStatusOption('Resuelto', AppColors.actionGreen),
            _buildStatusOption('Cerrado', AppColors.criticalRed),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(String status, Color color) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: color, radius: 6),
      title: Text(status),
      onTap: () {
        Navigator.pop(context);
        _updateStatus(status);
      },
      selected: _currentStatus.toLowerCase() == status.toLowerCase(),
      selectedTileColor: color.withOpacity(0.1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final fecha = widget.reporte.fechaCreacion != null
        ? dateFormat.format(widget.reporte.fechaCreacion!)
        : 'Fecha desconocida';

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Detalle del Reporte'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          if (_isUpdating)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con Estado
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reporte #${widget.reporte.id}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            _currentStatus,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(_currentStatus),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getStatusColor(_currentStatus),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _currentStatus.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(_currentStatus),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.reporte.titulo,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        fecha,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Información del Ciudadano
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información del Ciudadano',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        Icons.person_rounded,
                        'Nombre',
                        widget.reporte.usuario?.nombreCompleto ??
                            (widget.reporte.usuarioId != null
                                ? 'Usuario #${widget.reporte.usuarioId}'
                                : 'No disponible'),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.badge_rounded,
                        'DNI',
                        widget.reporte.usuario?.dni ?? 'No disponible',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.phone_rounded,
                        'Teléfono',
                        widget.reporte.usuario?.telefono ?? 'No disponible',
                      ),
                      if (widget.reporte.usuario?.email != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.email_rounded,
                          'Email',
                          widget.reporte.usuario!.email!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Detalles del Reporte
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detalles del Incidente',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        Icons.category_rounded,
                        'Categoría',
                        widget.reporte.categoria?.nombre ?? 'Sin categoría',
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Descripción',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.reporte.descripcion,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Ubicación
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text(
                        'Ubicación del Incidente',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReportLocationMap(
                                reportId: widget.reporte.id.toString(),
                                reportTitle: widget.reporte.titulo,
                                direccion: widget.reporte.ubicacion?.direccion,
                                latitude: widget.reporte.ubicacion?.latitud,
                                longitude: widget.reporte.ubicacion?.longitud,
                                enableRouting: true,
                                autoRequestRoute: true,
                                showRouteButton: true,
                                routeButtonColor: AppColors.actionGreen,
                                routeButtonIcon: Icons.route_rounded,
                                buttonMode: 'start_trip',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.map_rounded),
                        label: const Text('Ver Mapa'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: AppColors.chiclayoOrange,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.reporte.ubicacion?.direccion ??
                                  'Ubicación no disponible',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Multimedia
            if (widget.reporte.archivos.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Evidencia Multimedia',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ReportMultimediaViewer(reporte: widget.reporte),
                  ],
                ),
              ),

            const SizedBox(height: 100), // Espacio para el botón flotante
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showStatusDialog,
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Actualizar Estado'),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[400]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
