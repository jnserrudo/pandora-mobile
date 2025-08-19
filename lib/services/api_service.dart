import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart'; //hay que importar esto para poder usar la vble kdebugmode
import 'package:image_picker/image_picker.dart';

import 'package:pandora_app/services/auth_services.dart';

/// Excepción personalizada para errores de API
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final dynamic responseBody;

  ApiException({
    required this.message,
    required this.statusCode,
    this.responseBody,
  });

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class ApiService {
  // IMPORTANTE: Reemplaza esta URL con la IP de tu máquina si pruebas en un emulador/dispositivo real.
  // Si tu backend corre en tu PC, el emulador no puede acceder a 'localhost'.
  // 1. En tu PC, abre cmd y escribe `ipconfig`. Busca tu dirección "IPv4".
  // 2. Reemplaza 'localhost' con esa IP. Ejemplo: 'http://192.168.1.10:3000/api'
  // Reemplaza 192.168.1.10 con TU PROPIA DIRECCIÓN IPv4
  // --- LÓGICA PARA ELEGIR LA URL CORRECTA ---
  // kDebugMode es una constante de Flutter que es 'true' cuando estás en modo debug
  // y 'false' cuando la app está en modo release (producción).
  static final String _baseUrl = kDebugMode
      ? dotenv.env['API_BASE_URL_DEV']!
      : dotenv.env['API_BASE_URL_PROD']!;
  //static final String _baseUrl=dotenv.env['API_BASE_URL_PROD']!;

  // --- ASEGÚRATE DE QUE ESTAS DOS PARTES EXISTAN ---

  /// Referencia estática a la instancia de AuthService para acceder a los tokens.
  static AuthService? _authService;

  /// Debe ser llamado una vez al inicio de la app (ej. en SplashScreen)
  /// para inyectar la dependencia de AuthService.
  static void initialize(AuthService authService) {
    _authService = authService;
  }

  // --- 2. GESTIÓN CENTRALIZADA DE PETICIONES (EL "INTERCEPTOR") ---
  // Este es el único lugar donde vivirá la lógica de refresh token.
  static Future<http.Response> _makeAuthenticatedRequest(
    Future<http.Response> Function(Map<String, String> headers) requestFunction,
  ) async {
    // Validación de autenticación
    if (_authService == null) {
      throw ApiException(message: 'Servicio no inicializado', statusCode: 500);
    }

    if (!_authService!.isAuthenticated) {
      throw ApiException(message: 'Usuario no autenticado', statusCode: 401);
    }

    // Configurar headers con el token
    Map<String, String> headers = {
      'Authorization': 'Bearer ${_authService!.token}',
      'Content-Type': 'application/json',
    };

    try {
      var response = await requestFunction(headers);

      // Si la respuesta es exitosa o no es un error de autenticación, la devolvemos
      if (response.statusCode != 401 && response.statusCode != 403) {
        return response;
      }

      // Si hay un error de autenticación y tenemos refresh token, intentamos refrescar
      if (_authService!.refreshToken != null) {
        try {
          final refreshResponse = await http.post(
            Uri.parse('$_baseUrl/auth/refresh-token'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'refreshToken': _authService!.refreshToken}),
          );

          if (refreshResponse.statusCode == 200) {
            final responseData = json.decode(refreshResponse.body);
            final newAccessToken = responseData['accessToken'];
            final newRefreshToken =
                responseData['refreshToken'] ?? _authService!.refreshToken;

            await _authService!.saveTokens(newAccessToken, newRefreshToken);

            // Actualizamos el token en los headers y reintentamos la petición
            headers['Authorization'] = 'Bearer $newAccessToken';
            return await requestFunction(headers);
          } else {
            // Si el refresh falla, cerramos la sesión
            await _authService!.logout();
            throw ApiException(
              message:
                  'La sesión ha expirado. Por favor, inicia sesión nuevamente.',
              statusCode: refreshResponse.statusCode,
            );
          }
        } catch (e) {
          await _authService!.logout();
          if (e is ApiException) rethrow;
          throw ApiException(
            message: 'Error al intentar renovar la sesión',
            statusCode: 500,
          );
        }
      }

      // Si llegamos aquí, no había refresh token o falló la renovación
      await _authService!.logout();
      throw ApiException(
        message: 'La sesión ha expirado. Por favor, inicia sesión nuevamente.',
        statusCode: 401,
      );
    } catch (e) {
      // Si ya es una ApiException, la relanzamos
      if (e is ApiException) rethrow;

      // Cualquier otro error lo convertimos a ApiException
      throw ApiException(
        message: 'Error de conexión: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  /// Procesa la respuesta final.
  static dynamic _processResponse(http.Response response) {
    try {
      // Verificamos si el cuerpo de la respuesta está vacío
      if (response.body.trim().isEmpty) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return null; // Respuesta exitosa sin cuerpo
        }
        throw _createApiException(
          'La respuesta del servidor está vacía',
          response.statusCode,
        );
      }

      // Intentamos decodificar el JSON
      final dynamic responseBody;
      try {
        responseBody = json.decode(response.body);
      } catch (e) {
        // Si no es JSON válido, devolvemos el cuerpo como texto
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response.body;
        }
        throw _createApiException(
          'Respuesta no válida del servidor: ${response.body}',
          response.statusCode,
        );
      }

      // Verificamos si la respuesta es exitosa
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody;
      }

      // Manejo de errores con formato conocido
      String? errorMessage;
      if (responseBody is Map) {
        // Intentamos obtener el mensaje de error de campos comunes
        errorMessage =
            responseBody['message']?.toString() ??
            responseBody['error']?.toString() ??
            responseBody['error_description']?.toString();
      }

      throw _createApiException(
        errorMessage ?? 'Error en la solicitud',
        response.statusCode,
        responseBody,
      );
    } catch (e) {
      // Simplificamos el manejo de excepciones
      if (e is! Exception) {
        throw _createApiException(
          'Error inesperado: ${e.toString()}',
          response.statusCode,
        );
      }
      rethrow;
    }
  }

  /// Crea una excepción de API consistente
  static ApiException _createApiException(
    String message,
    int statusCode, [
    dynamic responseBody,
  ]) {
    // Mensaje amigable basado en el código de estado
    String friendlyMessage = message;

    if (statusCode == 401) {
      friendlyMessage = 'No autorizado. Por favor, inicia sesión nuevamente.';
    } else if (statusCode == 403) {
      friendlyMessage = 'No tienes permiso para realizar esta acción.';
    } else if (statusCode == 404) {
      friendlyMessage = 'Recurso no encontrado.';
    } else if (statusCode >= 500) {
      friendlyMessage = 'Error en el servidor. Por favor, inténtalo más tarde.';
    }

    return ApiException(
      message: friendlyMessage,
      statusCode: statusCode,
      responseBody: responseBody,
    );
  }

  // --- MÉTODOS PARA COMERCIOS ---
  static Future<List<dynamic>> getCommerces({String? category}) async {
    String url = '$_baseUrl/commerces';
    if (category != null) url += '?category=${category.toUpperCase()}';
    final response = await http.get(Uri.parse(url));
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> getCommerceById(String id) async {
    final response = await http.get(Uri.parse('$_baseUrl/commerces/$id'));
    return _processResponse(response);
  }

  // --- MÉTODOS PARA EVENTOS ---
  static Future<List<dynamic>> getEvents() async {
    final response = await http.get(Uri.parse('$_baseUrl/events'));
    return _processResponse(response);
  }

  
static Future<Map<String, dynamic>> getEventById(String eventId) async {
  // Construye la URL final para el endpoint específico del evento
  final url = '$_baseUrl/events/$eventId';

  try {
    // Realiza la petición GET. Como es una lectura pública, no necesita
    // pasar por _makeAuthenticatedRequest.
    final response = await http.get(Uri.parse(url));

    // Utiliza tu procesador de respuestas centralizado para manejar
    // el éxito, los errores y el parsing del JSON.
    return _processResponse(response);

  } catch (e) {
    // Si la petición http.get falla (ej. sin conexión), lo capturamos
    // y lo relanzamos como una ApiException para ser consistentes.
    if (e is ApiException) rethrow;
    throw ApiException(
      message: 'Error de conexión al obtener el evento: ${e.toString()}',
      statusCode: 503, // Service Unavailable
    );
  }
}

  static Future<Map<String, dynamic>> updateEvent(
    int eventId,
    Map<String, dynamic> data,
  ) async {
    final response = await _makeAuthenticatedRequest(
      (headers) => http.put(
        Uri.parse('$_baseUrl/events/$eventId'),
        headers: headers,
        body: json.encode(data),
      ),
    );
    return _processResponse(response);
  }

  // --- MÉTODOS PARA ARTÍCULOS ---
  static Future<List<dynamic>> getArticles() async {
    final response = await http.get(Uri.parse('$_baseUrl/articles'));
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> getArticleBySlug(String slug) async {
    final response = await http.get(Uri.parse('$_baseUrl/articles/$slug'));
    return _processResponse(response);
  }

  // --- MÉTODO PARA BÚSQUEDA ---
  static Future<List<dynamic>> search(String query) async {
    final String url = '$_baseUrl/search?q=$query';
    final response = await http.get(Uri.parse(url));
    return _processResponse(response);
  }

  // --- MÉTODOS DE AUTENTICACIÓN ---

  /// Intenta registrar un nuevo usuario.
  /// Devuelve un mapa con la respuesta exitosa o lanza un error.
  static Future<Map<String, dynamic>> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    final String url = '$_baseUrl/auth/register';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    return _processResponse(response);
  }

  /// Intenta iniciar sesión con un identificador (usuario o email) y contraseña.
  /// Devuelve un mapa con los tokens si es exitoso o lanza un error.
  static Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    final String url = '$_baseUrl/auth/login';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'identifier': identifier, 'password': password}),
    );

    return _processResponse(response);
  }

  // --- MÉTODOS DE USUARIO ---

  /// Obtiene el perfil del usuario autenticado enviando el token JWT.
  /// @param token El token de acceso del usuario.
  // Necesitamos una referencia al AuthService para este flujo
  /// Obtiene el perfil del usuario autenticado, manejando la expiración del token.
  static Future<Map<String, dynamic>> getMyProfile() async {
    final response = await _makeAuthenticatedRequest(
      (headers) => http.get(Uri.parse('$_baseUrl/users/me'), headers: headers),
    );
    return _processResponse(response);
  }

  // --- MÉTODO NUEVO Y CLAVE: REFRESH TOKEN ---

  /// Intenta obtener un nuevo access token usando el refresh token.
  /// Este es un método interno que usarán las otras funciones.
  // --- MÉTODO NUEVO PARA REFRESCAR EL TOKEN ---
  static Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final String url = '$_baseUrl/auth/refresh-token';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'refreshToken': refreshToken}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Session expired. Please login again.');
    }
  }

  // --- MÉTODOS PARA COMERCIOS (PROTEGIDOS) ---

  /// Obtiene LOS comercios del usuario autenticado, manejando la expiración del token.
