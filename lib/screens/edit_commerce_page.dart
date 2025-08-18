// edit_commerce_page.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pandora_app/screens/location_picker_page.dart'; // <-- IMPORTAR
import 'package:pandora_app/services/api_service.dart';

class EditCommercePage extends StatefulWidget {
  final Map<String, dynamic> commerce;

  const EditCommercePage({super.key, required this.commerce});

  @override
  State<EditCommercePage> createState() => _EditCommercePageState();
}

class _EditCommercePageState extends State<EditCommercePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;

  // Variables de estado
  String? _selectedCategory;
  double? _latitude; // <-- AÑADIR
  double? _longitude; // <-- AÑADIR
  bool _isLoading = false;
  bool _isSaving = false; // <-- Renombrado para claridad (guardado general)
  bool _isUploading = false; // <-- Estado específico para la carga de imágenes

  // ESTADO LOCAL PARA IMÁGENES
  final List<String> _galleryImageUrls = []; // <-- Gestionamos todo aquí

  final List<String> _categories = [
    'VIDA_NOCTURNA',
    'GASTRONOMIA',
    'SALAS_Y_TEATRO',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.commerce['name']);
    _descriptionController = TextEditingController(
      text: widget.commerce['description'],
    );
    _addressController = TextEditingController(
      text: widget.commerce['address'],
    );
    _phoneController = TextEditingController(text: widget.commerce['phone']);
    _selectedCategory = widget.commerce['category'];

    // Pre-rellenar las coordenadas si existen
    if (widget.commerce['latitude'] != null) {
      _latitude = double.tryParse(widget.commerce['latitude'].toString());
    }
    if (widget.commerce['longitude'] != null) {
      _longitude = double.tryParse(widget.commerce['longitude'].toString());
    }

    // Inicializamos nuestra lista local con los datos del widget
    _galleryImageUrls.addAll(
      List<String>.from(widget.commerce['galleryImages'] ?? []),
    );
  }

  // --- LÓGICA DE ACTUALIZACIÓN (AHORA ENVÍA TODO JUNTO) ---
  Future<void> _updateCommerce() async {
    if (!_formKey.currentState!.validate() || _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, completa todos los campos requeridos.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updatedData = {
        "name": _nameController.text,
        "description": _descriptionController.text,
        "address": _addressController.text,
        "phone": _phoneController.text,
        "category": _selectedCategory,
        if (_latitude != null) "latitude": _latitude,
        if (_longitude != null) "longitude": _longitude,
        "galleryImages":
            _galleryImageUrls, // <-- Envía la lista de imágenes local
      };

      await ApiService.updateMyCommerce(updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comercio actualizado con éxito.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- LÓGICA PARA ELEGIR Y SUBIR IMAGEN (REFINADA) ---
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
      // Simplemente añadimos la URL a nuestra lista local. No llamamos a updateMyCommerce aquí.
      setState(() {
        _galleryImageUrls.add(imageUrl);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // --- LÓGICA PARA QUITAR IMAGEN (COMPLETADA) ---
  void _removeImage(int index) {
    setState(() {
      _galleryImageUrls.removeAt(index);
    });
    // ¡Eso es todo! Solo modificamos la lista local. El cambio se guardará
    // cuando el usuario presione "Guardar Cambios".
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
      appBar: AppBar(title: const Text('Editar mi Negocio')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
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
              ),
              const SizedBox(height: 40),

              const SizedBox(height: 20),
              const Text(
                'Galería de Imágenes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              // Aquí construirías una GridView o un Row con las imágenes existentes
              // y un botón para añadir más.
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  // Mapear las URLs existentes a widgets de imagen
                  ..._galleryImageUrls.asMap().entries.map((entry) {
                    int idx = entry.key;
                    String imageUrl = entry.value;
                    return Stack(
                      children: [
                        ClipRRect(
                          // <-- Para bordes redondeados
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            imageUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: -10,
                          right: -10,
                          child: IconButton(
                            icon: const Icon(
                              Icons.remove_circle,
                              color: Colors.red,
                            ),
                            onPressed: () => _removeImage(
                              idx,
                            ), // <-- Llama a la nueva función
                          ),
                        ),
                      ],
                    );
                  }).toList(),

                  // Botón para añadir una nueva imagen
                  if (_isUploading)
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  else
                    GestureDetector(
                      onTap: _pickAndUploadImage,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: const Icon(Icons.add_a_photo, size: 40),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateCommerce,
                  child: _isLoading
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
