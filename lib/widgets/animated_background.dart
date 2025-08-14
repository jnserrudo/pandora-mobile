import 'dart:async';
import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> {
  // Definimos los colores de la aurora
  final List<Color> colors = const [Color(0xFF8a2be2), Color(0xFFc738dd), Color(0xFFff00c8)];
  // Posiciones iniciales de los gradientes
  List<Alignment> alignments = [Alignment.topLeft, Alignment.bottomRight, Alignment.topRight];
  int
  _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Un temporizador que cambia la alineación cada 5 segundos para crear el movimiento
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() => _currentIndex = (_currentIndex + 1) % alignments.length);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // El color de fondo base
        Container(color: const Color(0xFF0d0218)),
        // El efecto de aurora animado
        AnimatedContainer(
          duration: const Duration(seconds: 4),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: alignments[_currentIndex],
              radius: 1.5,
              colors: [colors[0].withOpacity(0.5), colors[0].withOpacity(0)],
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(seconds: 4),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: alignments[(_currentIndex + 1) % alignments.length],
              radius: 1.5,
              colors: [colors[1].withOpacity(0.5), colors[1].withOpacity(0)],
            ),
          ),
        ),
      ],
    );
  }
}