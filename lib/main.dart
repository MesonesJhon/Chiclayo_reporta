import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/register_viewmodel.dart';
import 'viewmodels/login_viewmodel.dart';
import 'viewmodels/nuevo_reporte_viewmodel.dart';
import 'viewmodels/mis_reportes_viewmodel.dart';
import 'viewmodels/reportes_publicos_viewmodel.dart';
import 'viewmodels/users_viewmodel.dart';
import 'viewmodels/admin_reportes_viewmodel.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/register_screen.dart';
import 'views/auth/forgot_password_screen.dart';
import 'views/auth/reset_password_screen.dart';
import 'views/home/home_screen.dart';
import 'views/home/reporte_screen.dart';
import 'views/home/nuevo_reporte_screen.dart';
import 'views/admin/admin_home_screen.dart';
import 'views/admin/manage_users_screen.dart';
import 'views/admin/admin_estadisticas_screen.dart';
import 'views/admin/admin_mapa_incidentes_screen.dart';
import 'views/admin/admin_permisos_screen.dart';
import 'views/admin/admin_soporte_screen.dart';
import 'views/home/mis_reportes_screen.dart';
import 'views/home/mapa_reportes_publicos_screen.dart';
import 'views/home/seguimiento_screen.dart';
import 'views/splash_screen.dart';
import 'views/home/settings_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Inicializar servicio de notificaciones
    final notificationService = NotificationService();
    await notificationService.initialize();
  } catch (e) {
    print("Error initializing Firebase: $e");
  }

  // Cargar datos de autenticación guardados al iniciar la app
  final authViewModel = AuthViewModel();
  await authViewModel.loadAuthData();

  runApp(MyApp(authViewModel: authViewModel));
}

class MyApp extends StatefulWidget {
  final AuthViewModel? authViewModel;

  const MyApp({super.key, this.authViewModel});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final authViewModel = widget.authViewModel ?? AuthViewModel();

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App está en segundo plano o pausada
      print('App pausada/inactiva');
    } else if (state == AppLifecycleState.detached) {
      // App está siendo cerrada
      print('App cerrada - limpiando sesión');
      authViewModel.logout();
    } else if (state == AppLifecycleState.resumed) {
      // App volvió al primer plano
      print('App resumida');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: widget.authViewModel ?? AuthViewModel(),
        ),
        ChangeNotifierProvider(create: (_) => RegisterViewModel()),
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => NuevoReporteViewModel()),
        ChangeNotifierProvider(create: (_) => MisReportesViewModel()),
        ChangeNotifierProvider(create: (_) => ReportesPublicosViewModel()),
        ChangeNotifierProvider(create: (_) => UsersViewModel()),
        ChangeNotifierProvider(create: (_) => AdminReportesViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
      ],
      child: MaterialApp(
        title: 'Reportes Ciudadanos MPCh',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
        ),
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot_password': (context) => const ForgotPasswordScreen(),
          '/reset_password': (context) => const ResetPasswordScreen(),
          '/home': (context) => const HomeScreen(),
          '/admin': (context) => const AdminHomeScreen(),
          '/manage_users': (context) => const ManageUsersScreen(),
          '/admin_estadisticas': (context) => const AdminEstadisticasScreen(),
          '/admin_mapa': (context) => const AdminMapaIncidentesScreen(),
          '/admin_permisos': (context) => const AdminPermisosScreen(),
          '/admin_soporte': (context) => const AdminSoporteScreen(),
          '/reporte': (context) => const CreateReportScreen(),
          '/nuevo_reporte': (context) => const NuevoReporteScreen(),
          '/mis_reportes': (context) => const MyReportsScreen(),
          '/mapa_reportes': (context) => const MapaReportesPublicosScreen(),
          '/seguimiento': (context) => const SeguimientoScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
