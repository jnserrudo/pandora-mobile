import 'package:flutter/material.dart';
// Más adelante importaremos el ApiService
import 'package:pandora_app/services/api_service.dart';

import 'package:pandora_app/screens/register_page.dart';
import 'package:pandora_app/services/auth_services.dart';

import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Accedemos al AuthService usando Provider. `listen: false` es importante
      // aquí porque solo queremos llamar a un método, no redibujar el widget.
      final authService = Provider.of<AuthService>(context, listen: false);

      try {
        final response = await ApiService.login(
          identifier: _identifierController.text,
          password: _passwordController.text,
        );

        // Si el login es exitoso, podríamos navegar a una pantalla de perfil
        // Por ahora, simplemente volvemos a la HomePage
        // Usamos el servicio para guardar el token.
        await authService.saveTokens(response['accessToken'], response['refreshToken']);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Bienvenido!'),
            backgroundColor: Colors.green,
          ),
        );
        // Cerramos la pantalla de login con éxito.
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll("Exception: ", "")}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingresar')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Bienvenido de vuelta',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ingresá para gestionar tu comercio',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 40),

                // --- CAMPO DE USUARIO/EMAIL ---
                TextFormField(
                  controller: _identifierController,
                  decoration: const InputDecoration(
                    labelText: 'Email o Nombre de Usuario',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingresa tu email o usuario';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // --- CAMPO DE CONTRASEÑA ---
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingresa tu contraseña';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 40),

                /// --- BOTÓN DE LOGIN ---
                SizedBox(
                  // Quitamos el const aquí porque el contenido cambia
                  width: double.infinity,
                  child: ElevatedButton(
                    // 1. El onPressed depende de _isLoading. Si es true, se deshabilita (null).
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      // Estilo opcional para cuando está deshabilitado
                      disabledBackgroundColor: const Color(
                        0xFF8a2be2,
                      ).withOpacity(0.5),
                    ),
                    // 2. El hijo del botón también depende de _isLoading.
                    child: _isLoading
                        // Si está cargando, muestra el spinner.
                        ? const SizedBox(
                            height: 24.0,
                            width: 24.0,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3.0,
                            ),
                          )
                        // Si no, muestra el texto.
                        : const Text(
                            'Ingresar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // --- LINK A REGISTRO ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '¿No tenés una cuenta?',
                      style: TextStyle(color: Colors.white70),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navegamos a la página de registro, reemplazando la de login
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterPage(),
                          ),
                        );
                      },
                      child: const Text('Registrate acá'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
