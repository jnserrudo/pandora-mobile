import 'dart:convert'; // Necesario para decodificar el token JWT
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Función helper para decodificar el payload del JWT
Map<String, dynamic> _parseJwt(String token) {
  final parts = token.split('.');
  if (parts.length != 3) {
    throw Exception('Token JWT inválido');
  }
  final payload = parts[1];
  final normalized = base64Url.normalize(payload);
  final resp = utf8.decode(base64Url.decode(normalized));
  final payloadMap = json.decode(resp);
  return payloadMap;
}

class AuthService with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  String? _token;
  String? _refreshToken;
  int? _userId; // <-- 1. AÑADE LA VARIABLE PARA EL USER ID
  bool _isAuthenticated = false;
  String? _userRole; // <-- 1. AÑADE EL ESTADO PARA EL ROL

  // Getters
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  int? get userId => _userId; // <-- 2. AÑADE EL GETTER PARA EL USER ID
  bool get isAuthenticated => _isAuthenticated;
  String? get userRole => _userRole; // <-- 2. AÑADE EL GETTER PARA EL ROL

  // Método para guardar tokens y extraer el userId del token de acceso
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'jwt_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);

    _token = accessToken;
    _refreshToken = refreshToken;

    // --- LÓGICA CLAVE: EXTRAER USER ID DEL TOKEN ---
    try {
      final payload = _parseJwt(accessToken);
      // Asumimos que tu backend incluye el ID del usuario en el payload del JWT
      // bajo la clave 'sub' (estándar) o 'userId'. ¡Verifica esto con tu backend!
    final userIdFromToken = payload['id']; // Usamos 'id' en lugar de 'sub'
          final userRoleFromToken = payload['role']; // <-- 3. EXTRAE EL ROL DEL TOKEN

      if (userIdFromToken != null) {
        _userId = int.tryParse(userIdFromToken.toString());
        // Guardamos también el userId en el storage para el auto-login
        await _storage.write(key: 'user_id', value: _userId.toString());
      }

      if (userRoleFromToken != null) {
        _userRole = userRoleFromToken.toString();
        // Guardamos también el userRole en el storage para el auto-login
        await _storage.write(key: 'user_role', value: _userRole.toString());
      }
    } catch (e) {
      print("Error decodificando JWT o extrayendo userId: $e");
      _userId = null; // Si falla, nos aseguramos que sea nulo
    }
    // ------------------------------------------------

    _isAuthenticated = _token != null && _userId != null;
    notifyListeners();
  }

  // Intenta cargar todo desde el almacenamiento al iniciar la app.
  Future<void> tryAutoLogin() async {
    final storedToken = await _storage.read(key: 'jwt_token');
    final storedRefreshToken = await _storage.read(key: 'refresh_token');
    final storedUserId = await _storage.read(
      key: 'user_id',
    ); // <-- 3. CARGA EL USER ID
    final storedUserRole = await _storage.read(
      key: 'user_role',
    ); // <-- 3. CARGA EL ROL

    if (storedToken != null &&
        storedRefreshToken != null &&
        storedUserId != null) {
      _token = storedToken;
      _refreshToken = storedRefreshToken;
      _userId = int.tryParse(storedUserId); // <-- 4. ASIGNA EL USER ID
      _userRole = storedUserRole; // <-- 4. ASIGNA EL ROL
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  // Cierra sesión y limpia todos los datos.
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'user_id'); // <-- 5. BORRA EL USER ID
    await _storage.delete(key: 'user_role'); // <-- 5. BORRA EL ROL
    
    _token = null;
    _refreshToken = null;
    _userId = null; // <-- 6. LIMPIA EL ESTADO
    _userRole = null; // <-- 6. LIMPIA EL ROL
    _isAuthenticated = false;
    notifyListeners();
  }


  
/// Actualiza el rol del usuario en el estado local y en el almacenamiento seguro.
/// Útil cuando la API devuelve información de perfil más reciente.
Future<void> updateUserRole(String newRole) async {
  if (_userRole != newRole) {
    _userRole = newRole;
    await _storage.write(key: 'user_role', value: _userRole);
    // Notificamos a los listeners para que la UI (como ProfilePage) se reconstruya
    // con el nuevo rol y muestre los botones correctos.
    notifyListeners();
  }
}
}
