import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // Navegar después de la animación
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _navigateToNextScreen(context);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: Stack(
        children: [
          // Fondo con gradiente
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primaryBlue, Color(0xFF1E40AF)],
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo animado CON IMAGEN
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 140,
                    height: 140,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/app_logo.png', // ✅ Ruta de tu imagen
                        fit: BoxFit.contain,
                        width: 80,
                        height: 80,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback si la imagen no existe
                          return Icon(
                            Icons.spoke_rounded,
                            size: 60,
                            color: const Color.fromARGB(255, 242, 239, 238),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Título de la app
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        'CHICLAYO REPORTA',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tu seguridad es nuestra prioridad',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                          color: AppColors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                // Loading indicator - Puntos saltando
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _JumpingDotsLoader(
                    dotColor: const Color.fromARGB(255, 241, 240, 240),
                  ),
                ),
              ],
            ),
          ),

          // Footer con información
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Text(
                    'Heroica Ciudad de Chiclayo',
                    style: TextStyle(
                      color: AppColors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Versión 1.0',
                    style: TextStyle(
                      color: AppColors.white.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToNextScreen(BuildContext context) {
    // Verificar si hay un usuario autenticado
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final user = authViewModel.currentUser;

    if (user != null && authViewModel.isAuthenticated) {
      // Si hay usuario autenticado, redirigir según su tipo usando el método helper
      if (user.isAdmin) {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      // Si no hay usuario autenticado, ir al login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}

// Widget de puntos saltando
class _JumpingDotsLoader extends StatefulWidget {
  final Color dotColor;
  final double dotSize;
  final Duration duration;

  const _JumpingDotsLoader({
    this.dotColor = const Color.fromARGB(255, 241, 240, 240),
    this.dotSize = 8.0,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<_JumpingDotsLoader> createState() => __JumpingDotsLoaderState();
}

class __JumpingDotsLoaderState extends State<_JumpingDotsLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 20,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final double animationValue = _controller.value;
              // Cada punto tiene su propio timing (desfase de 0.2)
              final double dotValue = (animationValue + index * 0.2) % 1.0;

              // Función para el salto suave (usa curva seno)
              final double translateY =
                  -10.0 * math.sin(dotValue * 2 * math.pi);
              final double scale = 1.0 + 0.3 * math.sin(dotValue * 2 * math.pi);

              return Transform(
                transform: Matrix4.identity()
                  ..translate(0.0, translateY)
                  ..scale(scale, scale),
                child: Container(
                  width: widget.dotSize,
                  height: widget.dotSize,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    color: widget.dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
