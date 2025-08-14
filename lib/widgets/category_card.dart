import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 1. Lo convertimos (de nuevo) a un StatefulWidget para manejar el estado _isPressed
class CategoryCard extends StatefulWidget {
  final String title;
  final IconData iconData;
  final VoidCallback? onTap; // Nuevo parámetro

  const CategoryCard({
    super.key,
    required this.title,
    required this.iconData,
    this.onTap, // Parámetro opcional
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  // 2. Añadimos la variable de estado para la animación
  bool _isPressed = false;

  // 3. Definimos las funciones que se ejecutarán en cada evento de toque
  void _onTapDown(TapDownDetails details) {
    HapticFeedback.mediumImpact(); // <-- AÑADIMOS LA VIBRACIÓN AQUÍ
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    widget.onTap?.call(); // Llamar al onTap cuando se levanta el dedo
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    // 4. Envolvemos todo en un GestureDetector para capturar los eventos de toque
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        // 5. La transformación (escala) y la sombra ahora dependen de la variable _isPressed
        transform: _isPressed
            ? (Matrix4.identity()..scale(0.95))
            : Matrix4.identity(),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8a2be2), Color(0xFF5a1a9a)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF8a2be2,
              ).withOpacity(_isPressed ? 0.6 : 0.4),
              blurRadius: _isPressed ? 8 : 12,
              offset: Offset(0, _isPressed ? 2 : 4),
            ),
          ],
        ),
        // La estructura interna con Column, Expanded y FittedBox se mantiene,
        // ya que es la que previene los errores de overflow.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.iconData, color: Colors.white, size: 36),
            const SizedBox(height: 4),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
