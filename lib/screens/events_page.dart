import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pandora_app/services/api_service.dart';
import 'package:pandora_app/widgets/error_display.dart';
import 'package:pandora_app/screens/event_detail_page.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:pandora_app/widgets/empty_state_display.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  late Future<List<dynamic>> _eventsFuture;
  List<dynamic> _allEvents = [];
  List<dynamic> _filteredEvents = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _searchController.addListener(_filterEvents);
  }

  void _loadEvents() {
    setState(() {
      _eventsFuture = ApiService.getEvents();
    });
  }

  void _filterEvents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredEvents = _allEvents;
      } else {
        _filteredEvents = _allEvents.where((event) {
          final eventName = event['name'].toString().toLowerCase();
          return eventName.contains(query);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda de Eventos'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar eventos...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _eventsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return ErrorDisplay(
                    message: 'Error al cargar los eventos',
                    onRetry: _loadEvents,
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return EmptyStateDisplay(
                    icon: Icons.event_note,
                    title: 'No hay eventos disponibles',
                    message: 'Vuelve más tarde para ver nuevos eventos.',
                    onButtonPressed: _loadEvents,
                    buttonText: 'Reintentar',
                  );
                } else {
                  if (_allEvents.isEmpty) {
                    _allEvents = snapshot.data!;
                    _filteredEvents = _allEvents;
                  }

                  if (_filteredEvents.isEmpty && _searchController.text.isNotEmpty) {
                    return const Center(child: Text('No se encontraron eventos para tu búsqueda.'));
                  }

                  return AnimationLimiter(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredEvents.length,
                      itemBuilder: (context, index) {
                        final event = _filteredEvents[index];
                        
                        // --- LÓGICA PARA FORMATEAR LA FECHA ---
                        final DateTime startDate = DateTime.parse(event['startDate']).toLocal();
                        final String day = DateFormat('d').format(startDate);
                        final String month = DateFormat('MMM', 'es_ES').format(startDate).toUpperCase();

                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => EventDetailPage(event: event)),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        // --- COLUMNA DE LA FECHA (IZQUIERDA) ---
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.purple, width: 2),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(day, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                              Text(month, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // --- COLUMNA DE LA INFO (DERECHA) ---
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(event['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                                              const SizedBox(height: 4),
                                              Text(event['description'], style: TextStyle(color: Colors.grey[400]), maxLines: 1, overflow: TextOverflow.ellipsis),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  const Icon(Icons.location_on, size: 16, color: Colors.purple),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      event['address'] ?? 'Lugar no especificado',
                                                      style: TextStyle(color: Colors.grey[300]),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
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
                          ),
                        );
                      },
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}