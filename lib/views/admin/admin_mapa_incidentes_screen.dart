import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/admin_reportes_viewmodel.dart';
import '../../utils/app_colors.dart';
import '../widgets/incident_map_widget.dart';

class AdminMapaIncidentesScreen extends StatelessWidget {
  const AdminMapaIncidentesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminReportesViewModel>();

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: _buildAppBar(viewModel),
      body: const IncidentMapWidget(),
    );
  }

  AppBar _buildAppBar(AdminReportesViewModel viewModel) {
    return AppBar(
      title: const Text(
        'MAPA DE INCIDENTES',
        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0),
      ),
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: viewModel.cargarReportes,
          tooltip: 'Actualizar',
        ),
      ],
    );
  }
}
