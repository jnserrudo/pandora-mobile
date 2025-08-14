import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Asegúrate de tener el paquete `intl`
import 'package:pandora_app/screens/commerce_detail_page.dart';

import 'package:url_launcher/url_launcher.dart';

class EventDetailPage extends StatelessWidget {
  // Recibirá el mapa completo de datos del evento.
  final Map<String, dynamic> event;

  const EventDetailPage({super.key, required this.event});

  // Añade la función helper para lanzar URLs
  Future<void> _launchURL(String urlString, BuildContext context) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir el enlace: $urlString')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Formateo de fechas para una mejor visualización
    String formattedDate = 'Fecha no disponible';
    try {
      final startDate = DateTime.parse(event['startDate']);
      final endDate = DateTime.parse(event['endDate']);
      formattedDate = DateFormat(
        'EEEE d \'de\' MMMM, y',
        'es_ES',
      ).format(startDate);
      // Podríamos añadir lógica para mostrar la hora también
    } catch (e) {
      print('Error al formatear fecha del evento: $e');
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                event['name'],
                style: const TextStyle(shadows: [Shadow(blurRadius: 10)]),
              ),
              background: FadeInImage.assetNetwork(
                placeholder: 'assets/images/placeholder.png',
                image: event['coverImage'] ?? 'https://picsum.photos/800/600',
                fit: BoxFit.cover,
                width: double.infinity,
                color: Colors.black.withOpacity(0.4),
                colorBlendMode: BlendMode.darken,
                imageErrorBuilder: (c, e, s) => Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SECCIÓN DE FECHA Y LUGAR ---
                    _buildInfoTile(
                      icon: Icons.calendar_today,
                      title: 'Fecha',
                      subtitle: formattedDate,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoTile(
                      icon: Icons.location_on,
                      title: 'Lugar',
                      subtitle:
                          event['commerce']?['name'] ?? 'Lugar no especificado',
                      // Hacemos que esta fila sea navegable al perfil del comercio
                      onTap: () {
                        if (event['commerce'] != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CommerceDetailPage(
                                commerce: event['commerce'],
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    const Divider(height: 40, color: Colors.white24),

                    // --- SECCIÓN DE DESCRIPCIÓN ---
                    const Text(
                      'Sobre el Evento',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      event['description'],
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- BOTÓN DE COMPRA DE ENTRADAS (COMPLETADO) ---
                    if (event['ticketUrl'] != null &&
                        event['ticketUrl'].isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _launchURL(event['ticketUrl'], context);
                          },
                          icon: const Icon(Icons.local_activity),
                          label: const Text('Comprar Entradas'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // Widget helper para las filas de información
  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFc738dd), size: 24),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (onTap != null) const Spacer(), // Empuja el icono al final
            if (onTap != null)
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.white70,
              ),
          ],
        ),
      ),
    );
  }
}
