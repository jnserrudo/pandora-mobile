// --- 1. IMPORTACIONES NECESARIAS ---
import 'package:flutter/material.dart';
import 'package:pandora_app/services/api_service.dart';
import 'package:pandora_app/services/auth_services.dart';

import 'package:pandora_app/widgets/error_display.dart';
import 'package:provider/provider.dart';
import 'package:pandora_app/screens/create_event_page.dart';
import 'package:pandora_app/screens/edit_commerce_page.dart';

import 'package:pandora_app/screens/commerce_detail_page.dart';
import 'package:pandora_app/screens/event_detail_page.dart';

import 'package:pandora_app/widgets/empty_state_display.dart';

// --- 2. WIDGET STATEFUL ---
// La estructura del StatefulWidget se mantiene como la tenías.
class MyCommercePage extends StatefulWidget {
  const MyCommercePage({super.key});

  @override
  State<MyCommercePage> createState() => _MyCommercePageState();
}

// --- 3. CLASE DE ESTADO ---
class _MyCommercePageState extends State<MyCommercePage> {
  late Future<Map<String, dynamic>> _myCommerceFuture;

  // --- 4. MÉTODO initState() Y LÓGICA DE CARGA ---
  @override
  void initState() {
    super.initState();
    _loadMyCommerce();
  }

  // Función de carga separada para poder reintentar y refrescar.
  void _loadMyCommerce() {
    setState(() {
        _myCommerceFuture = ApiService.getMyCommerce();
      });
  }

  // --- 5. MÉTODO build() ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Comercio'),
        actions: [
          // --- CONECTAMOS EL BOTÓN DE EDITAR ---
          FutureBuilder<Map<String, dynamic>>(
            future: _myCommerceFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditCommercePage(commerce: snapshot.data!),
                      ),
                    );
                    // Si la edición fue exitosa, recargamos los datos
                    if (result == true && mounted) {
                      _loadMyCommerce();
                    }
                  },
                );
              }
              return const SizedBox.shrink(); // No muestra nada mientras carga
            },
          ),
        ],
      ),
      // --- 6. BOTÓN FLOTANTE ---
      // Para añadir nuevos eventos al comercio.
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            // Esperamos a que el Future se resuelva para obtener los datos actuales.
            // Usamos `snapshot.data` si está disponible, o esperamos al `Future` si no.
            final commerceData = await _myCommerceFuture;
            final commerceId = commerceData['id'];

            // Navegamos a la página de creación de evento y esperamos un resultado.
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => CreateEventPage(commerceId: commerceId),
              ),
            );

            // Si la página de creación devuelve `true`, significa que se creó un evento
            // y debemos refrescar la lista.
            if (result == true && mounted) {
              _loadMyCommerce();
            }
          } catch (e) {
            // Manejar el caso en que el future aún no se ha resuelto
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Espera a que cargue la información del comercio.',
                ),
              ),
            );
          }
        },
        child: const Icon(Icons.add),
        backgroundColor: const Color(0xFFff00c8),
      ),
      // --- 7. USO DE FutureBuilder ---
      body: FutureBuilder<Map<String, dynamic>>(
        future: _myCommerceFuture,
        builder: (context, snapshot) {
          // Estados de carga, error y sin datos.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return ErrorDisplay(
              message: 'No se pudo cargar la información de tu comercio.',
              onRetry: _loadMyCommerce,
            );
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No se encontraron datos.'));
          } else {
            final commerce = snapshot.data!;
            // Extraemos la lista de eventos del objeto 'commerce'.
            final events = commerce['events'] as List;

            // Usamos un ListView para mostrar toda la información.
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                80,
              ), // Padding extra abajo por el FAB
              children: [
                // --- SECCIÓN DE INFO DEL COMERCIO ---
                Text(
                  commerce['name'],
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  commerce['category'],
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFFc738dd),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  commerce['description'],
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    height: 1.5,
                  ),
                ),
                const Divider(height: 40, color: Colors.white24),

                // --- SECCIÓN DE EVENTOS DEL COMERCIO ---
                const Text(
                  'Mis Eventos',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                // Si la lista de eventos está vacía, mostramos un mensaje.
                if (events.isEmpty)
                  // Reemplazamos el Padding y Text con nuestro widget
                  EmptyStateDisplay(
                    icon: Icons.add_circle_outline,
                    title: 'Sin Eventos Creados',
                    message:
                        'Aún no has añadido ningún evento para tu negocio.',
                    buttonText: 'Crear mi primer evento',
                    onButtonPressed: () {
                      // La misma lógica que el FloatingActionButton
                      final commerceId = commerce['id'];
                      Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CreateEventPage(commerceId: commerceId),
                        ),
                      ).then((result) {
                        if (result == true && mounted) {
                          _loadMyCommerce();
                        }
                      });
                    },
                  )
                // Si hay eventos, los mostramos usando un Column.
                // Usamos `...` (spread operator) para insertar la lista de widgets.
                else
                  ...events.map(
                    (event) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      color: Colors.white.withOpacity(0.05),
                      child: ListTile(
                        title: Text(event['name']),
                        subtitle: Text('Estado: ${event['status']}'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        // --- COMPLETAMOS EL TODO ---
                        onTap: () {
                          // Aquí podrías navegar a una pantalla de EDICIÓN de evento,
                          // o simplemente al detalle público. Usemos el detalle por ahora.
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EventDetailPage(event: event),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            );
          }
        },
      ),
    );
  }
}
