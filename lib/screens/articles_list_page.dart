// lib/screens/articles_list_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pandora_app/services/api_service.dart';
import 'package:pandora_app/widgets/error_display.dart';
import 'package:pandora_app/widgets/empty_state_display.dart';
import 'package:pandora_app/screens/article_detail_page.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class ArticlesListPage extends StatefulWidget {
  const ArticlesListPage({super.key});

  @override
  State<ArticlesListPage> createState() => _ArticlesListPageState();
}

class _ArticlesListPageState extends State<ArticlesListPage> {
  late Future<List<dynamic>> _articlesFuture;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  void _loadArticles() {
    setState(() {
      _articlesFuture = ApiService.getArticles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Magazine')),
      body: FutureBuilder<List<dynamic>>(
        future: _articlesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorDisplay(
              message: 'No se pudieron cargar las noticias.',
              onRetry: _loadArticles,
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyStateDisplay(
              icon: Icons.article_outlined,
              title: 'Sin Noticias',
              message:
                  'Vuelve más tarde para leer nuestras últimas publicaciones.',
              onButtonPressed: _loadArticles,
              buttonText: 'Reintentar',
            );
          }

          final articles = snapshot.data!;

          return AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: articles.length,
              itemBuilder: (context, index) {
                final article = articles[index];
                final DateTime createdAt = DateTime.parse(
                  article['createdAt'],
                ).toLocal();
                final String formattedDate = DateFormat(
                  'd \'de\' MMMM, y',
                  'es_ES',
                ).format(createdAt);

                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 20),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ArticleDetailPage(
                                  articleSlug: article['slug'],
                                ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FadeInImage.assetNetwork(
                                placeholder: 'assets/images/placeholder.png',
                                image: article['coverImage'],
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      article['category']['name']
                                          .toString()
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: Color(0xFFc738dd),
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      article['title'],
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      article['subtitle'] ?? '',
                                      style: TextStyle(color: Colors.grey[400]),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Divider(height: 30),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          article['authorName'],
                                          style: TextStyle(
                                            color: Colors.grey[300],
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                        Text(
                                          formattedDate,
                                          style: TextStyle(
                                            color: Colors.grey[500],
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
                );
              },
            ),
          );
        },
      ),
    );
  }
}