static Future<List<dynamic>> getMyCommerces() async { // <-- Nombre y tipo de retorno cambiados
  final response = await _makeAuthenticatedRequest(
    (headers) =>
        http.get(Uri.parse('$_baseUrl/commerces/me'), headers: headers),
  );
  // El backend debe devolver un array de comercios, incluso si solo hay uno.
  return _processResponse(response);
}

  /// Crea un nuevo comercio.
  static Future<Map<String, dynamic>> createCommerce(
    Map<String, dynamic> data,
  ) async {
    final response = await _makeAuthenticatedRequest(
      (headers) => http.post(
        Uri.parse('$_baseUrl/commerces'),
        headers: headers,
        body: json.encode(data),
      ),
    );
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> updateMyCommerce(
    Map<String, dynamic> data,
  ) async {
    final response = await _makeAuthenticatedRequest(
      (headers) => http.put(
        Uri.parse('$_baseUrl/commerces/me'),
        headers: headers,
        body: json.encode(data),
      ),
    );
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> createEvent(
    Map<String, dynamic> data,
  ) async {
    final response = await _makeAuthenticatedRequest(
      (headers) => http.post(
        Uri.parse('$_baseUrl/events'),
        headers: headers,
        body: json.encode(data),
      ),
    );
    return _processResponse(response);
  }


static Future<String> uploadImage(XFile imageFile) async {
  final url = Uri.parse('$_baseUrl/upload/image'); // La nueva ruta del backend
  
  // Usamos _makeAuthenticatedRequest para que el token se gestione automáticamente
  final response = await _makeAuthenticatedRequest(
    (headers) async {
      final request = http.MultipartRequest('POST', url);
      request.headers.addAll(headers);
      
      // Adjuntamos el archivo
      request.files.add(
        await http.MultipartFile.fromPath(
          'image', // Este es el nombre del campo que espera Multer: upload.single('image')
          imageFile.path,
        ),
      );
      
      final streamedResponse = await request.send();
      return http.Response.fromStream(streamedResponse);
    },
  );

  // Procesamos la respuesta
  final responseData = _processResponse(response);
  return responseData['imageUrl'];
}





// --- MÉTODOS PARA ARTÍCULOS (PROTEGIDOS) ---

/// Crea un nuevo artículo. Requiere autenticación de admin.
static Future<Map<String, dynamic>> createArticle(Map<String, dynamic> data) async {
  final response = await _makeAuthenticatedRequest(
    (headers) => http.post(
      Uri.parse('$_baseUrl/articles'),
      headers: headers,
      body: json.encode(data),
    ),
  );
  return _processResponse(response);
}

/// Actualiza un artículo existente por su ID. Requiere autenticación de admin.
static Future<Map<String, dynamic>> updateArticle(int id, Map<String, dynamic> data) async {
  final response = await _makeAuthenticatedRequest(
    (headers) => http.put(
      Uri.parse('$_baseUrl/articles/$id'),
      headers: headers,
      body: json.encode(data),
    ),
  );
  return _processResponse(response);
}


// --- MÉTODOS PARA ARTÍCULOS (PÚBLICOS) ---
static Future<List<dynamic>> getArticleCategories() async {
  final response = await http.get(Uri.parse('$_baseUrl/articles/categories'));
  return _processResponse(response);
}

// --- MÉTODOS PARA ARTÍCULOS (ADMIN) ---
static Future<List<dynamic>> getAllArticlesForAdmin() async {
  final response = await _makeAuthenticatedRequest(
    (headers) => http.get(Uri.parse('$_baseUrl/articles/manage/all'), headers: headers),
  );
  return _processResponse(response);
}

}
