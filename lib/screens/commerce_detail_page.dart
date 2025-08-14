import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart'; // Importamos el paquete
import 'package:url_launcher/url_launcher.dart';

class CommerceDetailPage extends StatelessWidget {
  final Map<String, dynamic> commerce;

  const CommerceDetailPage({super.key, required this.commerce});

  // --- 2. CREAMOS UNA FUNCIÓN HELPER PARA LANZAR URLS ---
  // Esta función maneja la lógica de abrir una URL de forma segura.
  Future<void> _launchURL(String urlString, BuildContext context) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Si no se puede abrir, mostramos un error al usuario.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir el enlace: $urlString')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- MANEJO DE DATOS NULOS ---
    // Extraemos los datos a variables locales con valores por defecto.
    // Esto hace el código más limpio y seguro.
    final String name = commerce['name'] ?? 'Nombre no disponible';
    final String description =
        commerce['description'] ?? 'Descripción no disponible.';
    final String address = commerce['address'] ?? 'Dirección no disponible';
    final String? phone = commerce['phone']; // Puede ser nulo
    final String? hours =
        commerce['openingHours']?.toString() ??
        'Horario no disponible'; // Asumimos que `openingHours` es el campo correcto
    final String? website = commerce['website'];
    final String? instagram = commerce['instagram'];
    final String? facebook = commerce['facebook'];

    // Para la galería, usamos el campo 'galleryImages' que es una lista.
    // Si está vacío o no existe, proveemos una imagen por defecto.
    final List<dynamic> galleryImagesDynamic = commerce['galleryImages'] ?? [];
    final List<String> galleryImages = galleryImagesDynamic
        .map((e) => e.toString())
        .toList();
    if (galleryImages.isEmpty) {
      galleryImages.add(
        "https://via.placeholder.com/800x600?text=Sin+Imágenes",
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. GALERÍA DE FOTOS ---
            Stack(
              children: [
                // Usamos `if` para asegurarnos de que el carrusel tenga imágenes
                if (galleryImages.isNotEmpty)
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 300,
                      viewportFraction: 1.0,
                      autoPlay: true,
                    ),
                    items: galleryImages.map((url) {
                      return FadeInImage.assetNetwork(
                        placeholder: 'assets/images/placeholder.png',
                        image: url,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        imageErrorBuilder: (context, error, stackTrace) =>
                            Container(
                              color: Colors.grey[800],
                              child: const Icon(Icons.broken_image),
                            ),
                      );
                    }).toList(),
                  )
                else
                  // Si no hay imágenes, mostramos un placeholder estático
                  Container(
                    height: 300,
                    color: Colors.grey[800],
                    child: const Center(
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.grey,
                        size: 50,
                      ),
                    ),
                  ),

                // Botón de atrás (sin cambios)
                Positioned(
                  top: 40,
                  left: 10,
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.5),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ],
            ),

            // --- 2. INFORMACIÓN ---
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Descripción',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFc738dd),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.white70,
                    ),
                  ),
                  const Divider(height: 40, color: Colors.white24),

                  const Text(
                    'Información y Contacto',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFc738dd),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Fila de Dirección (siempre debería existir)
                  _buildInfoRow(
                    Icons.location_on,
                    address,
                    onTap: () {
                      final query = Uri.encodeComponent(address);
                      _launchURL(
                        'https://www.google.com/maps/search/?api=1&query=$query',
                        context,
                      );
                    },
                  ),

                  // Mostramos las filas SOLO SI el dato no es nulo
                  if (phone != null && phone.isNotEmpty)
                    _buildInfoRow(
                      Icons.phone,
                      phone,
                      onTap: () => _launchURL('tel:$phone', context),
                    ),

                  if (hours != null && hours.isNotEmpty)
                    _buildInfoRow(Icons.access_time, hours),

                  const SizedBox(height: 20),

                  // Fila de Redes Sociales
                  if (website != null || instagram != null || facebook != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (website != null && website.isNotEmpty)
                          _buildSocialIcon(
                            Icons.public,
                            onTap: () => _launchURL(website, context),
                          ),
                        if (instagram != null && instagram.isNotEmpty)
                          _buildSocialIcon(
                            Icons.photo_camera,
                            onTap: () => _launchURL(instagram, context),
                          ),
                        if (facebook != null && facebook.isNotEmpty)
                          _buildSocialIcon(
                            Icons.facebook,
                            onTap: () => _launchURL(facebook, context),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget helper para las filas de información
  Widget _buildInfoRow(IconData icon, String text, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 16),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
            if (onTap != null)
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white70,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  // Widget helper para los iconos de redes sociales
  Widget _buildSocialIcon(IconData icon, {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFFc738dd), size: 28),
        onPressed: onTap,
      ),
    );
  }
}
