// lib/data/mock_data.dart

// --- DATOS DE EJEMPLO PARA COMERCIOS ---
final List<Map<String, dynamic>> allCommerces = [
  {
    "id": "1",
    "name": "Parrilla Don José",
    "description": "La mejor carne de Salta, con más de 20 años de tradición familiar. Un lugar para disfrutar con amigos y familia.",
    "address": "Av. Belgrano 123, Salta Capital",
    "phone": "+54 387 4123456",
    "hours": "12:00 - 15:00, 20:00 - 00:00",
    "category": "Gastronomía",
    "imageUrl": "https://picsum.photos/seed/parrilla/800/600",
  },
  {
    "id": "2",
    "name": "Bar La Casona",
    "description": "Tragos de autor y la mejor música en un ambiente único. Ideal para empezar la noche.",
    "address": "Balcarce 900, Salta Capital",
    "phone": "+54 387 4654321",
    "hours": "19:00 - 04:00",
    "category": "Vida Nocturna",
    "imageUrl": "https://picsum.photos/seed/casona/800/600",
  },
  {
    "id": "3",
    "name": "Teatro Provincial",
    "description": "Disfruta de las mejores obras y conciertos en el teatro más emblemático de la ciudad.",
    "address": "Zuviría 70, Salta Capital",
    "phone": "+54 387 4223344",
    "hours": "Según función",
    "category": "Salas y Teatro",
    "imageUrl": "https://picsum.photos/seed/teatroprov/800/600",
  },
  {
    "id": "4",
    "name": "Café del Tiempo",
    "description": "Un rincón para disfrutar de un buen café de especialidad y pastelería artesanal.",
    "address": "Caseros 456, Salta Capital",
    "phone": "+54 387 4987654",
    "hours": "08:00 - 21:00",
    "category": "Gastronomía",
    "imageUrl": "https://picsum.photos/seed/cafe/800/600",
  },
];


// --- DATOS DE EJEMPLO PARA EVENTOS ---
final List<Map<String, dynamic>> allEvents = [
  {
    "id": "101",
    "name": "Concierto de Rock Acústico",
    "location": "Bar La Casona",
    "commerceId": "2",
    "date": "25 DIC",
    "description": "Una noche íntima con las mejores bandas de rock locales en formato acústico.",
    "imageUrl": "https://picsum.photos/seed/rock/200/200"
  },
  {
    "id": "102",
    "name": "Noche de Stand Up",
    "location": "Teatro Provincial",
    "commerceId": "3",
    "date": "26 DIC",
    "description": "Los comediantes más destacados de la región te harán reír sin parar.",
    "imageUrl": "https://picsum.photos/seed/standup/200/200"
  },
];