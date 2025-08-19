// lib/screens/edit_article_page.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pandora_app/services/api_service.dart';

class EditArticlePage extends StatefulWidget {
  final Map<String, dynamic> article;
  const EditArticlePage({super.key, required this.article});

  @override
  State<EditArticlePage> createState() => _EditArticlePageState();
}

class _EditArticlePageState extends State<EditArticlePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _contentController;
  late TextEditingController _authorNameController;

  String? _coverImageUrl;
  bool _isUploading = false;
  bool _isSaving = false;

  late Future<List<dynamic>> _categoriesFuture;
  int? _selectedCategoryId;

  String? _selectedStatus;
  final List<String> _statuses = ['PUBLISHED', 'DRAFT'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.article['title']);
    _subtitleController = TextEditingController(
      text: widget.article['subtitle'],
    );
    _contentController = TextEditingController(text: widget.article['content']);
    _authorNameController = TextEditingController(
      text: widget.article['authorName'],
    );
    _coverImageUrl = widget.article['coverImage'];
    _selectedCategoryId = widget.article['categoryId'];
    _selectedStatus = widget.article['status'];

    _categoriesFuture = ApiService.getArticleCategories();
  }

  Future<void> _handleCoverImagePick() async {
    final imagePicker = ImagePicker();
    final XFile? imageFile = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (imageFile == null) return;

    setState(() => _isUploading = true);
    try {
      final imageUrl = await ApiService.uploadImage(imageFile);
      setState(() => _coverImageUrl = imageUrl);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al subir imagen: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _updateArticle() async {
    if (!_formKey.currentState!.validate() ||
        _coverImageUrl == null ||
        _selectedCategoryId == null ||
        _selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, completa todos los campos requeridos.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final articleData = {
        "title": _titleController.text,
        "subtitle": _subtitleController.text,
        "content": _contentController.text,
        "authorName": _authorNameController.text,
        "coverImage": _coverImageUrl,
        "categoryId": _selectedCategoryId,
        "status": _selectedStatus,
      };

      await ApiService.updateArticle(widget.article['id'], articleData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Artículo actualizado.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _contentController.dispose();
    _authorNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Noticia')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Imagen de Portada',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _handleCoverImagePick,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12.0),
                    image: _coverImageUrl != null && _coverImageUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(_coverImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _isUploading
                      ? const Center(child: CircularProgressIndicator())
                      : (_coverImageUrl == null || _coverImageUrl!.isEmpty)
                      ? const Center(
                          child: Icon(
                            Icons.add_a_photo,
                            size: 50,
                            color: Colors.white70,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título Principal',
                ),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _subtitleController,
                decoration: const InputDecoration(
                  labelText: 'Subtítulo (Opcional)',
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Contenido de la Noticia',
                ),
                maxLines: 10,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _authorNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Autor',
                ),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 20),
              FutureBuilder<List<dynamic>>(
                future: _categoriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return const Text('No se pudieron cargar las categorías.');
                  }
                  final categories = snapshot.data!;
                  return DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    items: categories.map<DropdownMenuItem<int>>((category) {
                      return DropdownMenuItem<int>(
                        value: category['id'],
                        child: Text(category['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    validator: (v) =>
                        v == null ? 'Selecciona una categoría' : null,
                  );
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                items: _statuses.map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(
                      status == 'PUBLISHED' ? 'Publicado' : 'Borrador',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Estado de Publicación',
                ),
                validator: (v) => v == null ? 'Selecciona un estado' : null,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _updateArticle,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Guardar Cambios'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
