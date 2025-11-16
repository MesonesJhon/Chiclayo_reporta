// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'viewmodels/auth_viewmodel.dart';
// import 'viewmodels/register_viewmodel.dart';
// import 'viewmodels/login_viewmodel.dart';
// import 'views/auth/login_screen.dart';
// import 'views/auth/register_screen.dart';
// import 'views/home/home_screen.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Cargar datos de autenticación guardados al iniciar la app
//   final authViewModel = AuthViewModel();
//   await authViewModel.loadAuthData();

//   runApp(MyApp(authViewModel: authViewModel));
// }

// class MyApp extends StatelessWidget {
//   final AuthViewModel? authViewModel;

//   const MyApp({super.key, this.authViewModel});

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider.value(value: authViewModel ?? AuthViewModel()),
//         ChangeNotifierProvider(create: (_) => RegisterViewModel()),
//         ChangeNotifierProvider(create: (_) => LoginViewModel()),
//       ],
//       child: MaterialApp(
//         title: 'Reportes Ciudadanos MPCh',
//         theme: ThemeData(
//           primarySwatch: Colors.blue,
//           visualDensity: VisualDensity.adaptivePlatformDensity,
//           useMaterial3: true,
//         ),
//         initialRoute: '/login',
//         routes: {
//           '/login': (context) => LoginScreen(),
//           '/register': (context) => const RegisterScreen(),
//           '/home': (context) => const HomeScreen(),
//         },
//         debugShowCheckedModeBanner: false,
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/register_viewmodel.dart';
import 'viewmodels/login_viewmodel.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/register_screen.dart';
import 'views/home/home_screen.dart';
import 'views/admin/admin_home_screen.dart';
import 'views/splash_screen.dart'; // Asegúrate de importar el SplashScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar datos de autenticación guardados al iniciar la app
  final authViewModel = AuthViewModel();
  await authViewModel.loadAuthData();

  runApp(MyApp(authViewModel: authViewModel));
}

class MyApp extends StatelessWidget {
  final AuthViewModel? authViewModel;

  const MyApp({super.key, this.authViewModel});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authViewModel ?? AuthViewModel()),
        ChangeNotifierProvider(create: (_) => RegisterViewModel()),
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
      ],
      child: MaterialApp(
        title: 'Reportes Ciudadanos MPCh',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
        ),
        initialRoute: '/splash', // Cambiado a splash como ruta inicial
        routes: {
          '/splash': (context) =>
              const SplashScreen(), // Nueva ruta para el splash
          '/login': (context) => LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/admin': (context) => const AdminHomeScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
