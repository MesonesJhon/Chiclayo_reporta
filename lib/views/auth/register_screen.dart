import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/register_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../utils/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarEstadoServicio();
    });
  }

  void _verificarEstadoServicio() {
    final registerViewModel = context.read<RegisterViewModel>();
    registerViewModel.verificarEstadoDecolecta();
  }

  @override
  Widget build(BuildContext context) {
    final registerViewModel = context.watch<RegisterViewModel>();
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryBlue,
              Color(0xFF1E40AF),
              Color(0xFF3B82F6),
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Header
                _buildHeader(context),
                const SizedBox(height: 30),

                // Registration Card
                _buildRegistrationCard(
                  registerViewModel,
                  authViewModel,
                  context,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        // Back Button
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/logos/app_logo.png',
              fit: BoxFit.contain,
              width: 50,
              height: 50,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 40,
                  color: AppColors.chiclayoOrange,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'Crear Cuenta',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Completa tus datos para registrarte',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
            fontWeight: FontWeight.w300,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRegistrationCard(
    RegisterViewModel registerViewModel,
    AuthViewModel authViewModel,
    BuildContext context,
  ) {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      shadowColor: Colors.black.withOpacity(0.3),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            // Información del servicio
            if (registerViewModel.estadoServicio.isNotEmpty)
              _buildServiceStatus(registerViewModel),

            const SizedBox(height: 20),

            // Campo DNI
            _buildDNIField(registerViewModel),
            const SizedBox(height: 20),

            // Botón de consulta manual
            if (!registerViewModel.dniVerified &&
                registerViewModel.dni.length == 8)
              _buildVerifyButton(registerViewModel),

            // Datos de RENIEC verificados
            if (registerViewModel.dniVerified &&
                registerViewModel.nombres.isNotEmpty)
              _buildVerifiedData(registerViewModel),

            // Campos adicionales
            _buildAdditionalFields(registerViewModel),
            const SizedBox(height: 20),

            // Mensajes de error
            if (registerViewModel.errorMessage.isNotEmpty)
              _buildErrorWidget(registerViewModel.errorMessage),

            if (authViewModel.errorMessage.isNotEmpty)
              _buildErrorWidget(authViewModel.errorMessage),

            const SizedBox(height: 20),

            // Botón de registro
            _buildRegisterButton(registerViewModel, authViewModel, context),

            const SizedBox(height: 16),

            // Enlace a login
            _buildLoginLink(context),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceStatus(RegisterViewModel registerViewModel) {
    final isAvailable = registerViewModel.estadoServicio.contains('disponible');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAvailable
            ? AppColors.actionGreen.withOpacity(0.1)
            : AppColors.warningYellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAvailable ? AppColors.actionGreen : AppColors.warningYellow,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isAvailable
                ? Icons.check_circle_rounded
                : Icons.warning_amber_rounded,
            color: isAvailable
                ? AppColors.actionGreen
                : AppColors.warningYellow,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              registerViewModel.estadoServicio,
              style: TextStyle(
                color: isAvailable
                    ? AppColors.actionGreen
                    : AppColors.warningYellow,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDNIField(RegisterViewModel registerViewModel) {
    return TextFormField(
      controller: _dniController,
      keyboardType: TextInputType.number,
      style: TextStyle(
        fontSize: 16,
        color: Colors.grey[800],
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: 'DNI',
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
        hintText: 'Ingrese su DNI',
        prefixIcon: Icon(Icons.badge_outlined, color: AppColors.primaryBlue),
        suffixIcon: registerViewModel.consultandoReniec
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryBlue,
                  ),
                ),
              )
            : registerViewModel.dniVerified
            ? Icon(Icons.verified_rounded, color: AppColors.actionGreen)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
        counterText: "",
      ),
      maxLength: 8,
      onChanged: (value) {
        registerViewModel.setDni(value);
        if (value != _dniController.text) {
          _dniController.text = value;
          _dniController.selection = TextSelection.collapsed(
            offset: value.length,
          );
        }
      },
    );
  }

  Widget _buildVerifyButton(RegisterViewModel registerViewModel) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: registerViewModel.consultandoReniec
            ? null
            : registerViewModel.consultarDniDecolecta,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: registerViewModel.consultandoReniec
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Verificar DNI con RENIEC',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildVerifiedData(RegisterViewModel registerViewModel) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.actionGreen.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.actionGreen.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: AppColors.actionGreen,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Datos verificados con RENIEC',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.actionGreen,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow('DNI:', registerViewModel.dni),
              _buildInfoRow('Nombres:', registerViewModel.nombres),
              _buildInfoRow(
                'Apellido Paterno:',
                registerViewModel.apellidoPaterno,
              ),
              _buildInfoRow(
                'Apellido Materno:',
                registerViewModel.apellidoMaterno,
              ),
              _buildInfoRow(
                'Nombre Completo:',
                registerViewModel.nombreCompleto,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalFields(RegisterViewModel registerViewModel) {
    return Column(
      children: [
        const SizedBox(height: 20),
        _buildTextField(
          controller: _emailController,
          label: 'Email (opcional)',
          icon: Icons.email_rounded,
          keyboardType: TextInputType.emailAddress,
          onChanged: registerViewModel.setEmail,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _telefonoController,
          label: 'Teléfono (opcional)',
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          onChanged: registerViewModel.setTelefono,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          label: 'Contraseña',
          icon: Icons.lock_rounded,
          isPassword: true,
          onChanged: registerViewModel.setPassword,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _confirmPasswordController,
          label: 'Confirmar Contraseña',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          onChanged: registerViewModel.setConfirmPassword,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    required Function(String) onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: 16,
        color: Colors.grey[800],
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: AppColors.primaryBlue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildErrorWidget(String errorMessage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.criticalRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.criticalRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AppColors.criticalRed,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorMessage,
              style: TextStyle(
                color: AppColors.criticalRed,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton(
    RegisterViewModel registerViewModel,
    AuthViewModel authViewModel,
    BuildContext context,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed:
            (authViewModel.isLoading || registerViewModel.consultandoReniec)
            ? null
            : () async {
                if (registerViewModel.validateForm()) {
                  final success = await authViewModel.registerWithData(
                    registerViewModel.toJson(),
                  );
                  if (success && mounted) {
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.actionGreen,
          foregroundColor: Colors.white,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shadowColor: AppColors.actionGreen.withOpacity(0.4),
        ),
        child: authViewModel.isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'CREAR CUENTA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
      ),
    );
  }

  Widget _buildLoginLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Ya tienes una cuenta?',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, '/login'),
          child: Text(
            'Inicia Sesión',
            style: TextStyle(
              color: AppColors.primaryBlue,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _dniController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }
}
