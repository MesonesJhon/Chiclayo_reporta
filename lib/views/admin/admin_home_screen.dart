import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/admin_reportes_viewmodel.dart';
import '../../models/user_model.dart';
import '../../utils/app_colors.dart';
import 'admin_reportes_screen.dart';
import 'manage_users_screen.dart';
import 'admin_estadisticas_screen.dart';
import '../widgets/incident_map_widget.dart';
import 'admin_mapa_incidentes_screen.dart';
import 'admin_permisos_screen.dart';
import 'admin_soporte_screen.dart';
import '../../viewmodels/users_viewmodel.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

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

    // Cargar datos iniciales
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reportesViewModel = Provider.of<AdminReportesViewModel>(
        context,
        listen: false,
      );
      final usersViewModel = Provider.of<UsersViewModel>(
        context,
        listen: false,
      );

      reportesViewModel.cargarReportes();
      usersViewModel.loadUsers();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final user = authViewModel.currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: _buildAppBar(context),
      drawer: _buildDrawer(context, user),
      body: _buildAnimatedBody(context, authViewModel, user),
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
              'PANEL ADMIN',
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
      actions: [_buildNotificationButton(), _buildAdminMenu(context)],
    );
  }

  Widget _buildNotificationButton() {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            // Navegar a notificaciones
          },
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: AppColors.criticalRed,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: const Text(
              '5',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (value) {
        switch (value) {
          case 'logout':
            _showLogoutDialog(context);
            break;
          case 'settings':
            // Navegar a configuración
            break;
          case 'users':
            // Navegar a gestión de usuarios
            break;
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'users',
          child: Row(
            children: [
              Icon(Icons.people_rounded, size: 20),
              SizedBox(width: 8),
              Text('Gestión de Usuarios'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_rounded, size: 20),
              SizedBox(width: 8),
              Text('Configuración'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: AppColors.criticalRed,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Cerrar Sesión',
                style: TextStyle(color: AppColors.criticalRed),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context, UserModel? user) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.8,
      elevation: 10,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header del Drawer
          Container(
            height: 180,
            padding: const EdgeInsets.only(
              top: 30,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryBlue,
                  AppColors.primaryBlue.withOpacity(0.9),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 28,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.nombreCompleto ?? 'Administrador',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'ADMINISTRADOR',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  user?.email ?? 'admin@chiclayo.gob.pe',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Menú Items
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 10,
                ),
                children: [
                  _buildDrawerItem(
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard Principal',
                    color: AppColors.primaryBlue,
                    isActive: true, // Active item
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 5),
                  _buildDrawerItem(
                    icon: Icons.assignment_rounded,
                    title: 'Gestión de Reportes',
                    color: AppColors.actionGreen,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminReportesScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 5),
                  _buildDrawerItem(
                    icon: Icons.people_rounded,
                    title: 'Usuarios Registrados',
                    color: AppColors.chiclayoOrange,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/manage_users');
                    },
                  ),
                  const SizedBox(height: 5),
                  _buildDrawerItem(
                    icon: Icons.analytics_rounded,
                    title: 'Estadísticas Avanzadas',
                    color: AppColors.infoBlue,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminEstadisticasScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 5),
                  _buildDrawerItem(
                    icon: Icons.map_rounded,
                    title: 'Mapa de Incidentes',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AdminMapaIncidentesScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 5,
                    ),
                    child: Text(
                      'CONFIGURACIÓN',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings_rounded,
                    title: 'Configuración del Sistema',
                    color: Colors.grey[600]!,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.security_rounded,
                    title: 'Permisos y Roles',
                    color: Colors.amber[700]!,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminPermisosScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.help_rounded,
                    title: 'Soporte Técnico',
                    color: Colors.blueGrey[600]!,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminSoporteScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Footer del Drawer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Panel Admin v1.0.0',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Último acceso: Hoy',
                      style: TextStyle(color: Colors.grey[500], fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required Color color,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isActive
            ? Border.all(color: color.withOpacity(0.3), width: 1)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isActive ? color : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isActive ? Colors.white : color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isActive ? color : Colors.grey[800],
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isActive ? color : Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBody(
    BuildContext context,
    AuthViewModel authViewModel,
    UserModel? user,
  ) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: _buildBody(context, authViewModel, user),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AuthViewModel authViewModel,
    UserModel? user,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bienvenida Admin
          _buildWelcomeSection(context, user),
          const SizedBox(height: 20),

          // Estadísticas principales
          _buildAdminStats(),
          const SizedBox(height: 20),

          // Acciones rápidas de administración
          _buildAdminActions(context),
          const SizedBox(height: 20),

          // Reportes pendientes críticos
          _buildCriticalReports(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, UserModel? user) {
    String userName = 'Administrador';
    if (user != null) {
      if (user.nombres.isNotEmpty) {
        userName = user.nombres.split(' ').first;
      } else if (user.nombreCompleto.isNotEmpty) {
        userName = user.nombreCompleto.split(' ').first;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryBlue, Color(0xFF1E3A8A)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Panel de Control',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Bienvenido/a, $userName! 🛠️',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Gestiona reportes, usuarios y monitorea el sistema.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminStats() {
    final reportesViewModel = Provider.of<AdminReportesViewModel>(context);
    final usersViewModel = Provider.of<UsersViewModel>(context);

    return Column(
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              title: 'Pendientes',
              value: reportesViewModel.reportesPendientes.toString(),
              icon: Icons.pending_actions_rounded,
              color: Colors.orange,
              isLoading: reportesViewModel.isLoading,
            ),
            _buildStatCard(
              title: 'En Proceso',
              value: reportesViewModel.reportesEnProceso.toString(),
              icon: Icons.autorenew_rounded,
              color: Colors.blue,
              isLoading: reportesViewModel.isLoading,
            ),
            _buildStatCard(
              title: 'Resueltos',
              value: reportesViewModel.reportesResueltos.toString(),
              icon: Icons.check_circle_outline_rounded,
              color: Colors.green,
              isLoading: reportesViewModel.isLoading,
            ),
            _buildStatCard(
              title: 'Usuarios Activos',
              value: usersViewModel.activeUsersCount.toString(),
              icon: Icons.group_rounded,
              color: Colors.purple,
              isLoading: usersViewModel.isLoading,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          height: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: const IncidentMapWidget(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isLoading,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                ),
            ],
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 360;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isSmallScreen ? 1.2 : 1.4,
              children: [
                _AdminActionCard(
                  icon: Icons.assignment_rounded,
                  title: 'Gestionar Reportes',
                  subtitle: 'Ver y asignar',
                  color: AppColors.primaryBlue,
                  gradient: LinearGradient(
                    colors: [AppColors.primaryBlue, AppColors.infoBlue],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminReportesScreen(),
                      ),
                    );
                  },
                ),
                _AdminActionCard(
                  icon: Icons.people_rounded,
                  title: 'Usuarios',
                  subtitle: 'Gestionar usuarios',
                  color: AppColors.actionGreen,
                  gradient: LinearGradient(
                    colors: [AppColors.actionGreen, Colors.green],
                  ),
                  onTap: () {
                    Navigator.pushNamed(context, '/manage_users');
                  },
                ),
                _AdminActionCard(
                  icon: Icons.analytics_rounded,
                  title: 'Estadísticas',
                  subtitle: 'Reportes avanzados',
                  color: AppColors.chiclayoOrange,
                  gradient: LinearGradient(
                    colors: [AppColors.chiclayoOrange, Colors.orange],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminEstadisticasScreen(),
                      ),
                    );
                  },
                ),
                _AdminActionCard(
                  icon: Icons.settings_rounded,
                  title: 'Configuración',
                  subtitle: 'Ajustes del sistema',
                  color: Colors.purple,
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.purpleAccent],
                  ),
                  onTap: () {
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCriticalReports() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.criticalRed,
              size: 18,
            ),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                'Reportes Críticos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminReportesScreen(),
                  ),
                );
              },
              child: Text(
                'Ver todos',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Usar Column en lugar de ListView.builder para evitar overflow
        Column(
          children: [
            _CriticalReportItem(
              data: _CriticalReportData(
                'Bache crítico en Av. Balta',
                'Vía Principal',
                'ALTA',
                'Hace 6h',
                AppColors.criticalRed,
                Icons.map_rounded,
              ),
            ),
            const SizedBox(height: 8),
            _CriticalReportItem(
              data: _CriticalReportData(
                'Semáforo fuera de servicio',
                'Intersección Balta-Leguía',
                'URGENTE',
                'Hace 3h',
                AppColors.criticalRed,
                Icons.traffic_rounded,
              ),
            ),
            const SizedBox(height: 8),
            _CriticalReportItem(
              data: _CriticalReportData(
                'Inundación en parque',
                'Parque Principal',
                'MEDIA',
                'Hace 1d',
                AppColors.warningYellow,
                Icons.water_damage_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.logout_rounded,
                  size: 48,
                  color: AppColors.criticalRed,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cerrar Sesión',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '¿Estás seguro de que quieres cerrar sesión?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                          side: BorderSide(color: AppColors.primaryBlue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          if (context.mounted) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (loadingContext) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          try {
                            final authViewModel = Provider.of<AuthViewModel>(
                              context,
                              listen: false,
                            );
                            await authViewModel.logout();

                            if (context.mounted) {
                              Navigator.pop(context);
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/login',
                                (route) => false,
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al cerrar sesión: $e'),
                                  backgroundColor: AppColors.criticalRed,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.criticalRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cerrar Sesión'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final Color color;
  final IconData icon;

  const _AdminStatCard({
    required this.title,
    required this.value,
    required this.change,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = change.startsWith('+');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isPositive
                      ? AppColors.actionGreen.withOpacity(0.1)
                      : AppColors.criticalRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: isPositive
                        ? AppColors.actionGreen
                        : AppColors.criticalRed,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _AdminActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Gradient gradient;
  final VoidCallback onTap;

  const _AdminActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: gradient,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CriticalReportData {
  final String title;
  final String location;
  final String priority;
  final String date;
  final Color priorityColor;
  final IconData icon;

  _CriticalReportData(
    this.title,
    this.location,
    this.priority,
    this.date,
    this.priorityColor,
    this.icon,
  );
}

class _CriticalReportItem extends StatelessWidget {
  final _CriticalReportData data;

  const _CriticalReportItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: data.priorityColor, width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: data.priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(data.icon, color: data.priorityColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.location,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: data.priorityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            data.priority,
                            style: TextStyle(
                              fontSize: 9,
                              color: data.priorityColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          data.date,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
