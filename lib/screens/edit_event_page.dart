import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pandora_app/screens/login_page.dart';
import 'package:pandora_app/screens/location_picker_page.dart'; // Asumiendo que tienes esta página
import 'package:pandora_app/services/api_service.dart';
import 'package:pandora_app/services/auth_services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

// Es importante que en tu main.dart hayas inicializado el locale para 'es_ES'
// import 'package:intl/date_symbol_data_local.dart';
// await initializeDateFormatting('es_ES', null);

class EditEventPage extends StatefulWidget {
  // Recibimos el evento completo como un mapa
  final Map<String, dynamic> event;

  const EditEventPage({super.key, required this.event});

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  // Variables de estado para las fechas y ubicación
  DateTime? _startDate;
  DateTime? _endDate;
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;

  bool _isSaving = false;

  // --- ESTADO PARA IMÁGENES ACTUALIZADO ---
  String? _coverImageUrl; // <-- 1. AÑADIR ESTADO PARA PORTADA
  final List<String> _galleryImageUrls = [];
  bool _isUploadingCover = false;
  bool _isUploadingGallery = false;

  @override
  void initState() {
    super.initState();
    // Pre-llenamos los controladores y variables con los datos del evento que recibimos
    _nameController.text = widget.event['name'] ?? '';
    _descriptionController.text = widget.event['description'] ?? '';
    _locationController.text = widget.event['address'] ?? '';

    // Convertimos las fechas de String (formato ISO 8601 UTC) a DateTime local
    if (widget.event['startDate'] != null) {
      _startDate = DateTime.tryParse(widget.event['startDate'])?.toLocal();
    }
    if (widget.event['endDate'] != null) {
      _endDate = DateTime.tryParse(widget.event['endDate'])?.toLocal();
    }

    // Asignamos las coordenadas si existen
    // La API puede devolverlos como String o double, así que lo manejamos con cuidado.
    if (widget.event['latitude'] != null) {
      _latitude = double.tryParse(widget.event['latitude'].toString());
    }
    if (widget.event['longitude'] != null) {
      _longitude = double.tryParse(widget.event['longitude'].toString());
    }

    // --- 2. INICIALIZAR IMÁGENES ---
    _coverImageUrl = widget.event['coverImage'];
    _galleryImageUrls.addAll(
      List<String>.from(widget.event['galleryImages'] ?? []),
    );
  }

