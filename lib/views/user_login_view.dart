import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chiclayo_reporte/viewmodels/user_viewModel.dart';

class UserLoginView extends StatelessWidget {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: SingleChildScrollView(
        // Añadido para hacer que el contenido sea desplazable
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Input fields for username and password
              TextField(
                controller: usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              SizedBox(height: 20),

              // Consumer for UserViewModel to handle state changes (error, authResponse)
              Consumer<UserViewModel>(
                builder: (context, viewModel, child) {
                  // Si hay un error, muestra el mensaje
                  if (viewModel.errorMessage.isNotEmpty) {
                    return Text(
                      viewModel.errorMessage,
                      style: TextStyle(color: Colors.red),
                    );
                  }

                  // Si la respuesta es exitosa, muestra el token
                  if (viewModel.authResponse != null) {
                    return Text(
                      'Login exitoso, token: ${viewModel.authResponse!.accessToken}',
                      style: TextStyle(color: Colors.green),
                    );
                  }

                  return Container(); // Si no hay respuesta o error, retorna un contenedor vacío
                },
              ),
              SizedBox(height: 20),

              // Button to trigger the login process
              ElevatedButton(
                onPressed: () {
                  String username = usernameController.text;
                  String password = passwordController.text;

                  // Validate if the username or password is empty
                  if (username.isEmpty || password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Por favor, ingresa tu usuario y contraseña',
                        ),
                      ),
                    );
                    return; // Return early if validation fails
                  }

                  // Call the login method from UserViewModel
                  context.read<UserViewModel>().login(username, password);
                },
                child: Text('Login'),
              ),

              // Show a loading indicator if the login is being processed
              Consumer<UserViewModel>(
                builder: (context, viewModel, child) {
                  if (viewModel.isLoading) {
                    return CircularProgressIndicator(); // Show loading while waiting for login
                  }
                  return Container(); // If not loading, return an empty container
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
