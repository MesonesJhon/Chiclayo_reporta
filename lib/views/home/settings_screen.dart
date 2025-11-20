import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../models/user_model.dart';
import '../../utils/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _pushNotifications = true;
  bool _emailNotifications = true;
  String _selectedLanguage = 'Español';

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

    // Cargar datos del usuario actual
    _loadUserData();
  }

  void _loadUserData() {
    // Aquí cargarías los datos reales del usuario
    _nameController.text = 'María';
    _lastNameController.text = 'García López';
    _emailController.text = 'maria.garcia@email.com';
    _phoneController.text = '+51 987 654 321';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final user = authViewModel.currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: _buildAppBar(context),
      body: _buildAnimatedBody(context, authViewModel),
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
              'CONFIGURACIÓN',
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

  Widget _buildAnimatedBody(BuildContext context, AuthViewModel authViewModel) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: _buildBody(context, authViewModel),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AuthViewModel authViewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información personal
          _buildPersonalInfoSection(),
          const SizedBox(height: 24),

          // Seguridad
          _buildSecuritySection(context),
          const SizedBox(height: 24),

          // Preferencias
          _buildPreferencesSection(),
          const SizedBox(height: 24),

          // Información municipal
          _buildMunicipalInfoSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
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
          Row(
            children: [
              Icon(
                Icons.person_rounded,
                color: AppColors.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Información personal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              children: [
                _buildFormField(
                  controller: _nameController,
                  label: 'Nombre',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _lastNameController,
                  label: 'Apellidos',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _emailController,
                  label: 'Correo electrónico',
                  icon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _phoneController,
                  label: 'Teléfono',
                  icon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _savePersonalInfo,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Guardar cambios',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: InputBorder.none,
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: AppColors.primaryBlue, size: 20),
        ),
      ),
    );
  }

  Widget _buildSecuritySection(BuildContext context) {
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
          Row(
            children: [
              Icon(
                Icons.security_rounded,
                color: AppColors.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Seguridad',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.criticalRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.lock_reset_rounded,
                color: AppColors.criticalRed,
                size: 20,
              ),
            ),
            title: const Text(
              'Cambiar contraseña',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey[400],
            ),
            onTap: () => _showChangePasswordDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
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
          Row(
            children: [
              Icon(
                Icons.settings_rounded,
                color: AppColors.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Preferencias',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPreferenceSwitch(
            title: 'Notificaciones push activadas',
            value: _pushNotifications,
            onChanged: (value) {
              setState(() {
                _pushNotifications = value;
              });
            },
            icon: Icons.notifications_active_rounded,
          ),
          const SizedBox(height: 12),
          _buildPreferenceSwitch(
            title: 'Recibir correos de seguimiento',
            value: _emailNotifications,
            onChanged: (value) {
              setState(() {
                _emailNotifications = value;
              });
            },
            icon: Icons.email_rounded,
          ),
          const SizedBox(height: 16),
          _buildLanguageSelector(),
        ],
      ),
    );
  }

  Widget _buildPreferenceSwitch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.infoBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.language_rounded,
              color: AppColors.infoBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Idioma',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              _selectedLanguage,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMunicipalInfoSection() {
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
          Row(
            children: [
              Icon(
                Icons.account_balance_rounded,
                color: AppColors.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Información municipal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Municipalidad Provincial de Chiclayo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.phone_rounded,
                      color: AppColors.primaryBlue,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(074) 123456',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: AppColors.primaryBlue,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Av. Balta 815, Chiclayo',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
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

  void _savePersonalInfo() {
    if (_formKey.currentState!.validate()) {
      // Lógica para guardar la información personal
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Información guardada exitosamente'),
          backgroundColor: AppColors.actionGreen,
        ),
      );
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.criticalRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_reset_rounded,
                    size: 30,
                    color: AppColors.criticalRed,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cambiar Contraseña',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Función de cambio de contraseña en desarrollo...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Entendido'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
