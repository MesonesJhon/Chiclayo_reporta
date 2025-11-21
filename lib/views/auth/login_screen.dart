import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../utils/app_colors.dart'; // Importa tus colores

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  static const String _rememberedDniKey = 'remembered_dni';

  @override
  void initState() {
    super.initState();
    _loadRememberedDni();
  }

  Future<void> _loadRememberedDni() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberedDni = prefs.getString(_rememberedDniKey);
      if (rememberedDni != null && rememberedDni.isNotEmpty) {
        setState(() {
          _dniController.text = rememberedDni;
          _rememberMe = true;
        });
      }
    } catch (e) {
      print('Error cargando DNI recordado: $e');
    }
  }

  Future<void> _saveRememberedDni(String dni) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_rememberedDniKey, dni);
    } catch (e) {
      print('Error guardando DNI recordado: $e');
    }
  }

  Future<void> _clearRememberedDni() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_rememberedDniKey);
    } catch (e) {
      print('Error limpiando DNI recordado: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final size = MediaQuery.of(context).size;

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
          child: SizedBox(
            height: size.height,
            child: Stack(
              children: [
                // Background decoration - Elementos más sutiles
                Positioned(
                  top: -size.width * 0.15,
                  right: -size.width * 0.05,
                  child: Container(
                    width: size.width * 0.4,
                    height: size.width * 0.4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -size.width * 0.2,
                  left: -size.width * 0.1,
                  child: Container(
                    width: size.width * 0.6,
                    height: size.width * 0.6,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Header with Logo
                      _buildHeader(),
                      const SizedBox(height: 40),

                      // Login Card
                      _buildLoginCard(authViewModel, context),
                      const SizedBox(height: 20),

                      // Footer
                      _buildFooter(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo Container con IMAGEN
        Container(
          width: 100,
          height: 100,
          // decoration: BoxDecoration(
          //   color: AppColors.white,
          //   borderRadius: BorderRadius.circular(20),
          //   boxShadow: [
          //     BoxShadow(
          //       color: Colors.black.withOpacity(0.15),
          //       blurRadius: 25,
          //       offset: const Offset(0, 10),
          //     ),
          //   ],
          // ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/app_logo.png',
              fit: BoxFit.contain,
              width: 60,
              height: 60,
              errorBuilder: (context, error, stackTrace) {
                // Fallback si la imagen no existe
                return Icon(
                  Icons.report_problem,
                  size: 50,
                  color: AppColors.chiclayoOrange,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'CHICLAYO REPORTA',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Municipalidad Provincial de Chiclayo',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
            fontWeight: FontWeight.w300,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginCard(AuthViewModel authViewModel, BuildContext context) {
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
            Text(
              'Iniciar Sesión',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryBlue,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresa tus credenciales para continuar',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // DNI Field
            _buildTextField(
              controller: _dniController,
              label: 'DNI',
              icon: Icons.badge_outlined,
              isPassword: false,
              keyboardType: TextInputType.number,
              maxLength: 8,
            ),
            const SizedBox(height: 20),

            // Password Field
            _buildTextField(
              controller: _passwordController,
              label: 'Contraseña',
              icon: Icons.lock_outline_rounded,
              isPassword: true,
            ),
            const SizedBox(height: 12),

            // Remember me and Forgot password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                        // Si se desactiva, limpiar el DNI guardado
                        if (!_rememberMe) {
                          _clearRememberedDni();
                        }
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      activeColor: AppColors.primaryBlue,
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _rememberMe = !_rememberMe;
                        });
                        if (!_rememberMe) {
                          _clearRememberedDni();
                        }
                      },
                      child: Text(
                        'Recordarme',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/forgot_password');
                  },
                  child: Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Error Message
            if (authViewModel.errorMessage.isNotEmpty)
              _buildErrorWidget(authViewModel.errorMessage),
            const SizedBox(height: 20),

            // Login Button
            _buildLoginButton(authViewModel, context),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isPassword,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      maxLength: maxLength,
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
        counterText: "",
      ),
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

  Widget _buildLoginButton(AuthViewModel authViewModel, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: authViewModel.isLoading
            ? null
            : () async {
                final dni = _dniController.text.trim();
                final password = _passwordController.text;

                // Guardar o limpiar DNI según el estado del checkbox
                if (_rememberMe && dni.isNotEmpty) {
                  await _saveRememberedDni(dni);
                } else {
                  await _clearRememberedDni();
                }

                final success = await authViewModel.login(dni, password);

                if (success && context.mounted) {
                  // Verificar el tipo de usuario para redirigir a la pantalla correcta
                  final user = authViewModel.currentUser;
                  if (user != null) {
                    // Usar el método helper isAdmin para verificar el tipo
                    if (user.isAdmin) {
                      Navigator.pushReplacementNamed(context, '/admin');
                    } else {
                      Navigator.pushReplacementNamed(context, '/home');
                    }
                  } else {
                    // Si no hay usuario, redirigir a home por defecto
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
                    'INGRESAR',
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

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        Text(
          '¿No tienes una cuenta?',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/register');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              'REGÍSTRATE AQUÍ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
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
    super.dispose();
  }
}
