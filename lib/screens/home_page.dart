import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pandora_app/services/auth_services.dart';
import 'package:pandora_app/widgets/animated_background.dart'; // Importamos el fondo
import 'package:pandora_app/widgets/category_card.dart';
import 'package:pandora_app/screens/commerce_list_page.dart';
import 'package:pandora_app/screens/events_page.dart';
import 'package:pandora_app/screens/search_results_page.dart';
import 'package:pandora_app/screens/login_page.dart';
import 'package:pandora_app/screens/register_page.dart';
import 'package:pandora_app/screens/profile_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Consumer<AuthService>(
          builder: (context, authService, child) {
            // Toda la lógica del AppBar ahora va DENTRO del builder.
            return AppBar(
              title: const Text(
                'Pandora',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                // --- AQUÍ VIENE LA LÓGICA CONDICIONAL ---

                // Si el usuario ESTÁ autenticado...
                if (authService.isAuthenticated)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: IconButton(
                      icon: const Icon(Icons.person),
                      tooltip: 'Mi Perfil',
                      onPressed: () {
                        // NAVEGAMOS A LA PANTALLA DE PERFIL
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfilePage(),
                          ),
                        );
                      },
                    ),
                  )
                // Si NO está autenticado...
                else
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'Ingresar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFff00c8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Registrarse'),
                        ),
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          const Text(
            'Todo en un',
            style: TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w300,
              color: Colors.white,
            ),
          ),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFFff00c8), Color(0xFFc738dd)],
            ).createShader(b),
            child: const Text(
              'solo lugar',
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Descubrí los mejores eventos, la gastronomía más exquisita y la vida nocturna de tu ciudad.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 30),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.0,
             children: [
              _buildNavigableCategory(
                context,
                title: 'Vida\nNocturna',
                icon: Icons.nightlife,
                categoryKey: 'VIDA_NOCTURNA', // <-- CLAVE CORRECTA
              ),
              _buildNavigableCategory(
                context,
                title: 'Gastronomía',
                icon: Icons.restaurant,
                categoryKey: 'GASTRONOMIA', // <-- CLAVE CORRECTA
              ),
              _buildNavigableCategory(
                context,
                title: 'Salas y\nTeatro',
                icon: Icons.theater_comedy,
                categoryKey: 'SALAS_Y_TEATRO', // <-- CLAVE CORRECTA
              ),
            ],
          ),
          const SizedBox(height: 30),
          TextField(
            style: const TextStyle(color: Colors.white, fontSize: 16),
            // El evento que se dispara cuando el usuario presiona "Enter" o el botón de buscar
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchResultsPage(query: value),
                  ),
                );
              }
            },
            decoration: InputDecoration(
              hintText: 'Buscá algo especial...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.white.withOpacity(0.7),
              ),
              filled: true,
              fillColor: const Color(0xFF8a2be2).withOpacity(0.15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          // --- BOTÓN PARA IR A LA AGENDA DE EVENTOS ---
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: ActionChip(
                label: const Text('Ver Agenda de Eventos'),
                avatar: const Icon(Icons.calendar_today, size: 16),
                backgroundColor: const Color(0xFFff00c8).withOpacity(0.2),
                labelStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EventsPage()),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Helper para la navegación. Envuelve la tarjeta en un GestureDetector.
  Widget _buildNavigableCategory(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String categoryKey,
  }) {
    return CategoryCard(
      title: title,
      iconData: icon,
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CommerceListPage(category: categoryKey.replaceAll('\n', ' ')),
          ),
        );
      },
    );
  }
}
