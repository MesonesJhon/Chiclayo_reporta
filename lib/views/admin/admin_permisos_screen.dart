import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class AdminPermisosScreen extends StatelessWidget {
  const AdminPermisosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'PERMISOS Y ROLES',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.admin_panel_settings_rounded,
              size: 120,
              color: AppColors.chiclayoOrange.withAlpha(128),
            ),
            const SizedBox(height: 24),
            const Text(
              'Permisos y Roles',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Gestiona los permisos y roles de los usuarios del sistema.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.chiclayoOrange.withAlpha(26),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Próximamente',
                style: TextStyle(
                  color: AppColors.chiclayoOrange,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
