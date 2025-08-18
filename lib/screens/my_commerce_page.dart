// Reemplaza el contenido de tu archivo: screens/my_commerce_page.dart

import 'package:flutter/material.dart';
import 'package:pandora_app/services/api_service.dart';
import 'package:pandora_app/widgets/error_display.dart';
import 'package:pandora_app/widgets/empty_state_display.dart';
import 'package:pandora_app/screens/my_commerce_detail_page.dart'; // <-- Nueva página de detalles
import 'package:pandora_app/screens/create_commerce_page.dart'; // <-- Página para crear comercio

class MyCommercesPage extends StatefulWidget {
  // <-- Renombramos para claridad
  const MyCommercesPage({super.key});

  @override
  State<MyCommercesPage> createState() => _MyCommercesPageState();
}

class _MyCommercesPageState extends State<MyCommercesPage> {
  // El Future ahora espera una LISTA de comercios
  late Future<List<dynamic>> _myCommercesFuture;

  @override
  void initState() {
    super.initState();
    _loadMyCommerces();
  }

  void _loadMyCommerces() {
    setState(() {
      _myCommercesFuture =
          ApiService.getMyCommerces(); // <-- Llama al nuevo método
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Comercios'), // <-- Título actualizado
      ),
      // El FAB ahora es para CREAR un nuevo comercio
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const CreateCommercePage()),
          );
          if (result == true) {
            _loadMyCommerces(); // Refresca la lista si se creó un comercio
          }
        },
        child: const Icon(Icons.add_business),
        tooltip: 'Registrar Nuevo Comercio',
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _myCommercesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorDisplay(
              message: 'No se pudieron cargar tus comercios.',
              onRetry: _loadMyCommerces,
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyStateDisplay(
              icon: Icons.storefront,
              title: 'Sin Comercios Registrados',
              message: 'Parece que aún no has registrado ningún negocio.',
              buttonText: 'Registrar mi primer comercio',
              onButtonPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateCommercePage(),
                  ),
                );
                if (result == true) _loadMyCommerces();
              },
            );
          }

          final commerces = snapshot.data!;

          // La UI principal es una lista de tarjetas de comercio
          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: commerces.length,
            itemBuilder: (context, index) {
              final commerce = commerces[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.store, size: 40),
                  title: Text(
                    commerce['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    commerce['category'].toString().replaceAll('_', ' '),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Al tocar, navegamos a la página de detalles de ESE comercio
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            MyCommerceDetailPage(commerceId: commerce['id']),
                      ),
                    ).then(
                      (_) => _loadMyCommerces(),
                    ); // Refresca la lista al volver por si algo cambió
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
