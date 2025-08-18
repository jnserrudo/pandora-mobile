import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pandora_app/screens/home_page.dart';
import 'package:pandora_app/screens/login_page.dart';
import 'package:pandora_app/services/api_service.dart';

import 'package:provider/provider.dart';
import 'package:pandora_app/services/auth_services.dart';
import 'package:pandora_app/screens/splash_creen.dart';

// Convertimos main() en una función asíncrona para poder usar 'await'
Future<void> main() async {
  // Aseguramos que los widgets estén inicializados antes de dotenv
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Creamos la instancia de AuthService
  final authService = AuthService();

  // Inyectamos la dependencia de authService en ApiService
  ApiService.initialize(authService);

  // Opcional: Iniciar la precarga de la sesión aquí
  await authService.tryAutoLogin();

  await initializeDateFormatting('es_ES', null); // <-- AÑADE ESTA LÍNEA

  runApp(
    ChangeNotifierProvider(
      create: (context) => authService, // Usamos la instancia que creamos
      child: const PandoraApp(),
    ),
  );
}

class PandoraApp extends StatelessWidget {
  const PandoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pandora Salta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF8a2be2),
        scaffoldBackgroundColor: const Color(0xFF0d0218),
        fontFamily: 'Poppins',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(
            color: Colors.white,
          ), // Flecha de "atrás" blanca
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFf0e8ff)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          labelStyle: const TextStyle(color: Colors.white70),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8a2be2),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: Consumer<AuthService>(
        builder: (context, authService, _) {
          // La SplashScreen podría seguir siendo un intermedio si lo necesitas
          // para un loader inicial, pero puedes simplificarlo.

          // La lógica ideal:
          // Si el estado de autenticación no se ha verificado, muestra la SplashScreen.
          if (!authService.isAuthenticated && authService.token == null) {
            // Este caso es para la primera carga, si no hay token guardado.
            // Para la primera vez que entras, puedes mostrar algo mientras se verifica.
            // Aquí puedes decidir si quieres que se muestre la HomePage o un loader.
            return const HomePage(); // O la pantalla de inicio para invitados.
          } else {
            // La lógica para redirección si la sesión expira
            if (authService.isAuthenticated) {
              return const HomePage();
            } else {
              // Esto es solo si el token expiró y se hizo logout.
              return const LoginPage();
            }
          }
        },
      ),
    );
  }
}
