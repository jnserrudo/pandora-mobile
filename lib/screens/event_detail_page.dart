import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pandora_app/screens/commerce_detail_page.dart';
import 'package:pandora_app/services/api_service.dart'; // Importa tu ApiService
import 'package:pandora_app/services/auth_services.dart';
import 'package:provider/provider.dart';
import 'package:pandora_app/screens/edit_event_page.dart';

import 'package:url_launcher/url_launcher.dart';

// EventDetailPage ahora es un StatefulWidget
class EventDetailPage extends StatefulWidget {
  final Map<String, dynamic> event;

  const EventDetailPage({super.key, required this.event});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  // Estado para almacenar el comercio y el estado de carga
  late Map<String, dynamic> _currentEvent; // <-- Estado para el evento actual
  Map<String, dynamic>? _commerce;
  bool _isLoading = true;
  bool _isOwner = false; // <-- 2. VARIABLE PARA VERIFICAR PROPIEDAD

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
    _fetchCommerceDetails();
  }

  // Método para obtener los datos del comercio
  Future<void> _fetchCommerceDetails() async {
    try {
      // Usamos el commerceId del evento para llamar al API
      final commerceId = widget.event['commerceId'];
      if (commerceId != null) {
        final commerceData = await ApiService.getCommerceById(
          commerceId.toString(),
        );
        if (mounted) {
          setState(() {
            _commerce = commerceData;
            // 3. LÓGICA DE VERIFICACIÓN
            _checkOwnership();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error al obtener los datos del comercio: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _checkOwnership() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.userId;
    // Comprobamos que el usuario esté logueado y que el ID del dueño del comercio coincida
    if (currentUserId != null &&
        _commerce != null &&
        _commerce!['ownerId'] == currentUserId) {
      setState(() {
        _isOwner = true;
      });
    }
  }

  // 4. MÉTODO PARA NAVEGAR A LA PÁGINA DE EDICIÓN
  void _navigateToEditPage() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditEventPage(event: _currentEvent),
      ),
    );

    // Si EditEventPage devuelve `true`, significa que el evento se actualizó.
    // Volvemos a cargar los datos para refrescar la UI.
    if (result == true) {
      _refreshEventDetails();
    }
  }

  // Método para recargar los datos del evento desde la API
  Future<void> _refreshEventDetails() async {
    try {
      final updatedEvent = await ApiService.getEventById(
        _currentEvent['id'].toString(),
      );
      if (mounted) {
        setState(() {
          _currentEvent = updatedEvent; // Actualizamos el estado del evento
        });
      }
    } catch (e) {
      print("Error al refrescar el evento: $e");
      // Opcional: mostrar un SnackBar de error
    }
  }

  // Método helper para lanzar URLs
  Future<void> _launchURL(String urlString, BuildContext context) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir el enlace: $urlString')),
      );
    }
  }

  // Método para abrir el mapa
  Future<void> _openMapWithAddress(String address, BuildContext context) async {
    final encodedAddress = Uri.encodeComponent(address);
    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encodedAddress',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir Google Maps.')),
      );
    }
  }

  // --- NUEVO: MÉTODO PARA ABRIR MAPA CON COORDENADAS ---
  // Es más preciso que buscar por dirección
  Future<void> _openMap(double lat, double lng, String address) async {
    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    final Uri fallbackUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el mapa.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // --- LÓGICA DE DATOS MEJORADA ---
    // 1. Lógica de Imágenes (AQUÍ ESTÁ EL CAMBIO)
    String? coverImageUrl = _currentEvent['coverImage'] as String?;
    final List<String> galleryImages = List<String>.from(
      _currentEvent['galleryImages'] ?? [],
    );

    // Si no hay coverImage explícita, PERO SÍ hay imágenes en la galería,
    // usamos la PRIMERA imagen de la galería como imagen de portada.
    if ((coverImageUrl == null || coverImageUrl.isEmpty) &&
        galleryImages.isNotEmpty) {
      coverImageUrl = galleryImages.first;
    }

    // Si después de todo lo anterior aún no hay imagen de portada, usamos el placeholder.
    final String finalCoverImageUrl =
        coverImageUrl ?? 'https://picsum.photos/800/600';

    // --- NUEVO BLOQUE DE LÓGICA DE FECHAS ---
    String formattedStartDate = 'Fecha no disponible';
    String formattedStartTime = '';
    String formattedEndDate = '';
    String formattedEndTime = '';

    final DateFormat dateFormatter = DateFormat(
      'EEEE d \'de\' MMMM, y',
      'es_ES',
    );
    final DateFormat timeFormatter = DateFormat('HH:mm \'hs\'');

    try {
      final startDate = DateTime.parse(_currentEvent['startDate']).toLocal();
      final endDate = DateTime.parse(_currentEvent['endDate']).toLocal();

      formattedStartDate = dateFormatter.format(startDate);
      formattedStartTime = timeFormatter.format(startDate);

      // Solo mostramos la fecha de fin si es un día diferente al de inicio
      if (startDate.year != endDate.year ||
          startDate.month != endDate.month ||
          startDate.day != endDate.day) {
        formattedEndDate = dateFormatter.format(endDate);
      }
      formattedEndTime = timeFormatter.format(endDate);
    } catch (e) {
      print('Error al formatear fechas del evento: $e');
    }
    // Lógica de dirección mejorada usando _currentEvent
    final eventAddress = _currentEvent['address'] as String?;
    final commerceAddress = _commerce?['address'] as String?;

    String locationToShow;
    String locationTitle;
    bool isCommerceLocation;

    // Ahora la condición es más robusta: verifica si la dirección no es nula Y no está vacía
    if (eventAddress != null && eventAddress.isNotEmpty) {
      locationToShow = eventAddress;
      locationTitle = 'Lugar del Evento'; // Título más claro
      isCommerceLocation = false;
    } else {
      locationToShow = commerceAddress ?? 'Lugar no especificado';
      locationTitle = 'Lugar del Comercio';
      isCommerceLocation = true;
    }
    // --- FIN DEL BLOQUE CORREGIDO ---

    return Scaffold(
      floatingActionButton: _isOwner
          ? FloatingActionButton(
              onPressed: _navigateToEditPage,
              tooltip: 'Editar Evento',
              child: const Icon(Icons.edit),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _currentEvent['name'],
                style: const TextStyle(shadows: [Shadow(blurRadius: 10)]),
              ),
              background: FadeInImage.assetNetwork(
                placeholder: 'assets/images/placeholder.png',
                image: finalCoverImageUrl,
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
                    // --- NUEVOS WIDGETS DE FECHA Y HORA ---
                    _buildInfoTile(
                      icon: Icons.calendar_today_outlined,
                      title: 'Comienza',
                      subtitle:
                          '$formattedStartDate\na las $formattedStartTime',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoTile(
                      icon: Icons.calendar_today,
                      title: 'Finaliza',
                      subtitle: formattedEndDate.isNotEmpty
                          ? '$formattedEndDate\na las $formattedEndTime'
                          : 'a las $formattedEndTime',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoTile(
                      icon: Icons.location_on,
                      title: locationTitle, // <-- Usa la variable corregida
                      subtitle: locationToShow, // <-- Usa la variable corregida
                      onTap: () {
                        if (isCommerceLocation && _commerce != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CommerceDetailPage(commerce: _commerce!),
                            ),
                          );
                        } else if (_currentEvent['latitude'] != null) {
                          // Usa las coordenadas si están disponibles (más preciso)
                          _openMap(
                            _currentEvent['latitude'],
                            _currentEvent['longitude'],
                            locationToShow,
                          );
                        }
                      },
                    ),
                    const Divider(height: 40, color: Colors.white24),
                    const Text(
                      'Sobre el Evento',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _currentEvent['description'],
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.white70,
                      ),
                    ),

                    // --- SECCIÓN DE GALERÍA (NUEVA) ---
                    if (galleryImages.isNotEmpty) ...[
                      const Divider(height: 40, color: Colors.white24),
                      const Text(
                        'Galería',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 120, // Altura fija para el scroll horizontal
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: galleryImages.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 10.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12.0),
                                child: Image.network(
                                  galleryImages[index],
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    // --- FIN SECCIÓN DE GALERÍA ---
                    const SizedBox(height: 30),
                    if (_currentEvent['ticketUrl'] != null &&
                        _currentEvent['ticketUrl'].isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _launchURL(_currentEvent['ticketUrl'], context);
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
            // Envolvemos la columna en un Expanded para que ocupe el espacio
            // disponible y permita que el texto se divida en varias líneas.
            Expanded(
              child: Column(
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
            ),
            // --------------------
            // La flecha necesita un pequeño padding para que no quede pegada
            if (onTap != null) const Spacer(),
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
