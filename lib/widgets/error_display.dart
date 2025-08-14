import 'package:flutter/material.dart';

class ErrorDisplay extends StatelessWidget {
  final String message;
  final VoidCallback onRetry; // Una función para reintentar la carga

  const ErrorDisplay({
    super.key,
    this.message = 'Ocurrió un error inesperado.', // Mensaje por defecto
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off, // Icono que sugiere un problema de conexión
              color: const Color(0xFFc738dd).withOpacity(0.7),
              size: 80,
            ),
            const SizedBox(height: 20),
            Text(
              '¡Ups! Algo salió mal',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message, // Aquí mostramos un mensaje más específico pero amigable
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: onRetry, // El botón llama a la función de reintento
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF8a2be2), // Color de texto
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}