  // --- FUNCIÓN PARA SELECCIONAR FECHA (idéntica a la de CreateEventPage) ---
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(
        2020,
      ), // Permitir editar eventos pasados si es necesario
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          (isStartDate ? _startDate : _endDate) ?? DateTime.now(),
        ),
      );
      if (pickedTime != null) {
        setState(() {
          final finalDateTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          if (isStartDate) {
            _startDate = finalDateTime;
          } else {
            _endDate = finalDateTime;
          }
        });
      }
    }
  }

  // --- LÓGICA DE SELECCIÓN DE IMÁGENES (REUTILIZADA) ---
  Future<String?> _pickAndUploadSingleImage() async {
    final imagePicker = ImagePicker();
    final XFile? imageFile = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (imageFile == null) return null;
    try {
      return await ApiService.uploadImage(imageFile);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al subir imagen: $e')));
      return null;
    }
  }

  Future<void> _handleCoverImagePick() async {
    setState(() => _isUploadingCover = true);
    final imageUrl = await _pickAndUploadSingleImage();
    if (imageUrl != null) {
      setState(() => _coverImageUrl = imageUrl);
    }
    setState(() => _isUploadingCover = false);
  }

  Future<void> _handleGalleryImagePick() async {
    setState(() => _isUploadingGallery = true);
    final imageUrl = await _pickAndUploadSingleImage();
    if (imageUrl != null) {
      setState(() => _galleryImageUrls.add(imageUrl));
    }
    setState(() => _isUploadingGallery = false);
  }

  void _removeGalleryImage(int index) {
    setState(() => _galleryImageUrls.removeAt(index));
  }

  // --- LÓGICA PARA ACTUALIZAR EL EVENTO ---
  Future<void> _updateEvent() async {
    HapticFeedback.mediumImpact();

    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona las fechas de inicio y fin.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La fecha de fin no puede ser anterior a la de inicio.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if ((_coverImageUrl == null || _coverImageUrl!.isEmpty) &&
        _galleryImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, añade al menos una imagen.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _isSaving = true);

    // Verificación de autenticación (muy importante)
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = authService.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu sesión ha expirado. Por favor, inicia sesión.'),
          backgroundColor: Colors.red,
        ),
      );
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
      }
      return;
    }

    try {
      // --- LÓGICA DE PAYLOAD MEJORADA ---
      String finalCoverImage = _coverImageUrl ?? _galleryImageUrls.first;

      final eventData = {
        "name": _nameController.text,
        "description": _descriptionController.text,
        "startDate": _startDate!.toUtc().toIso8601String(),
        "endDate": _endDate!.toUtc().toIso8601String(),
        // Incluir la dirección y coordenadas solo si están disponibles
        if (_locationController.text.isNotEmpty)
          "address": _locationController.text,
        if (_latitude != null) "latitude": _latitude,
        if (_longitude != null) "longitude": _longitude,
        "coverImage": finalCoverImage, // <-- 3. ENVIAR LA IMAGEN DE PORTADA
        "galleryImages": _galleryImageUrls,
      };

      // Usamos el ID del evento que recibimos en el widget
      await ApiService.updateEvent(widget.event['id'], eventData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Evento actualizado con éxito!'),
          backgroundColor: Colors.green,
        ),
      );
      // Devolvemos 'true' para que la pantalla anterior se refresque
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al actualizar: ${e.toString().replaceAll("Exception: ", "")}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormatter = DateFormat('EEEE, d MMMM, y', 'es_ES');
    final DateFormat timeFormatter = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Evento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edita los detalles del evento',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Evento',
                ),
                validator: (v) => v!.isEmpty ? 'El nombre es requerido' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción del Evento',
                ),
                maxLines: 4,
                validator: (v) =>
                    v!.isEmpty ? 'La descripción es requerida' : null,
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Fecha y Hora de Inicio'),
                subtitle: Text(
                  _startDate == null
                      ? 'No seleccionada'
                      : '${dateFormatter.format(_startDate!)} a las ${timeFormatter.format(_startDate!)}',
                ),
                onTap: () => _selectDate(context, true),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Fecha y Hora de Fin'),
                subtitle: Text(
                  _endDate == null
                      ? 'No seleccionada'
                      : '${dateFormatter.format(_endDate!)} a las ${timeFormatter.format(_endDate!)}',
                ),
                onTap: () => _selectDate(context, false),
              ),

              // Widget para seleccionar la ubicación en el mapa
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.location_on_outlined),
                title: const Text('Lugar del Evento'),
                subtitle: Text(
                  _locationController.text.isNotEmpty
                      ? _locationController.text
                      : 'Toca para seleccionar en el mapa',
                ),
                trailing: const Icon(Icons.map_outlined),
                onTap: () async {
                  // Navega a la página del selector de mapa y espera un resultado
                  final result = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LocationPickerPage(),
                    ),
                  );
                  // Si el usuario seleccionó una ubicación y volvió, actualizamos el estado
                  if (result != null && result.containsKey('latitude')) {
                    setState(() {
                      _latitude = result['latitude'];
                      _longitude = result['longitude'];
                      _locationController.text =
                          result['address'] ?? 'Ubicación seleccionada';
                    });
                  }
                },
              ),

               // --- 4. AÑADIR UI PARA IMAGEN DE PORTADA ---
              const SizedBox(height: 20),
              const Text('Imagen de Portada', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _handleCoverImagePick,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12.0),
                    image: _coverImageUrl != null && _coverImageUrl!.isNotEmpty
                      ? DecorationImage(image: NetworkImage(_coverImageUrl!), fit: BoxFit.cover)
                      : null,
                  ),
                  child: _isUploadingCover
                    ? const Center(child: CircularProgressIndicator())
                    : (_coverImageUrl == null || _coverImageUrl!.isEmpty)
                      ? const Center(child: Icon(Icons.add_a_photo, size: 50, color: Colors.white70))
                      : null,
                ),
              ),

              // --- UI PARA LA GALERÍA DE IMÁGENES (NUEVA) ---
              const SizedBox(height: 20),
              const Text(
                'Galería de Imágenes',
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
                        ClipRRect(
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
                            onPressed: () => _removeGalleryImage(idx),
                          ),
                        ),
                      ],
                    );
                  }).toList(),

                  if (_isUploadingGallery)
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
                      onTap: _handleGalleryImagePick,
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
                  onPressed: _isSaving ? null : _updateEvent,
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
