import 'package:flutter/material.dart';
import 'package:pandora_app/services/api_service.dart';
import 'package:pandora_app/services/auth_services.dart';
import 'package:provider/provider.dart';

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

  String? _selectedCategory;
  final List<String> _categories = [
    'VIDA_NOCTURNA',
    'GASTRONOMIA',
    'SALAS_Y_TEATRO',
  ];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-rellenamos los campos con los datos actuales del comercio
    _nameController = TextEditingController(text: widget.commerce['name']);
    _descriptionController = TextEditingController(
      text: widget.commerce['description'],
    );
    _addressController = TextEditingController(
      text: widget.commerce['address'],
    );
    _phoneController = TextEditingController(text: widget.commerce['phone']);
    _selectedCategory = widget.commerce['category'];
  }

  Future<void> _updateCommerce() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final updatedData = {
        "name": _nameController.text,
        "description": _descriptionController.text,
        "address": _addressController.text,
        "phone": _phoneController.text,
        "category": _selectedCategory,
      };

      await ApiService.updateMyCommerce(updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comercio actualizado con éxito.'),
          backgroundColor: Colors.green,
        ),
      );
      if (mounted)
        Navigator.of(context).pop(true); // Devolvemos 'true' para refrescar
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
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
      appBar: AppBar(title: const Text('Editar mi Negocio')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            // ... (El contenido del Form es idéntico al de CreateCommercePage, pero usa los controllers pre-rellenados)
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
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Dirección'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
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
              SizedBox(
                // Quitamos el const aquí
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateCommerce,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                    ), // Le damos un padding consistente
                    disabledBackgroundColor: const Color(
                      0xFF8a2be2,
                    ).withOpacity(0.5),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24.0,
                          width: 24.0,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3.0,
                          ),
                        )
                      : const Text(
                          'Guardar Cambios',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ), // Hacemos la fuente consistente
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
