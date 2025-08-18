// Importaciones
import 'package:flutter/material.dart';
import 'package:pandora_app/services/api_service.dart';
import 'package:pandora_app/services/auth_services.dart';
import 'package:pandora_app/widgets/error_display.dart';
import 'package:provider/provider.dart';
import 'package:pandora_app/screens/my_commerce_page.dart';
import 'package:pandora_app/screens/create_commerce_page.dart';
import 'package:pandora_app/screens/login_page.dart';

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
    setState(() {
      _profileFuture = ApiService.getMyProfile();
    });
  }

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

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (!authService.isAuthenticated) {
          return Scaffold(
            appBar: AppBar(title: const Text('Mi Perfil')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Para ver tu perfil, por favor, inicia sesión.',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    child: const Text('Iniciar Sesión'),
                  ),
                ],
              ),
            ),
          );
        }

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
              } else if (!snapshot.hasData || snapshot.data == null) {
                return const Center(
                  child: Text('No se encontraron datos del perfil.'),
                );
              }

              final user = snapshot.data!;
              return ListView(
                padding: const EdgeInsets.all(20.0),
                children: [
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
                          user['name'] ?? 'Nombre no disponible',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@${user['username'] ?? ''}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 40, color: Colors.white24),
                  _buildProfileInfoTile(
                    Icons.email_outlined,
                    'Email',
                    user['email'] ?? 'Email no disponible',
                  ),
                  _buildProfileInfoTile(
                    Icons.shield_outlined,
                    'Tipo de Cuenta',
                    _getRoleDisplayName(user['role'] ?? 'USER'),
                  ),
                  const Divider(height: 40, color: Colors.white24),
                  if (user['role'] == 'OWNER')
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyCommercesPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.storefront),
                      label: const Text('Gestionar mi Comercio'),
                    ),
                  if (user['role'] == 'USER')
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreateCommercePage(),
                          ),
                        );
                        if (result == true && mounted) {
                          _loadProfileData();
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
                  ElevatedButton.icon(
                    onPressed: () {
                      authService.logout();
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
            },
          ),
        );
      },
    );
  }
}
