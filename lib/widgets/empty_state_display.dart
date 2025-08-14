import 'package:flutter/material.dart';

class EmptyStateDisplay extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonText; // Texto del botón opcional
  final VoidCallback? onButtonPressed; // Acción del botón opcional

  const EmptyStateDisplay({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: const Color(0xFF8a2be2).withOpacity(0.7),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            // Si proporcionamos texto para un botón, lo mostramos
            if (buttonText != null && onButtonPressed != null)
              Padding(
                padding: const EdgeInsets.only(top: 30.0),
                child: ElevatedButton(
                  onPressed: onButtonPressed,
                  child: Text(buttonText!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}