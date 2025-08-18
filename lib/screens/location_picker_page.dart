import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  static final LatLng _initialPosition = LatLng(-26.8315, -65.2073);

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

  Future<void> _getCurrentLocationAndCenterMap() async {
    print("[LocationPicker] Intentando obtener la ubicación actual...");
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print(
          "[LocationPicker] Error: Los servicios de ubicación están desactivados.",
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, activa los servicios de ubicación.'),
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      print("[LocationPicker] Permiso de ubicación actual: $permission");
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print("[LocationPicker] Error: El usuario denegó los permisos.");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Se necesitan permisos de ubicación para centrar el mapa.',
              ),
            ),
          );
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        print("[LocationPicker] Error: Permisos denegados permanentemente.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Los permisos de ubicación fueron denegados permanentemente.',
            ),
          ),
        );
        return;
      }

      print("[LocationPicker] Obteniendo posición...");
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print(
        "[LocationPicker] Posición obtenida: ${position.latitude}, ${position.longitude}",
      );

      final newLocation = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() => _selectedLocation = newLocation);
        _mapController.move(newLocation, 16.0);
        _getAddressFromLatLng(newLocation);
      }
    } catch (e) {
      print(
        "[LocationPicker] !!! EXCEPCIÓN en _getCurrentLocationAndCenterMap: $e",
      );
      // Si falla, al menos intenta obtener la dirección de la ubicación inicial
      _getAddressFromLatLng(_initialPosition);
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    print(
      "[LocationPicker] Buscando dirección para: ${position.latitude}, ${position.longitude} usando Nominatim...",
    );
    if (!mounted) return;
    setState(() => _isLoadingAddress = true);

    try {
      // Construimos la URL para la API de Nominatim
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&accept-language=es',
      );

      // Realizamos la petición GET
      final response = await http.get(
        url,
        // Es una buena práctica incluir un User-Agent
        headers: {'User-Agent': 'PandoraApp/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // La dirección completa está en la clave 'display_name'
        final displayName = data['display_name'];

        if (mounted && displayName != null) {
          final address = displayName.toString();
          print("[LocationPicker] Dirección encontrada: $address");
          setState(() => _selectedAddress = address);
        } else if (mounted) {
          print(
            "[LocationPicker] No se encontró la dirección en la respuesta de Nominatim.",
          );
          setState(
            () => _selectedAddress = 'No se pudo encontrar la dirección.',
          );
        }
      } else {
        print(
          "[LocationPicker] Error de Nominatim. Código: ${response.statusCode}",
        );
        if (mounted)
          setState(
            () => _selectedAddress = 'Error al contactar el servicio de mapas.',
          );
      }
    } catch (e) {
      print(
        "[LocationPicker] !!! EXCEPCIÓN en _getAddressFromLatLng (http): $e",
      );
      if (mounted) {
        setState(
          () => _selectedAddress = 'Error de conexión. Verifica tu internet.',
        );
      }
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
    // El resto del build no cambia...
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
              onPositionChanged: (MapPosition pos, bool hasGesture) {
                if (hasGesture) {
                  if (mounted) setState(() => _selectedLocation = pos.center!);
                }
              },
              onMapEvent: (MapEvent event) {
                if (event is MapEventMoveEnd) {
                  _getAddressFromLatLng(_selectedLocation);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                    'com.example.pandora_app', // Reemplaza con el nombre de tu paquete
                // AÑADIMOS UN ERROR BUILDER PARA VER SI LOS TILES FALLAN
                errorImage: const AssetImage(
                  'assets/images/placeholder.png',
                ), // <-- AÑADE UNA IMAGEN DE PLACEHOLDER
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
                color: Colors.white,
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
