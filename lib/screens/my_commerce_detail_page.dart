// Crea un nuevo archivo: screens/my_commerce_detail_page.dart

import 'package:flutter/material.dart';
import 'package:pandora_app/services/api_service.dart';
// ... (copia todos los imports de tu MyCommercePage actual)
import 'package:pandora_app/screens/create_event_page.dart';
import 'package:pandora_app/screens/edit_commerce_page.dart';
import 'package:pandora_app/screens/event_detail_page.dart';
import 'package:pandora_app/widgets/error_display.dart';
import 'package:pandora_app/widgets/empty_state_display.dart';


class MyCommerceDetailPage extends StatefulWidget {
  final int commerceId;

  const MyCommerceDetailPage({super.key, required this.commerceId});

  @override
  State<MyCommerceDetailPage> createState() => _MyCommerceDetailPageState();
}

class _MyCommerceDetailPageState extends State<MyCommerceDetailPage> {
  // Ahora el Future obtiene UN comercio por su ID
  late Future<Map<String, dynamic>> _commerceDetailFuture;

  final Map<String, String> _eventStatusTranslations = {
    'SCHEDULED': 'PROGRAMADO', 'CANCELLED': 'CANCELADO', 'FINISHED': 'FINALIZADO',
  };

  @override
  void initState() {
    super.initState();
    _loadCommerceDetails();
  }

  void _loadCommerceDetails() {
    setState(() {
      _commerceDetailFuture = ApiService.getCommerceById(widget.commerceId.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    // La estructura de esta página es idéntica a tu antigua "MyCommercePage"
    return FutureBuilder<Map<String, dynamic>>(
      future: _commerceDetailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: ErrorDisplay(message: 'Error al cargar el comercio', onRetry: _loadCommerceDetails),
          );
        }

        final commerce = snapshot.data!;
        final events = commerce['events'] as List;

        return Scaffold(
          appBar: AppBar(
            title: Text(commerce['name']),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (context) => EditCommercePage(commerce: commerce)),
                  );
                  if (result == true) _loadCommerceDetails();
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (context) => CreateEventPage(commerceId: commerce['id'])),
              );
              if (result == true) _loadCommerceDetails();
            },
            child: const Icon(Icons.add),
            tooltip: 'Crear Evento',
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Aquí va toda la UI de tu antigua MyCommercePage para mostrar
              // la descripción, la categoría y la lista de eventos.
              Text(commerce['description'], style: const TextStyle(height: 1.5)),
              const Divider(height: 40),
              const Text('Eventos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (events.isEmpty)
                EmptyStateDisplay(
                  icon: Icons.event_note,
                  title: 'Sin Eventos',
                  message: 'Aún no has creado eventos para este comercio.',
                  buttonText: 'Crear primer evento',
                  onButtonPressed: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (context) => CreateEventPage(commerceId: commerce['id'])),
                    );
                    if (result == true) _loadCommerceDetails();
                  },
                )
              else
                ...events.map(
                  (event) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(event['name']),
                      subtitle: Text('Estado: ${_eventStatusTranslations[event['status']] ?? event['status']}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EventDetailPage(event: event)),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}