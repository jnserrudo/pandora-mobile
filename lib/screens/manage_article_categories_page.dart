// lib/screens/manage_article_categories_page.dart

import 'package:flutter/material.dart';
import 'package:pandora_app/services/api_service.dart';
import 'package:pandora_app/widgets/error_display.dart';

class ManageArticleCategoriesPage extends StatefulWidget {
  const ManageArticleCategoriesPage({super.key});

  @override
  State<ManageArticleCategoriesPage> createState() => _ManageArticleCategoriesPageState();
}

class _ManageArticleCategoriesPageState extends State<ManageArticleCategoriesPage> {
  late Future<List<dynamic>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    setState(() {
      _categoriesFuture = ApiService.getArticleCategories();
    });
  }

  // DIÁLOGO REUTILIZABLE PARA CREAR Y EDITAR
  void _showCategoryDialog({Map<String, dynamic>? category}) {
    final isEditing = category != null;
    final _nameController = TextEditingController(text: isEditing ? category['name'] : '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar Categoría' : 'Nueva Categoría'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre de la categoría'),
              validator: (v) => v!.trim().isEmpty ? 'El nombre es requerido' : null,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    if (isEditing) {
                      await ApiService.updateArticleCategory(category['id'], _nameController.text);
                    } else {
                      await ApiService.createArticleCategory(_nameController.text);
                    }
                    Navigator.of(context).pop();
                    _loadCategories(); // Refrescar la lista
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }
  
  // DIÁLOGO DE CONFIRMACIÓN PARA BORRAR
  void _confirmDelete(int categoryId, String categoryName) {
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar la categoría "$categoryName"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await ApiService.deleteArticleCategory(categoryId);
                Navigator.of(context).pop();
                _loadCategories();
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar Categorías')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Crear Categoría',
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return ErrorDisplay(message: 'Error al cargar categorías', onRetry: _loadCategories);
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No hay categorías. Toca el + para crear una.'));

          final categories = snapshot.data!;
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                title: Text(category['name']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showCategoryDialog(category: category)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(category['id'], category['name'])),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}