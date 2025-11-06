// lib/model/2vs2p/SessionData.dart

class SessionData {
  // Detalles básicos
  String sessionName = '';
  int numberOfCourts = 1;
  int durationHours = 2;
  int numberOfPlayers = 6;

  // Configuración del juego
  int pointsPerGame = 11;
  int winBy = 2;
  String numberOfSets = '1';

  // Tipo de sesión
  String sessionType = 'S';

  // Canchas
  List<String> courtNames = [];

  // Jugadores
  List<PlayerData> players = [];

  // Constructor por defecto
  SessionData();

  // Constructor fromJson
  SessionData.fromJson(Map<String, dynamic> json) {
    sessionName = json['session_name'] ?? '';
    numberOfCourts = json['number_of_courts'] ?? 1;
    durationHours = json['duration_hours'] ?? 2;
    numberOfPlayers = json['number_of_players'] ?? 6;
    pointsPerGame = json['points_per_game'] ?? 11;
    winBy = json['win_by'] ?? 2;
    numberOfSets = json['number_of_sets']?.toString() ?? '1';
    sessionType = json['session_type'] ?? 'P4';

    // Cargar canchas
    if (json['courts'] != null && json['courts'] is List) {
      courtNames = (json['courts'] as List).map((court) {
        if (court is Map) {
          return court['court_name']?.toString() ?? 'Court';
        } else {
          return court.toString();
        }
      }).toList();
      print('[SessionData] Loaded ${courtNames.length} courts from JSON');
    } else {
      print('[SessionData] No courts in JSON, will initialize on demand');
    }

    // Cargar jugadores
    if (json['players'] != null && json['players'] is List) {
      players = (json['players'] as List).map((playerJson) {
        if (playerJson == null) {
          return PlayerData();
        }
        if (playerJson is Map<String, dynamic>) {
          return PlayerData.fromJson(playerJson);
        } else {
          print('[SessionData] Unexpected player format: $playerJson');
          return PlayerData();
        }
      }).toList();

      print('[SessionData] ✅ Loaded ${players.length} players from JSON:');
      for (var i = 0; i < players.length; i++) {
        print('   Player ${i + 1}: "${players[i].firstName}" "${players[i].lastInitial}"');
      }
    } else {
      print('[SessionData] No players in JSON, will initialize on demand');
    }

    print('[SessionData] SessionData.fromJson() complete');
  }

  // ✅ MÉTODO SEGURO: Inicializar canchas solo si están vacías
  void initializeCourts() {
    if (courtNames.isNotEmpty && courtNames.length == numberOfCourts) {
      print('[SessionData] Courts already initialized, skipping...');
      return;
    }

    print('[SessionData] Initializing ${numberOfCourts} courts...');
    courtNames = List.generate(
      numberOfCourts,
      (index) => 'Court ${index + 1}',
    );
  }

  // ✅ MÉTODO SEGURO: Ajustar jugadores sin perder datos
  void initializePlayers() {
    // Si ya hay jugadores con datos, solo ajustar el tamaño
    final hasData = players.any((p) => p.firstName.isNotEmpty);
    
    if (hasData) {
      print('[SessionData] ⚠️ Players have data! Adjusting size only...');
      
      // Agregar jugadores vacíos si faltan
      while (players.length < numberOfPlayers) {
        players.add(PlayerData());
        print('   Added empty player #${players.length}');
      }
      
      // Recortar si hay de más
      if (players.length > numberOfPlayers) {
        final removed = players.length - numberOfPlayers;
        players = players.sublist(0, numberOfPlayers);
        print('   Removed $removed extra players');
      }
      
      print('[SessionData] ✅ Players adjusted: ${players.length} players');
      return;
    }

    // Si la lista está vacía o sin datos, inicializar nuevos jugadores
    if (players.isEmpty || players.length != numberOfPlayers) {
      print('[SessionData] Initializing ${numberOfPlayers} empty players...');
      players = List.generate(
        numberOfPlayers,
        (index) => PlayerData(),
      );
    } else {
      print('[SessionData] Players already initialized (${players.length}), skipping...');
    }
  }

  // Convertir a JSON
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
      'courts': courtNames
          .asMap()
          .entries
          .map((entry) => {
                'court_name': entry.value,
                'court_number': entry.key + 1,
              })
          .toList(),
      'players': players.map((p) => p.toJson()).toList(),
    };
  }
}

class PlayerData {
  String firstName;
  String lastInitial;
  String level;
  String dominantHand;

  PlayerData({
    this.firstName = '',
    this.lastInitial = '',
    this.level = 'Average',
    this.dominantHand = 'None',
  });

  factory PlayerData.fromJson(Map<String, dynamic> json) {
    return PlayerData(
      firstName: json['first_name']?.toString() ?? '',
      lastInitial: json['last_initial']?.toString() ?? '',
      level: json['level']?.toString() ?? 'Average',
      dominantHand: json['dominant_hand']?.toString() ?? 'None',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_initial': lastInitial,
      'level': level,
      'dominant_hand': dominantHand,
    };
  }
}
 