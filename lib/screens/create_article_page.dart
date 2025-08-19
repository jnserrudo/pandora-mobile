// lib/screens/create_article_page.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pandora_app/services/api_service.dart';

class CreateArticlePage extends StatefulWidget {
  const CreateArticlePage({super.key});

  @override
  State<CreateArticlePage> createState() => _CreateArticlePageState();
}

class _CreateArticlePageState extends State<CreateArticlePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _contentController = TextEditingController();
  final _authorNameController = TextEditingController();

  String? _coverImageUrl;
  bool _isUploading = false;
  bool _isSaving = false;

  // --- ESTADO PARA CATEGORÍAS ---
  late Future<List<dynamic>> _categoriesFuture;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    // Cargamos las categorías cuando la página se inicia
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

  Future<void> _createArticle() async {
    if (!_formKey.currentState!.validate()) return;
    if (_coverImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, añade una imagen de portada.'),
        ),
      );
      return;
    }
    // --- VALIDACIÓN DE CATEGORÍA ---
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una categoría.')),
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
        "status": "PUBLISHED", // O tener un selector DRAFT/PUBLISHED
      };

      await ApiService.createArticle(articleData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Artículo creado con éxito.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Devolver true para refrescar
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
      appBar: AppBar(title: const Text('Crear Noticia')),
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
                    image: _coverImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(_coverImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _isUploading
                      ? const Center(child: CircularProgressIndicator())
                      : _coverImageUrl == null
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
              // --- DROPDOWN DINÁMICO PARA CATEGORÍAS ---
              FutureBuilder<List<dynamic>>(
                future: _categoriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
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
                    validator: (v) => v == null ? 'Requerido' : null,
                  );
                },
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _createArticle,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Publicar Noticia'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
