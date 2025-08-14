import 'package:flutter/material.dart';
import 'package:pandora_app/services/api_service.dart';
import 'package:pandora_app/services/auth_services.dart';
import 'package:pandora_app/widgets/error_display.dart';
import 'package:provider/provider.dart';

import 'package:pandora_app/screens/my_commerce_page.dart';
import 'package:pandora_app/screens/create_commerce_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    // Usamos Provider para obtener el token del usuario actual.
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = authService.token;

    // Si no hay token, no deberíamos estar en esta página, pero es una buena práctica validarlo.
    if (token != null) {
      setState(() {
        _profileFuture = ApiService.getMyProfile();
      });
    }
  }

  // --- HELPER PARA TRADUCIR ROLES ---
  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'USER':
        return 'Consumidor';
      case 'OWNER':
        return 'Propietario de Negocio';
      case 'ADMIN':
        return 'Administrador';
      default:
        return 'Usuario';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos el Consumer para acceder fácilmente al AuthService en el build.
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return ErrorDisplay(
              message: 'No se pudo cargar tu perfil.',
              onRetry: _loadProfileData,
            );
          } else if (!snapshot.hasData) {
            return const Center(
              child: Text('No se encontraron datos del perfil.'),
            );
          } else {
            final user = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                // Avatar e información principal
                Center(
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Color(0xFF8a2be2),
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user['name'],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${user['username']}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 40, color: Colors.white24),

                // Detalles del perfil
                _buildProfileInfoTile(
                  Icons.email_outlined,
                  'Email',
                  user['email'],
                ),
                // Usamos la función para mostrar el nombre amigable del rol
                _buildProfileInfoTile(
                  Icons.shield_outlined,
                  'Tipo de Cuenta',
                  _getRoleDisplayName(user['role']),
                ),
                const Divider(height: 40, color: Colors.white24),

                // --- SECCIÓN CONDICIONAL PARA OWNERS Y USERS ---
                // Aquí irá la lógica para "Gestionar Comercio" o "Crear Comercio"
                // Si el usuario es OWNER, muestra el botón para gestionar su comercio
                if (user['role'] == 'OWNER')
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyCommercePage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.storefront),
                    label: const Text('Gestionar mi Comercio'),
                  ),

                // Si el usuario es USER, muestra el botón para registrar uno
                if (user['role'] == 'USER')
                  OutlinedButton.icon(
                    onPressed: () async {
                      // 1. Asegurarse de que sea async
                      // 2. Navegamos y ESPERAMOS a que la página se cierre
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateCommercePage(),
                        ),
                      );

                      // 3. Si la página de creación nos devuelve 'true' (o cualquier valor),
                      //    forzamos una recarga de los datos del perfil.
                      if (result == true && mounted) {
                        _loadProfileData(); // Esta es la función que llama a la API de nuevo
                      }
                    },
                    icon: const Icon(Icons.add_business),
                    label: const Text('¿Tenés un negocio? ¡Registralo!'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFc738dd)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),

                const SizedBox(height: 20),
                // Botón de Cerrar Sesión
                ElevatedButton.icon(
                  onPressed: () {
                    authService.logout();
                    // Cerramos la pantalla de perfil y volvemos a la HomePage
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar Sesión'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  // Widget helper para mostrar la información del perfil
  Widget _buildProfileInfoTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.white.withOpacity(0.8)),
      ),
    );
  }
}
