import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatear las fechas
import 'package:pandora_app/services/api_service.dart';
import 'package:pandora_app/services/auth_services.dart';
import 'package:provider/provider.dart';

import 'package:flutter/services.dart';


class CreateEventPage extends StatefulWidget {
  final int commerceId;

  const CreateEventPage({super.key, required this.commerceId});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Variables de estado para las fechas
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  // --- FUNCIÓN PARA SELECCIONAR FECHA ---
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
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

  // --- LÓGICA PARA CREAR EL EVENTO ---
  Future<void> _createEvent() async {
      HapticFeedback.mediumImpact(); // <-- AÑADE ESTA LÍNEA AL PRINCIPIO


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

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = authService.token;
    if (token == null) {
      /* ... manejo de error de token ... */
      return;
    }

    try {
      final eventData = {
        "name": _nameController.text,
        "description": _descriptionController.text,
        // Convertimos las fechas a formato ISO 8601 (formato estándar para JSON/APIs)
        "startDate": _startDate!.toIso8601String(),
        "endDate": _endDate!.toIso8601String(),
        "commerceId": widget.commerceId,
      };

      await ApiService.createEvent(eventData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Evento creado con éxito!'),
          backgroundColor: Colors.green,
        ),
      );

      // Devolvemos 'true' para que la pantalla anterior se refresque
      if (mounted) Navigator.of(context).pop(true);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Formateadores para mostrar la fecha y hora de forma amigable
    final DateFormat dateFormatter = DateFormat('EEEE, d MMMM, y', 'es_ES');
    final DateFormat timeFormatter = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Crear Nuevo Evento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Detalles del nuevo evento',
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

              // --- SELECTORES DE FECHA ---
              ListTile(
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
                leading: const Icon(Icons.calendar_today),
                title: const Text('Fecha y Hora de Fin'),
                subtitle: Text(
                  _endDate == null
                      ? 'No seleccionada'
                      : '${dateFormatter.format(_endDate!)} a las ${timeFormatter.format(_endDate!)}',
                ),
                onTap: () => _selectDate(context, false),
              ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  // 1. Deshabilitamos el botón cuando está cargando
                  onPressed: _isLoading ? null : _createEvent,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    // Opcional: Cambiamos el color cuando está deshabilitado
                    disabledBackgroundColor: Colors.grey[700],
                  ),
                  child: _isLoading
                      // 2. Si está cargando, mostramos un spinner pequeño
                      ? const SizedBox(
                          height: 24.0,
                          width: 24.0,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3.0,
                          ),
                        )
                      // 3. Si no, mostramos el texto normal
                      : const Text(
                          'Publicar Evento',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
