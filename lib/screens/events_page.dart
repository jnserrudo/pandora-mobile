import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Asegúrate de haber ejecutado: flutter pub add intl
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
  // El Future está correctamente tipado como Future<List<dynamic>>
  late Future<List<dynamic>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = ApiService.getEvents();
  }
// Creamos una función para poder llamarla desde el botón de reintento
  void _loadEvents() {
    setState(() {
      _eventsFuture = ApiService.getEvents();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda de Eventos'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return ErrorDisplay(
              message: 'Error al cargar los eventos: ${snapshot.error}',
              onRetry: _loadEvents,
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyStateDisplay(
              icon: Icons.event_available,
              title: 'No hay eventos programados por el momento.',
              message: 'Parece que no hay eventos programados en este momento.',
              buttonText: 'Intentar de nuevo',
              onButtonPressed: _loadEvents,
            );
          }  else {
            final events = snapshot.data!;
            // --- 1. ENVOLVEMOS CON ANIMATIONLIMITER ---
            return AnimationLimiter(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  // --- 2. ENVOLVEMOS CON ANIMATIONCONFIGURATION ---
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 400),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        // --- 3. TU CARD DE EVENTO VA AQUÍ ---
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          color: Colors.white.withOpacity(0.05),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: InkWell( // <-- Usamos InkWell para poder navegar
                            onTap: () { /* TODO: Navegar al detalle del evento */ },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                // ... (El contenido de tu Row se mantiene igual)
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
    );
  }
}