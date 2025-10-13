// lib/model/2vs2p/SessionData.dart
class SessionData {
  // Detalles básicos
  String sessionName = '';
  int numberOfCourts = 1;
  int durationHours = 2;
  int numberOfPlayers = 4;
  
  // Configuración del juego
  int pointsPerGame = 11;
  int winBy = 2;
  String numberOfSets = '1';
  
  // Tipo de sesión
  String sessionType = 'P4'; // T, P4, P8
  
  // Canchas
  List<String> courtNames = [];
  
  // Jugadores
  List<PlayerData> players = [];

void initializeCourts() {
  courtNames = List.generate(
    numberOfCourts,
    (index) => 'Court ${index + 1}', // Court 1, Court 2, Court 3...
  );
}



  void initializePlayers() {
    players = List.generate(
      numberOfPlayers,
      (index) => PlayerData(),
    );
  }

  // Convertir a JSON para enviar al backend
  Map<String, dynamic> toJson() {
    return {
      'session_name': sessionName,
      'number_of_courts': numberOfCourts,
      'duration_hours': durationHours,
      'number_of_players': numberOfPlayers,
      'points_per_game': pointsPerGame,
      'win_by': winBy,
      'number_of_sets': numberOfSets,
      'session_type': sessionType,
      'courts': courtNames.asMap().entries.map((entry) => {
        'court_name': entry.value,
        'court_number': entry.key + 1,
      }).toList(),
      'players': players.map((p) => p.toJson()).toList(),
    };
  }
}

class PlayerData {
  String firstName;
  String lastInitial;
  String level;
  String dominantHand;

  // Constructor con valores por defecto
 PlayerData({
  this.firstName = '',
  this.lastInitial = '',
  this.level = 'Average',         // 👈 traducido
  this.dominantHand = 'None',     // 👈 traducido
});


  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_initial': lastInitial,
      'level': level,
      'dominant_hand': dominantHand,
    };
  }

  factory PlayerData.fromJson(Map<String, dynamic> json) {
    return PlayerData(
      firstName: json['first_name'] ?? '',
      lastInitial: json['last_initial'] ?? '',
      level: json['level'] ?? 'Promedio',
      dominantHand: json['dominant_hand'] ?? 'Ninguna',
    );
  }
}