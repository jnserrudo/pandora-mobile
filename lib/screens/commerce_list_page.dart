// --- 1. IMPORTACIONES NECESARIAS ---
import 'package:flutter/material.dart';
import 'package:pandora_app/services/api_service.dart';
import 'package:pandora_app/screens/commerce_detail_page.dart';
import 'package:pandora_app/widgets/error_display.dart'; // Importamos el widget de error
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; // Importamos el paquete de animaciones

import 'package:pandora_app/widgets/empty_state_display.dart';
import 'package:flutter/services.dart';

// --- 2. WIDGET STATEFUL ---
// La estructura del StatefulWidget se mantiene como la tenías.
class CommerceListPage extends StatefulWidget {
  final String category;
  const CommerceListPage({super.key, required this.category});

  @override
  State<CommerceListPage> createState() => _CommerceListPageState();
}

// --- 3. CLASE DE ESTADO ---
class _CommerceListPageState extends State<CommerceListPage> {
  late Future<List<dynamic>> _commercesFuture;

  // --- 4. MÉTODO initState() Y LÓGICA DE CARGA ---
  @override
  void initState() {
    super.initState();
    _loadCommerces(); // Llamamos a la función de carga
  }

  // Creamos una función separada para poder llamarla desde el botón de "Reintentar"
  void _loadCommerces() {
    setState(() {
      _commercesFuture = ApiService.getCommerces(category: widget.category);
    });
  }

  // --- FUNCIÓN HELPER PARA OBTENER EL NOMBRE DE PANTALLA ---
  String _getCategoryDisplayName(String categoryKey) {
    switch (categoryKey) {
      case 'VIDA_NOCTURNA':
        return 'Vida Nocturna';
      case 'GASTRONOMIA':
        return 'Gastronomía';
      case 'SALAS_Y_TEATRO':
        return 'Salas y Teatro';
      default:
        // Si por alguna razón llega una clave desconocida, la mostramos tal cual.
        return categoryKey;
    }
  }

  // --- 5. MÉTODO build() ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_getCategoryDisplayName(widget.category))),
      // --- 6. USO DE FutureBuilder ---
      body: FutureBuilder<List<dynamic>>(
        future: _commercesFuture,
        builder: (context, snapshot) {
          // Estado de carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Estado de error
          else if (snapshot.hasError) {
            // Usamos nuestro widget de error personalizado
            return ErrorDisplay(
              message: 'No pudimos cargar los comercios. Revisa tu conexión.',
              onRetry: _loadCommerces,
            );
          }
          // Estado sin datos
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyStateDisplay(
              icon: Icons.store,
              title: 'No se encontraron comercios en esta categoría.',
              message: 'Parece que no hay comercios en esta categoría.',
              buttonText: 'Intentar de nuevo',
              onButtonPressed: _loadCommerces,
            );
          }
          // Estado de éxito con datos
          else {
            final commerces = snapshot.data!;
            // --- 7. LISTA CON ANIMACIÓN ---
            // Envolvemos nuestro ListView.builder en un AnimationLimiter
            // para que las animaciones sepan los límites de la lista.
            return AnimationLimiter(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: commerces.length,
                itemBuilder: (context, index) {
                  // --- 1. PRIMERO DEFINIMOS EL COMERCIO ACTUAL ---
                  final commerce = commerces[index];

                  // --- 2. AHORA, CON 'commerce' DEFINIDO, EXTRAEMOS LA INFORMACIÓN ---

                  // Obtenemos la galería de imágenes y nos aseguramos de que sea una lista.
                  final gallery = commerce['galleryImages'];
                  final List<String> galleryImages = (gallery is List)
                      ? List<String>.from(gallery)
                      : [];

                  // Determinamos la URL de la imagen a mostrar de forma segura.
                  // Primero intentamos usar 'coverImage', luego la primera de la galería, y finalmente el placeholder.
                  final String imageUrlToShow =
                      commerce['coverImage'] ??
                      (galleryImages.isNotEmpty
                          ? galleryImages.first
                          : 'https://picsum.photos/800/200');

                  // --- FIN DE LA LÓGICA ---

                  // Cada item de la lista se envuelve en una configuración de animación.
                  return AnimationConfiguration.staggeredList(
                    position: index, // La posición del item en la lista
                    duration: const Duration(milliseconds: 400),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          color: Colors.white.withOpacity(0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CommerceDetailPage(commerce: commerce),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FadeInImage.assetNetwork(
                                  placeholder: 'assets/images/placeholder.png',
                                  image:
                                      imageUrlToShow, // Usamos la variable segura
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  imageErrorBuilder:
                                      (context, error, stackTrace) {
                                        return Container(
                                          height: 120,
                                          color: Colors.grey[800],
                                          child: const Icon(
                                            Icons.broken_image,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        commerce['name'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        commerce['description'],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }
}
