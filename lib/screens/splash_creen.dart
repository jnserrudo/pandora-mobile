import 'package:flutter/material.dart';
import 'package:pandora_app/screens/home_page.dart';
import 'package:pandora_app/services/api_service.dart';
import 'package:pandora_app/services/auth_services.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Usamos el Provider para acceder al AuthService
    final authService = Provider.of<AuthService>(context, listen: false);
    
     // --- LÍNEA CLAVE DE INICIALIZACIÓN ---
    // --- LÍNEA CLAVE DE INICIALIZACIÓN (CORREGIDA) ---
    ApiService.initialize(authService); // <-- SIN 'await'
    // Le damos un pequeño delay para que la pantalla de carga sea visible
    await Future.delayed(const Duration(seconds: 1));
    
    // Intentamos hacer auto-login
    await authService.tryAutoLogin();
    
    // Después de intentar el login, navegamos a la HomePage.
    // Usamos `pushReplacement` para que el usuario no pueda volver a esta pantalla.
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Una pantalla de carga simple con el logo o un indicador
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
        // Asumiendo que tu logo está en assets/images/logo.png
        Image.asset('assets/images/logo_pandora.png', width: 150),
        const SizedBox(height: 30),
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ],
        ),
      ),
    );
  }
}