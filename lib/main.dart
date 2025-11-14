import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Asegúrate de importar provider
import 'package:chiclayo_reporte/viewmodels/user_viewModel.dart'; // Asegúrate de importar el UserViewModel
import 'package:chiclayo_reporte/views/user_login_view.dart'; // Asegúrate de importar la vista

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UserViewModel>(
      create: (context) =>
          UserViewModel(), // Crea la instancia de UserViewModel
      child: MaterialApp(
        title: 'Flutter Login',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: UserLoginView(), // Usa tu vista de login
      ),
    );
  }
}
