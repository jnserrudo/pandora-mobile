import 'package:flutter/material.dart';

import 'package:pandora_app/services/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    // 1. Convertimos a async
    // Validamos que el formulario esté correcto
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true); // Mostramos el indicador de carga

      try {
        // 2. Llamamos al ApiService
        final response = await ApiService.register(
          name: _nameController.text,
          username: _usernameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );

        // 3. Si todo sale bien, mostramos un mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? '¡Registro exitoso!'),
            backgroundColor: Colors.green,
          ),
        );

        // Opcional: Navegamos a la página de login después de un registro exitoso
        Navigator.of(context).pop(); // Vuelve a la pantalla anterior (HomePage)
      } catch (e) {
        // 4. Si la API lanza un error, lo mostramos en un SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll("Exception: ", "")}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        // 5. Ocultamos el indicador de carga, tanto si hubo éxito como si hubo error
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Cuenta')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text(
                  'Creá tu cuenta en Pandora',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'El nombre es requerido' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de Usuario',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'El nombre de usuario es requerido' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v!.isEmpty ? 'El email es requerido' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (v) => v!.length < 6
                      ? 'La contraseña debe tener al menos 6 caracteres'
                      : null,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  // Quitamos el const aquí
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor: const Color(
                        0xFF8a2be2,
                      ).withOpacity(0.5),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24.0,
                            width: 24.0,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3.0,
                            ),
                          )
                        : const Text(
                            'Crear Cuenta',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
