// create_commerce_page.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pandora_app/screens/location_picker_page.dart'; // <-- IMPORTAR
import 'package:pandora_app/services/api_service.dart';

class CreateCommercePage extends StatefulWidget {
  const CreateCommercePage({super.key});

  @override
  State<CreateCommercePage> createState() => _CreateCommercePageState();
}

class _CreateCommercePageState extends State<CreateCommercePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController =
      TextEditingController(); // Usaremos este para mostrar la dirección
  final _phoneController = TextEditingController();

  // Variables de estado
  String? _selectedCategory;
  double? _latitude; // <-- AÑADIR
  double? _longitude; // <-- AÑADIR
  bool _isLoading = false;

  final List<String> _galleryImageUrls = [];
  bool _isUploading = false; // Estado específico para la carga de imágenes

  final List<String> _categories = [
    'VIDA_NOCTURNA',
    'GASTRONOMIA',
    'SALAS_Y_TEATRO',
  ];

  // --- LÓGICA PARA ELEGIR Y SUBIR IMAGEN ---
  Future<void> _pickAndUploadImage() async {
    final imagePicker = ImagePicker();
    final XFile? imageFile = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (imageFile == null) return;

    setState(() => _isUploading = true);
    try {
      final imageUrl = await ApiService.uploadImage(imageFile);
      setState(() {
        _galleryImageUrls.add(
          imageUrl,
        ); // Añadimos la URL a nuestra lista local
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al subir imagen: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // --- LÓGICA PARA QUITAR IMAGEN ---
  void _removeImage(int index) {
    setState(() {
      _galleryImageUrls.removeAt(index);
    });
  }

  Future<void> _createCommerce() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, completa todos los campos requeridos.'),
        ),
      );
      return;
    }

    // Validación extra para la dirección
    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona una ubicación en el mapa.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final commerceData = {
        "name": _nameController.text,
        "description": _descriptionController.text,
        "address": _addressController.text,
        "phone": _phoneController.text,
        "category": _selectedCategory,
        // Enviar las coordenadas a la API
        if (_latitude != null) "latitude": _latitude,
        if (_longitude != null) "longitude": _longitude,
        "galleryImages": _galleryImageUrls,
      };

      await ApiService.createCommerce(commerceData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Tu negocio ha sido enviado para revisión!'),
          backgroundColor: Colors.green,
        ),
      );

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registra tu Negocio')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Comercio',
                ),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 4,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 20),

              // --- CAMBIO AQUÍ: Selector de Ubicación ---
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.location_on_outlined),
                title: const Text('Dirección del Comercio'),
                subtitle: Text(
                  _addressController.text.isNotEmpty
                      ? _addressController.text
                      : 'Toca para seleccionar en el mapa',
                ),
                trailing: const Icon(Icons.map_outlined),
                onTap: () async {
                  final result = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LocationPickerPage(),
                    ),
                  );
                  if (result != null && result.containsKey('latitude')) {
                    setState(() {
                      _latitude = result['latitude'];
                      _longitude = result['longitude'];
                      _addressController.text =
                          result['address'] ?? 'Ubicación seleccionada';
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono (Opcional)',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                decoration: const InputDecoration(labelText: 'Categoría'),
                validator: (v) => v == null ? 'Selecciona una categoría' : null,
              ),

              const SizedBox(height: 40),

              // --- UI PARA LA GALERÍA DE IMÁGENES ---
              const SizedBox(height: 20),
              const Text(
                'Galería de Imágenes (Opcional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  ..._galleryImageUrls.asMap().entries.map((entry) {
                    int idx = entry.key;
                    String imageUrl = entry.value;
                    return Stack(
                      children: [
                        Image.network(
                          imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: -10,
                          right: -10,
                          child: IconButton(
                            icon: const Icon(
                              Icons.remove_circle,
                              color: Colors.red,
                            ),
                            onPressed: () => _removeImage(idx),
                          ),
                        ),
                      ],
                    );
                  }).toList(),

                  // Botón para añadir
                  if (_isUploading)
                    Container(
                      width: 100,
                      height: 100,
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  else
                    GestureDetector(
                      onTap: _pickAndUploadImage,
                      child: Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[800],
                        child: const Icon(Icons.add_a_photo, size: 40),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createCommerce,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Enviar Registro'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
