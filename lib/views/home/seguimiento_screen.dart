import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/mis_reportes_viewmodel.dart';
import '../../models/reporte_model.dart';
import '../../utils/app_colors.dart';
import 'nuevo_reporte_screen.dart';

class SeguimientoScreen extends StatefulWidget {
  const SeguimientoScreen({super.key});

  @override
  State<SeguimientoScreen> createState() => _SeguimientoScreenState();
}

class _SeguimientoScreenState extends State<SeguimientoScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MisReportesViewModel>().cargarReportes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ReporteModel> _filtrarReportes(List<ReporteModel> reportes) {
    if (_searchQuery.isEmpty) {
      return reportes;
    }
    final query = _searchQuery.toLowerCase();
    return reportes.where((reporte) {
      return reporte.codigoSeguimiento.toLowerCase().contains(query) ||
          reporte.titulo.toLowerCase().contains(query) ||
          reporte.estado.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'SEGUIMIENTO',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Consumer<MisReportesViewModel>(
        builder: (context, viewModel, child) {
          final reportesFiltrados = _filtrarReportes(viewModel.reportes);

          return Column(
            children: [
              // Barra de búsqueda
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por código, título o estado...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primaryBlue),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),

              // Estadísticas rápidas
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: Colors.white,
                child: Row(
                  children: [
                    _buildStatChip(
                      'Total',
                      viewModel.reportes.length.toString(),
                      AppColors.primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      'Activos',
                      viewModel.reportes
                          .where(
                            (r) =>
                                r.estado != 'resuelto' &&
                                r.estado != 'cancelado',
                          )
                          .length
                          .toString(),
                      AppColors.warningYellow,
                    ),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      'Resueltos',
                      viewModel.reportes
                          .where((r) => r.estado == 'resuelto')
                          .length
                          .toString(),
                      AppColors.actionGreen,
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Lista de reportes
              Expanded(
                child: viewModel.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : reportesFiltrados.isEmpty
                    ? _buildEmptyState(_searchQuery.isNotEmpty)
                    : RefreshIndicator(
                        onRefresh: () => viewModel.cargarReportes(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: reportesFiltrados.length,
                          itemBuilder: (context, index) {
                            return _ReporteCard(
                              reporte: reportesFiltrados[index],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => NuevoReporteScreen(
                                      reporteAEditar: reportesFiltrados[index],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isSearching) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearching ? Icons.search_off : Icons.track_changes_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isSearching
                  ? 'No se encontraron reportes'
                  : 'No tienes reportes aún',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Intenta con otro código o término de búsqueda'
                  : 'Crea tu primer reporte para comenzar',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            if (!isSearching) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/nuevo_reporte');
                },
                icon: const Icon(Icons.add),
                label: const Text('Crear Reporte'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReporteCard extends StatelessWidget {
  final ReporteModel reporte;
  final VoidCallback onTap;

  const _ReporteCard({required this.reporte, required this.onTap});

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'resuelto':
        return AppColors.actionGreen;
      case 'en_proceso':
        return AppColors.warningYellow;
      case 'pendiente':
        return AppColors.infoBlue;
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

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Sin fecha';
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  String _formatearFechaRelativa(DateTime? fecha) {
    if (fecha == null) return 'Sin fecha';

    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inDays == 0) {
      return 'Hoy';
    } else if (diferencia.inDays == 1) {
      return 'Ayer';
    } else if (diferencia.inDays < 7) {
      return 'Hace ${diferencia.inDays} días';
    } else {
      return _formatearFecha(fecha);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoColor = _getEstadoColor(reporte.estado);
    final estadoLabel = _getEstadoLabel(reporte.estado);
    final prioridadColor = _getPrioridadColor(reporte.prioridad);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Código y Estado
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.qr_code, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            reporte.codigoSeguimiento,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryBlue,
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: estadoColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      estadoLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: estadoColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Título
              Text(
                reporte.titulo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Categoría y Prioridad
              Row(
                children: [
                  if (reporte.categoria != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (reporte.categoria!.icono != null) ...[
                            Text(
                              reporte.categoria!.icono!,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            reporte.categoria!.nombre,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: prioridadColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag, size: 12, color: prioridadColor),
                        const SizedBox(width: 4),
                        Text(
                          reporte.prioridad.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: prioridadColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Fechas
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Creado: ${_formatearFechaRelativa(reporte.fechaCreacion)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  if (reporte.fechaActualizacion != null) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.update, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Actualizado: ${_formatearFechaRelativa(reporte.fechaActualizacion)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),

              // Barra de progreso del estado
              const SizedBox(height: 12),
              _buildProgressBar(reporte.estado, estadoColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(String estado, Color color) {
    double progress = 0.0;
    String label = '';

    switch (estado.toLowerCase()) {
      case 'pendiente':
        progress = 0.25;
        label = 'En revisión';
        break;
      case 'en_proceso':
        progress = 0.65;
        label = 'En proceso';
        break;
      case 'resuelto':
        progress = 1.0;
        label = 'Completado';
        break;
      case 'cancelado':
        progress = 0.0;
        label = 'Cancelado';
        break;
      default:
        progress = 0.0;
        label = 'Desconocido';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
