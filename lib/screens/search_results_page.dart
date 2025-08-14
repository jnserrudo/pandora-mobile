import 'package:flutter/material.dart';
import 'package:pandora_app/screens/commerce_detail_page.dart';
import 'package:pandora_app/screens/event_detail_page.dart';
import 'package:pandora_app/services/api_service.dart';
import 'package:pandora_app/widgets/error_display.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class SearchResultsPage extends StatefulWidget {
  final String query;
  const SearchResultsPage({super.key, required this.query});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  late Future<List<dynamic>> _searchResultsFuture;

  @override
  void initState() {
    super.initState();
    _performSearch(); // Usamos un nombre de función más claro
  }

  // Función para poder reintentar la búsqueda
  void _performSearch() {
    setState(() {
      _searchResultsFuture = ApiService.search(widget.query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Resultados para "${widget.query}"'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _searchResultsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return ErrorDisplay(
              message: 'Hubo un problema con la búsqueda.',
              onRetry: _performSearch, // Conectamos el reintento
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No se encontraron resultados para tu búsqueda.'));
          } else {
            final allResults = snapshot.data!;
            
            return AnimationLimiter(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: allResults.length,
                itemBuilder: (context, index) {
                  final result = allResults[index];
                  
                  // Determinamos el tipo de resultado basándonos en el campo 'type' del backend
                  final bool isCommerce = result['type'] == 'commerce';

                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 400),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        // --- AQUÍ REINSERTAMOS EL LISTTILE COMPLETO ---
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: Colors.white.withOpacity(0.05),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            leading: Icon(
                              isCommerce ? Icons.store : Icons.event,
                              color: const Color(0xFFc738dd),
                              size: 30,
                            ),
                            title: Text(result['name'] ?? 'Sin nombre', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text(isCommerce ? 'Comercio' : 'Evento', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                            // --- ¡Y AQUÍ ESTÁ EL ONTAP! ---
                            onTap: () {
                              if (isCommerce) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => CommerceDetailPage(commerce: result)),
                                );
                              } else {
                                // Navegamos a la página de detalle del evento
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => EventDetailPage(event: result)),
                                );
                              }
                            },
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