import 'package:flutter/material.dart';
import 'package:pandora_app/services/api_service.dart';
import 'package:pandora_app/services/auth_services.dart';
import 'package:provider/provider.dart';

class CreateCommercePage extends StatefulWidget {
  const CreateCommercePage({super.key});

  @override
  State<CreateCommercePage> createState() => _CreateCommercePageState();
}

class _CreateCommercePageState extends State<CreateCommercePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  // Para el Dropdown de categorías
  String? _selectedCategory;
  final List<String> _categories = ['VIDA_NOCTURNA', 'GASTRONOMIA', 'SALAS_Y_TEATRO'];

  bool _isLoading = false;

  // --- LÓGICA PARA CREAR EL COMERCIO ---
  Future<void> _createCommerce() async {
    // 1. Validar el formulario
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una categoría.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final token = authService.token;

    if (token == null) {
      // Esto no debería pasar si el botón solo es visible para usuarios logueados.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de autenticación. Por favor, inicia sesión de nuevo.'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 2. Construir el mapa de datos para enviar a la API
      final commerceData = {
        "name": _nameController.text,
        "description": _descriptionController.text,
        "address": _addressController.text,
        "phone": _phoneController.text,
        "category": _selectedCategory,
        // Por ahora, enviamos una galería de ejemplo. En el futuro, aquí iría un uploader de imágenes.
        "galleryImages": ["https://picsum.photos/seed/${_nameController.text}/800/600"]
      };

      // 3. Llamar a la API
      final response = await ApiService.createCommerce(commerceData);

      // --- 4. MANEJO DEL ROL (LA PARTE CLAVE) ---
      // El backend debería devolver un nuevo token si el rol del usuario cambió.
      // Por ahora, asumiremos que debemos volver a cargar el perfil para ver el nuevo rol.
      // Una mejora futura sería que el backend devolviera un nuevo token aquí.
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Tu negocio ha sido registrado con éxito!'), backgroundColor: Colors.green),
      );

      // / 5. Navegamos de vuelta al perfil, pasando 'true' para indicar que hubo un cambio.
      Navigator.of(context).pop(true);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      appBar: AppBar(title: const Text('Registrar mi Negocio')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Contanos sobre tu negocio', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nombre del Comercio'), validator: (v) => v!.isEmpty ? 'El nombre es requerido' : null),
              const SizedBox(height: 20),
              TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Descripción'), maxLines: 4, validator: (v) => v!.isEmpty ? 'La descripción es requerida' : null),
              const SizedBox(height: 20),
              TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: 'Dirección'), validator: (v) => v!.isEmpty ? 'La dirección es requerida' : null),
              const SizedBox(height: 20),
              TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Teléfono (Opcional)'), keyboardType: TextInputType.phone),
              const SizedBox(height: 20),
              
              // --- DROPDOWN PARA CATEGORÍAS ---
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                hint: const Text('Selecciona una categoría'),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category.replaceAll('_', ' ').toLowerCase().replaceFirst(category[0].toLowerCase(), category[0])),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (value) => value == null ? 'La categoría es requerida' : null,
              ),

              const SizedBox(height: 40),
              _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _createCommerce,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Registrar Comercio', style: TextStyle(fontSize: 16)),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}