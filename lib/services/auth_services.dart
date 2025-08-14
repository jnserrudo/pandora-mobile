import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Usaremos ChangeNotifier para notificar a los widgets cuando el estado de autenticación cambie.
class AuthService with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  String? _token;
  bool _isAuthenticated = false;
  String? _refreshToken; // <-- 1. AÑADE UN CAMPO PARA EL REFRESH TOKEN

  // Getters para acceder al estado desde fuera de la clase.
  String? get token => _token;
  bool get isAuthenticated => _isAuthenticated;
  String? get refreshToken => _refreshToken; // <-- 2. AÑADE SU GETTER

  // Método para guardar el token después de un login exitoso.
 // 3. MODIFICA saveToken PARA GUARDAR AMBOS
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'jwt_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
    _token = accessToken;
    _refreshToken = refreshToken;
    _isAuthenticated = true;
    notifyListeners();
  }

  // Método para intentar cargar el token desde el almacenamiento al iniciar la app.
  Future<void> tryAutoLogin() async {
    final storedToken = await _storage.read(key: 'jwt_token');
    final storedRefreshToken = await _storage.read(key: 'refresh_token');
    if (storedToken != null && storedRefreshToken != null) {
      _token = storedToken;
      _refreshToken = storedRefreshToken;
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  // Método para cerrar sesión.
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'refresh_token');
    _token = null;
    _refreshToken = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}