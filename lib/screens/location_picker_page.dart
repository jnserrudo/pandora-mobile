// lib/screens/location_picker_page.dart

import 'dart:async'; // Necesario para TimeoutException
import 'dart:convert';
import 'dart:io'; // Necesario para SocketException
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  static final LatLng _initialPosition = LatLng(
    -24.7859,
    -65.4117,
  ); // Salta, Argentina

  final MapController _mapController = MapController();
  LatLng _selectedLocation = _initialPosition;
  String _selectedAddress = 'Moviendo el mapa...';
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocationAndCenterMap();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // --- FUNCIÓN DE PERMISOS Y UBICACIÓN (MEJORADA) ---
  Future<void> _getCurrentLocationAndCenterMap() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, activa los servicios de ubicación.'),
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // Mostramos nuestro propio diálogo explicando por qué necesitamos el permiso
        if (mounted) {
          final bool? userAgreed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Permiso de Ubicación'),
              content: const Text(
                'Pandora necesita tu ubicación para centrar el mapa. ¿Deseas permitirlo?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Ahora no'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Permitir'),
                ),
              ],
            ),
          );

          if (userAgreed != true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permiso no solicitado.')),
            );
            return;
          }
        }

        // Solo si el usuario aceptó, pedimos el permiso del sistema
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de ubicación denegado.')),
        );
        return;
      }

      if (permission == LocationPermission.deniedForever && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permisos bloqueados. Por favor, actívalos en la configuración.',
            ),
          ),
        );
        await Geolocator.openAppSettings(); // Guía al usuario a la configuración de la app
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final newLocation = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() => _selectedLocation = newLocation);
        _mapController.move(newLocation, 16.0);
        _getAddressFromLatLng(newLocation);
      }
    } catch (e) {
      print(
        "[LocationPicker] EXCEPCIÓN en _getCurrentLocationAndCenterMap: $e",
      );
      _getAddressFromLatLng(
        _initialPosition,
      ); // Intenta cargar dirección de la ubicación por defecto
    }
  }

  // --- FUNCIÓN DE BÚSQUEDA DE DIRECCIÓN (MEJORADA) ---
  Future<void> _getAddressFromLatLng(LatLng position) async {
    if (!mounted) return;
    setState(() => _isLoadingAddress = true);

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&accept-language=es',
      );

      final response = await http
          .get(url, headers: {'User-Agent': 'PandoraApp/1.0'})
          .timeout(const Duration(seconds: 10)); // Timeout de 10 segundos

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final displayName = data['display_name'];

        if (mounted && displayName != null) {
          setState(() => _selectedAddress = displayName.toString());
        } else if (mounted) {
          setState(
            () => _selectedAddress = 'No se pudo encontrar la dirección.',
          );
        }
      } else if (mounted) {
        setState(() => _selectedAddress = 'El servicio de mapas no responde.');
      }
    } on TimeoutException {
      if (mounted)
        setState(
          () => _selectedAddress = 'La conexión es lenta. Intenta de nuevo.',
        );
    } on SocketException {
      if (mounted)
        setState(
          () => _selectedAddress = 'Error de red. Verifica tu internet.',
        );
    } catch (e) {
      print("[LocationPicker] EXCEPCIÓN en _getAddressFromLatLng: $e");
      if (mounted)
        setState(
          () => _selectedAddress = 'Ocurrió un error al buscar la dirección.',
        );
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  void _confirmSelection() {
    final result = {
      'latitude': _selectedLocation.latitude,
      'longitude': _selectedLocation.longitude,
      'address': _selectedAddress,
    };
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Ubicación'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocationAndCenterMap,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialPosition,
              initialZoom: 14.0,
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture && mounted)
                  setState(() => _selectedLocation = pos.center!);
              },
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  _getAddressFromLatLng(_selectedLocation);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                    'com.example.pandora_app', // este es el nombre del paquete, recordar "Antes de publicar tu app en la Play Store o App Store, debes cambiarlo a algo único, como com.tuempresa.pandora_app."
              ),
            ],
          ),
          const Center(
            child: Icon(Icons.location_pin, color: Colors.red, size: 50),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _isLoadingAddress
                      ? const LinearProgressIndicator()
                      : Text(
                          _selectedAddress,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _confirmSelection,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      child: const Text(
                        'Confirmar esta ubicación',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
