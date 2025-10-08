// lib/services/session_service.dart
import 'dart:convert';
import 'package:Frutia/services/storage_service.dart';
import 'package:Frutia/utils/constantes.dart';
import 'package:http/http.dart' as http;

class SessionService {
  static final StorageService _storage = StorageService();

  // ==================== SESSIONS ====================
  

static Future<Map<String, String>> getAuthHeaders() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

 

 static Future<void> generatePlayoffBracket(int sessionId) async {
  print('[SessionService] Generando bracket de playoffs para sesión: $sessionId');
  final token = await _storage.getToken();
  
  if (token == null) {
    throw Exception('Usuario no autenticado.');
  }

  try {
    final response = await http.post(
      Uri.parse('$baseUrl/sessions/$sessionId/generate-playoff-bracket'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['message'] ?? 'Error al generar bracket.');
    }
  } catch (e) {
    print('[SessionService] Excepción: $e');
    throw Exception('Error de conexión: $e');
  }
}

static Future<void> advanceStage(int sessionId) async {
  print('[SessionService] Avanzando stage para sesión: $sessionId');
  final token = await _storage.getToken();
  
  if (token == null) {
    throw Exception('Usuario no autenticado.');
  }

  try {
    final response = await http.post(
      Uri.parse('$baseUrl/sessions/$sessionId/advance-stage'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['message'] ?? 'Error al avanzar stage.');
    }
  } catch (e) {
    print('[SessionService] Excepción: $e');
    throw Exception('Error de conexión: $e');
  }
}


// Método para espectadores (sin autenticación)
static Future<List<dynamic>> getPublicActiveSessions() async {
  final url = Uri.parse('$baseUrl/public/sessions/active');
  
  final response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['sessions'] ?? [];
  } else {
    throw Exception('Error al obtener sesiones públicas');
  }
}

static Future<Map<String, dynamic>> getPublicSession(int sessionId) async {
  print('[SessionService] Obteniendo sesión pública con ID: $sessionId');
  
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/public/sessions/$sessionId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener sesión.');
    }
  } catch (e) {
    print('[SessionService] Excepción: $e');
    throw Exception('Error de conexión: $e');
  }
}

static Future<List<dynamic>> getPublicGamesByStatus(int sessionId, String status) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/public/sessions/$sessionId/games/$status'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['games'] ?? [];
    } else {
      throw Exception('Error al obtener juegos.');
    }
  } catch (e) {
    throw Exception('Error de conexión: $e');
  }
}

