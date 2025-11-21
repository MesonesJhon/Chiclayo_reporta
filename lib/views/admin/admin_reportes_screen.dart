import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/admin_reportes_viewmodel.dart';
import '../../utils/app_colors.dart';
import '../widgets/admin_reporte_card.dart';
import 'admin_reporte_detail_screen.dart';

class AdminReportesScreen extends StatefulWidget {
  const AdminReportesScreen({super.key});

  @override
  State<AdminReportesScreen> createState() => _AdminReportesScreenState();
}

class _AdminReportesScreenState extends State<AdminReportesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Cargar reportes al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminReportesViewModel>().cargarReportes();
    });
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
        return apiStatus;
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'Gestión de Reportes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Buscador y Filtros
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primaryBlue,
            child: Column(
              children: [
                // Buscador
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    context.read<AdminReportesViewModel>().setSearchQuery(
                      value,
                    );
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar por ID, título...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: AppColors.backgroundWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
                const SizedBox(height: 12),
                // Filtros
                Row(
                  children: [
                    Expanded(
                      child: Consumer<AdminReportesViewModel>(
                        builder: (context, viewModel, _) {
                          // Convertir el valor del filtro de API a Display para mostrar
                          final displayValue = viewModel.filtroEstado == 'Todos'
                              ? 'Todos'
                              : _apiStatusToDisplay(viewModel.filtroEstado);
                          return _buildDropdownFilter(
                            context,
                            label: 'Estado',
                            value: displayValue,
                            items: [
                              'Todos',
                              'Pendiente',
                              'En Proceso',
                              'Resuelto',
                              'Cerrado',
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                // Convertir el valor de display a API para el filtro
                                final apiValue = value == 'Todos'
                                    ? 'Todos'
                                    : _displayStatusToApi(value);
                                viewModel.setFiltroEstado(apiValue);
                              }
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Consumer<AdminReportesViewModel>(
                        builder: (context, viewModel, _) {
                          return _buildDropdownFilter(
                            context,
                            label: 'Prioridad',
                            value: viewModel.filtroPrioridad,
                            items: ['Todas', 'Alta', 'Media', 'Baja'],
                            onChanged: (value) {
                              if (value != null) {
                                viewModel.setFiltroPrioridad(value);
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista de reportes
          Expanded(
            child: Consumer<AdminReportesViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (viewModel.error.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          viewModel.error,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[700]),
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

                if (viewModel.reportes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron reportes',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => viewModel.cargarReportes(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: viewModel.reportes.length,
                    itemBuilder: (context, index) {
                      final reporte = viewModel.reportes[index];
                      return AdminReporteCard(
                        reporte: reporte,
                        onEditStatus: () =>
                            _mostrarDialogoEstado(context, reporte, viewModel),
                        onViewDetails: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AdminReporteDetailScreen(reporte: reporte),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter(
    BuildContext context, {
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item.toUpperCase(),
                style: const TextStyle(fontSize: 12),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _mostrarDialogoEstado(
    BuildContext context,
    dynamic reporte,
    AdminReportesViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Estado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusOption(
              context,
              reporte,
              'pendiente',
              'Pendiente',
              AppColors.warningYellow,
              viewModel,
            ),
            _buildStatusOption(
              context,
              reporte,
              'en_proceso',
              'En Proceso',
              AppColors.infoBlue,
              viewModel,
            ),
            _buildStatusOption(
              context,
              reporte,
              'resuelto',
              'Resuelto',
              AppColors.actionGreen,
              viewModel,
            ),
            _buildStatusOption(
              context,
              reporte,
              'cerrado',
              'Cerrado',
              AppColors.criticalRed,
              viewModel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(
    BuildContext context,
    dynamic reporte,
    String statusValue,
    String statusLabel,
    Color color,
    AdminReportesViewModel viewModel,
  ) {
    // Comparar estados normalizados (ambos en formato API)
    final reporteEstado = reporte.estado.toLowerCase();
    final statusValueLower = statusValue.toLowerCase();
    final isSelected = reporteEstado == statusValueLower;
    return ListTile(
      leading: CircleAvatar(backgroundColor: color, radius: 6),
      title: Text(
        statusLabel,
        style: TextStyle(
          color: isSelected ? color : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: color.withAlpha(26),
      onTap: () async {
        Navigator.pop(context);
        if (!isSelected) {
          final success = await viewModel.actualizarEstadoReporte(
            reporte.id,
            statusValue,
          );
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Estado actualizado a $statusLabel'),
                backgroundColor: color,
              ),
            );
          }
        }
      },
    );
  }
}
