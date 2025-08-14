import 'package:flutter/material.dart';
import 'package:pandora_app/screens/home_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:provider/provider.dart';
import 'package:pandora_app/services/auth_services.dart';
import 'package:pandora_app/screens/splash_creen.dart';

// Convertimos main() en una función asíncrona para poder usar 'await'
Future<void> main() async {
  // 2. Carga las variables de entorno antes de iniciar la app
  await dotenv.load(fileName: ".env");

  runApp( ChangeNotifierProvider(
    create: (context) => AuthService(),
    child: const PandoraApp(),
  ));
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
      home: const SplashScreen(),
    );
  }
}
