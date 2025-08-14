import 'package:flutter/material.dart';
import 'package:pandora_app/services/api_service.dart';
import 'package:pandora_app/widgets/error_display.dart';

// Es un StatefulWidget porque necesita cargar los datos del artículo
class ArticleDetailPage extends StatefulWidget {
  final String articleSlug;

  const ArticleDetailPage({super.key, required this.articleSlug});

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  late Future<Map<String, dynamic>> _articleFuture;

  @override
  void initState() {
    super.initState();
    _loadArticle();
  }

  void _loadArticle() {
    setState(() {
      _articleFuture = ApiService.getArticleBySlug(widget.articleSlug);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usamos un FutureBuilder para manejar la carga del artículo
      body: FutureBuilder<Map<String, dynamic>>(
        future: _articleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return ErrorDisplay(
              message: 'No se pudo cargar el artículo.',
              onRetry: _loadArticle,
            );
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Artículo no encontrado.'));
          } else {
            final article = snapshot.data!;
            // Usamos CustomScrollView para un efecto de AppBar con imagen
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 250.0,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      article['title'],
                      style: const TextStyle(
                        shadows: [Shadow(blurRadius: 10, color: Colors.black54)],
                        fontSize: 16, // Ajustamos el tamaño para que quepa mejor
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    background: FadeInImage.assetNetwork(
                      placeholder: 'assets/images/placeholder.png',
                      image: article['coverImage'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      color: Colors.black.withOpacity(0.4),
                      colorBlendMode: BlendMode.darken,
                    ),
                  ),
                ),
                // El contenido del artículo va en un SliverList
                SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Subtítulo y autor
                          Text(
                            article['subtitle'] ?? '',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Por ${article['authorName']}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFFc738dd),
                            ),
                          ),
                          const Divider(height: 40, color: Colors.white24),
                          
                          // Contenido del artículo
                          Text(
                            article['content'],
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.6, // Interlineado para fácil lectura
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}