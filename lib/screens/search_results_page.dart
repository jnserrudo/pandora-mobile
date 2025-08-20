import 'package:flutter/material.dart';
import 'package:pandora_app/screens/commerce_detail_page.dart';
import 'package:pandora_app/screens/event_detail_page.dart';
import 'package:pandora_app/services/api_service.dart';
import 'package:pandora_app/widgets/error_display.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:pandora_app/screens/article_detail_page.dart'; // <-- 1. IMPORTAR

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

  // --- 2. FUNCIÓN HELPER PARA LA UI ---
  // Creamos un helper para no repetir código en el itemBuilder
  Widget _buildResultTile(Map<String, dynamic> result) {
    final String type = result['type'];

    // Valores por defecto
    IconData icon = Icons.help_outline;
    String title = result['name'] ?? result['title'] ?? 'Sin título';
    String subtitle = type.replaceFirst(
      type[0],
      type[0].toUpperCase(),
    ); // "commerce" -> "Commerce"
    VoidCallback? onTap;

    if (type == 'commerce') {
      icon = Icons.store;
      subtitle = 'Comercio';
      onTap = () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommerceDetailPage(commerce: result),
        ),
      );
    } else if (type == 'event') {
      icon = Icons.event;
      subtitle = 'Evento';
      onTap = () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EventDetailPage(event: result)),
      );
    } else if (type == 'article') {
      icon = Icons.article;
      subtitle = 'Noticia / Magazine';
      onTap = () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ArticleDetailPage(articleSlug: result['slug']),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFc738dd), size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Resultados para "${widget.query}"')),
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
            return const Center(
              child: Text('No se encontraron resultados para tu búsqueda.'),
            );
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
                        // --- 3. USAMOS NUESTRO HELPER ---
                        // La UI se genera de forma limpia y dinámica
                        child: _buildResultTile(result),
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