static Future<List<dynamic>> getPublicPlayerStats(int sessionId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/public/sessions/$sessionId/players'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['players'] ?? [];
    } else {
      throw Exception('Error al obtener estadísticas.');
    }
  } catch (e) {
    throw Exception('Error de conexión: $e');
  }
}



  static Future<Map<String, dynamic>> joinWithCode(String code) async {
    final url = Uri.parse('$baseUrl/sessions/join/$code');
    
    final response = await http.post(
      url,
      headers: await getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Código inválido o expirado');
    }
  }

 static Future<Map<String, dynamic>> getSessionRole(int sessionId) async {
    final url = Uri.parse('$baseUrl/sessions/$sessionId/role');
    
    final response = await http.get(
      url,
      headers: await getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al verificar permisos');
    }
  }


 static Future<Map<String, dynamic>> createSession(Map<String, dynamic> sessionData) async {
  print('[SessionService] Starting session creation...');
  final token = await _storage.getToken();
  
  if (token == null) {
    print('[SessionService] Error: Token not found.');
    throw Exception('User not authenticated.');
  }

  try {
    final response = await http.post(
      Uri.parse('$baseUrl/sessions'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(sessionData),
    );

    print('[SessionService] Response received. Status code: ${response.statusCode}');
    print('[SessionService] Response body: ${response.body}');

    if (response.statusCode == 201) {
      print('[SessionService] Session created successfully.');
      return json.decode(response.body);
    } else {
      // ✅ Extraer el mensaje exacto del backend
      try {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['message'] ?? 'Error creating session.';
        print('[SessionService] Backend error: $errorMessage');
        
        // ✅ Lanzar excepción con el mensaje exacto (sin agregar texto adicional)
        throw Exception(errorMessage);
      } catch (e) {
        if (e is Exception && e.toString().contains('Exception:')) {
          // Si ya es una excepción formateada, relanzarla
          rethrow;
        }
        // Si no se puede decodificar, usar código de estado
        throw Exception('Error creating session. Status code: ${response.statusCode}');
      }
    }
  } catch (e) {
    print('[SessionService] Exception creating session: $e');
    
    // ✅ Si es una excepción que ya tiene el mensaje del backend, relanzarla sin modificar
    if (e is Exception && e.toString().contains('Exception:')) {
      rethrow;
    }
    
    // Para errores de conexión, mantener mensaje genérico
    throw Exception('Connection error: $e');
  }
}
  
  
  static Future<Map<String, dynamic>> startSession(int sessionId) async {
  print('[SessionService] Starting session with ID: $sessionId');
  final token = await _storage.getToken();
  
  if (token == null) {
    throw Exception('User not authenticated.');
  }

  try {
    final response = await http.post(
      Uri.parse('$baseUrl/sessions/$sessionId/start'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('[SessionService] Start response. Status code: ${response.statusCode}');

    if (response.statusCode == 200) {
      print('[SessionService] Session started successfully.');
      return json.decode(response.body);
    } else {
      try {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Error starting session.');
      } catch (e) {
        if (e is Exception && e.toString().contains('Exception:')) {
          rethrow;
        }
        throw Exception('Error starting session. Status code: ${response.statusCode}');
      }
    }
  } catch (e) {
    print('[SessionService] Exception starting session: $e');
    if (e is Exception && e.toString().contains('Exception:')) {
      rethrow;
    }
    throw Exception('Connection error: $e');
  }
}


  static Future<Map<String, dynamic>> getSession(int sessionId) async {
    print('[SessionService] Obteniendo sesión con ID: $sessionId');
    final token = await _storage.getToken();
    
    if (token == null) {
      throw Exception('Usuario no autenticado.');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sessions/$sessionId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener sesión.');
      }
    } catch (e) {
      print('[SessionService] Excepción: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<List<dynamic>> getActiveSessions() async {
    print('[SessionService] Obteniendo sesiones activas...');
    final token = await _storage.getToken();
    
    if (token == null) {
      throw Exception('Usuario no autenticado.');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sessions/active'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['sessions'] ?? [];
      } else {
        throw Exception('Error al obtener sesiones activas.');
      }
    } catch (e) {
      print('[SessionService] Excepción: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<List<dynamic>> getGamesByStatus(int sessionId, String status) async {
    print('[SessionService] Obteniendo juegos con status: $status');
    final token = await _storage.getToken();
    
    if (token == null) {
      throw Exception('Usuario no autenticado.');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sessions/$sessionId/games/$status'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['games'] ?? [];
      } else {
        throw Exception('Error al obtener juegos.');
      }
    } catch (e) {
      print('[SessionService] Excepción: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<List<dynamic>> getPlayerStats(int sessionId) async {
    print('[SessionService] Obteniendo estadísticas de jugadores...');
    final token = await _storage.getToken();
    
    if (token == null) {
      throw Exception('Usuario no autenticado.');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sessions/$sessionId/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['players'] ?? [];
      } else {
        throw Exception('Error al obtener estadísticas.');
      }
    } catch (e) {
      print('[SessionService] Excepción: $e');
      throw Exception('Error de conexión: $e');
    }
  
  
    
    
    }
  }

// lib/services/game_service.dart
class GameService {
  static final StorageService _storage = StorageService();

// En tu GameService.dart, agrega:

// Reemplaza el método skipToCourt en tu GameService:

// Reemplaza el método skipToCourt en tu GameService:

static Future<void> skipToCourt(int gameId) async {
  print('[GameService] Saltando juego a cancha ID: $gameId');
  final token = await _storage.getToken();
  
  if (token == null) {
    throw Exception('Usuario no autenticado.');
  }

  final response = await http.post(
    Uri.parse('$baseUrl/games/$gameId/skip-to-court'),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    print('[GameService] Juego saltado a cancha exitosamente');
    return;
  }

  // Capturar el mensaje específico del backend
  String errorMessage = 'Error al saltar juego a cancha.';
  try {
    final errorBody = json.decode(response.body);
    errorMessage = errorBody['message'] ?? errorMessage;
  } catch (_) {
    // Si no se puede decodificar, usar mensaje por defecto
  }
  
  print('[GameService] Error del servidor: $errorMessage');
  throw Exception(errorMessage);
}

static Future<Map<String, dynamic>> updateScore(
    int gameId,
    int team1Score,
    int team2Score,
  ) async {
    print('[GameService] Actualizando score para juego ID: $gameId');
    final token = await _storage.getToken();
    if (token == null) {
      throw Exception('Usuario no autenticado.');
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/games/$gameId/update-score'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'team1_score': team1Score,
          'team2_score': team2Score,
        }),
      );

      if (response.statusCode == 200) {
        print('[GameService] Score actualizado exitosamente.');
        return json.decode(response.body);
      } else {
        try {
          final errorBody = json.decode(response.body);
          throw Exception(errorBody['message'] ?? 'Error al actualizar score.');
        } catch (e) {
          throw Exception('Error al actualizar score. Código: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('[GameService] Excepción: $e');
      throw Exception('Error de conexión: $e');
    }
  }



  static Future<Map<String, dynamic>> startGame(int gameId) async {
    print('[GameService] Iniciando juego ID: $gameId');
    final token = await _storage.getToken();
    
    if (token == null) {
      throw Exception('Usuario no autenticado.');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/games/$gameId/start'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al iniciar juego.');
      }
    } catch (e) {
      print('[GameService] Excepción: $e');
      throw Exception('Error de conexión: $e');
    }
  }
static Future<Map<String, dynamic>> submitScore(
  int gameId,
  int team1Score,
  int team2Score, {
  int? team1Sets,
  int? team2Sets,
}) async {
  print('🔹 [GameService] Enviando score para juego ID: $gameId');

  final token = await _storage.getToken();

  if (token == null) {
    throw Exception('❌ Usuario no autenticado.');
  }

  try {
    final body = {
      'team1_score': team1Score,
      'team2_score': team2Score,
    };

    if (team1Sets != null) body['team1_sets_won'] = team1Sets;
    if (team2Sets != null) body['team2_sets_won'] = team2Sets;

    final url = Uri.parse('$baseUrl/games/$gameId/score');
    print('📤 [GameService] POST -> $url');
    print('📦 Body -> ${jsonEncode(body)}');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    print('📥 [GameService] Respuesta recibida -> ${response.statusCode}');
    print('🧾 Headers -> ${response.headers}');
    print('📃 Body -> ${response.body}');

    if (response.statusCode == 200) {
      print('✅ [GameService] Score registrado exitosamente.');
      return json.decode(response.body);
    } else {
      try {
        final errorBody = json.decode(response.body);
        final message = errorBody['message'] ??
            errorBody['error'] ??
            errorBody.toString();
        print('⚠️ [GameService] Error del backend: $message');
        throw Exception('Error al registrar score: $message');
      } catch (e) {
        print('❌ [GameService] Error al parsear respuesta: ${response.body}');
        throw Exception(
            'Error al registrar score. Código: ${response.statusCode}');
      }
    }
  } catch (e, stackTrace) {
    print('💥 [GameService] Excepción capturada: $e');
    print('🧩 StackTrace:\n$stackTrace');
    throw Exception('Error de conexión o inesperado: $e');
  }
}

  static Future<void> cancelGame(int gameId) async {
    print('[GameService] Cancelando juego ID: $gameId');
    final token = await _storage.getToken();
    
    if (token == null) {
      throw Exception('Usuario no autenticado.');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/games/$gameId/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Error al cancelar juego.');
      }
    } catch (e) {
      print('[GameService] Excepción: $e');
      throw Exception('Error de conexión: $e');
    }
  }
}