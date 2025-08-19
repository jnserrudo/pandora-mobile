// lib/screens/manage_articles_page.dart

import 'package:flutter/material.dart';
import 'package:pandora_app/services/api_service.dart';
import 'package:pandora_app/screens/create_article_page.dart';
import 'package:pandora_app/screens/edit_article_page.dart';
// ... (imports de widgets de error, etc.)

class ManageArticlesPage extends StatefulWidget {
  const ManageArticlesPage({super.key});

  @override
  State<ManageArticlesPage> createState() => _ManageArticlesPageState();
}

class _ManageArticlesPageState extends State<ManageArticlesPage> {
  late Future<List<dynamic>> _articlesFuture;

  @override
  void initState() {
    super.initState();
    _loadAllArticles();
  }

  void _loadAllArticles() {
    setState(() {
      // --- USA EL NUEVO MÉTODO DE API ---
      _articlesFuture = ApiService.getAllArticlesForAdmin();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar Noticias')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const CreateArticlePage()),
          );
          if (result == true) _loadAllArticles();
        },
        child: const Icon(Icons.add),
        tooltip: 'Crear Noticia',
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _articlesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay artículos.'));
          }

          final articles = snapshot.data!;

          return ListView.builder(
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              return ListTile(
                leading: Image.network(
                  article['coverImage'],
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
                title: Text(article['title']),
                subtitle: Text('Estado: ${article['status']}'),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  // --- LÓGICA DE EDICIÓN MEJORADA ---
                  // 1. Necesitamos todos los datos del artículo para editar. El endpoint de admin ya los trae.
                  // 2. Navegamos a la página de edición.
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditArticlePage(article: article),
                    ),
                  );
                  // 3. Si la edición fue exitosa (devuelve true), refrescamos la lista.
                  if (result == true) _loadAllArticles();
                },
              );
            },
          );
        },
      ),
    );
  }
}
