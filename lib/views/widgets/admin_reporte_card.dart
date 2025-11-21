import 'package:flutter/material.dart';
import '../../../models/reporte_model.dart';
import '../../../models/archivo_multimedia_model.dart';
import '../../../utils/app_colors.dart';
import 'report_location_map.dart';
import 'report_multimedia_viewer.dart';

class AdminReporteCard extends StatelessWidget {
  final ReporteModel reporte;
  final VoidCallback onEditStatus;
  final VoidCallback onViewDetails;

  const AdminReporteCard({
    super.key,
    required this.reporte,
    required this.onEditStatus,
    required this.onViewDetails,
  });

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
      case 'cancelado':
        estadoColor = AppColors.criticalRed;
        estadoIcon = Icons.cancel_rounded;
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
                    color: AppColors.primaryBlue.withAlpha(26),
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
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'status') {
                      onEditStatus();
                    } else if (value == 'details') {
                      onViewDetails();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'status',
                      child: Row(
                        children: [
                          Icon(Icons.edit_attributes_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('Cambiar Estado'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'details',
                      child: Row(
                        children: [
                          Icon(Icons.visibility_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('Ver Detalles'),
                        ],
                      ),
                    ),
                  ],
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

            // Estado y Prioridad
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: estadoColor.withAlpha(26),
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
                const SizedBox(width: 8),
                // Prioridad
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getPrioridadColor(reporte.prioridad).withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flag_rounded,
                        color: _getPrioridadColor(reporte.prioridad),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        reporte.prioridad.toUpperCase(),
                        style: TextStyle(
                          color: _getPrioridadColor(reporte.prioridad),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                    onPressed: () {
                      if (reporte.archivos.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Este reporte no tiene archivos'),
                          ),
                        );
                        return;
                      }
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) =>
                            ReportMultimediaViewer(reporte: reporte),
                      );
                    },
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
                            enableRouting: true,
                            autoRequestRoute: true,
                            showRouteButton: false,
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
}
