import 'package:flutter/material.dart';
import 'package:pandora_app/services/api_service.dart';
import 'package:pandora_app/widgets/error_display.dart';

import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'package:pandora_app/screens/article_detail_page.dart';

// 1. Convertimos a StatefulWidget
class MagazinePage extends StatefulWidget {
  const MagazinePage({super.key});

  @override
  State<MagazinePage> createState() => _MagazinePageState();
}

class _MagazinePageState extends State<MagazinePage> {
  // El Future está correctamente tipado como Future<List<dynamic>>
  late Future<List<dynamic>> _articlesFuture;

  @override
  void initState() {
    super.initState();
    _articlesFuture = ApiService.getArticles();
  }

  // Creamos una función para poder llamarla desde el botón de reintento
  void _loadArticles() {
    setState(() {
      _articlesFuture = ApiService.getArticles();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Datos de ejemplo para los artículos
    final List<Map<String, String>> articles = [
      {
        'title': 'Los 5 Bares Secretos de Salta',
        'category': 'Vida Nocturna',
        'imageUrl': 'https://picsum.photos/seed/barsecreto/800/400',
      },
      {
        'title': 'Entrevista con el Chef de Parrilla Don José',
        'category': 'Gastronomía',
        'imageUrl': 'https://picsum.photos/seed/chef/800/400',
      },
      {
        'title': 'La Historia del Teatro Provincial',
        'category': 'Salas y Teatro',
        'imageUrl': 'https://picsum.photos/seed/historia/800/400',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Pandora Magazine')),

      body: FutureBuilder<List<dynamic>>(
        future: _articlesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return ErrorDisplay(
              message: 'Error al cargar los artículos: ${snapshot.error}',
              onRetry: _loadArticles,
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay artículos disponibles.'));
          } else {
            final articles = snapshot.data!;
            // --- 1. ENVOLVEMOS LA LISTA CON ANIMATIONLIMITER ---
            return AnimationLimiter(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: articles.length,
                itemBuilder: (context, index) {
                  final article = articles[index];
                  // --- 2. ENVOLVEMOS CADA ITEM CON ANIMATIONCONFIGURATION ---
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 400),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        // --- 3. TU CARD DE ARTÍCULO VA AQUÍ DENTRO ---
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 20),
                          color: Colors.white.withOpacity(0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              // Obtenemos el slug del artículo actual
                              final String articleSlug = article['slug'];
                              // Navegamos a la pantalla de detalle
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ArticleDetailPage(
                                    articleSlug: articleSlug,
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FadeInImage.assetNetwork(
                                  placeholder: 'assets/images/placeholder.png',
                                  image:
                                      article['coverImage'] ??
                                      'https://picsum.photos/800/400',
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  imageErrorBuilder: (c, e, s) => Container(
                                    height: 150,
                                    color: Colors.grey[800],
                                    child: const Icon(Icons.broken_image),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        article['category']?['name'] ??
                                            'Artículo',
                                        style: const TextStyle(
                                          color: Color(0xFFff00c8),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        article['title']!,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          height: 1.2,
                                        ),
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
