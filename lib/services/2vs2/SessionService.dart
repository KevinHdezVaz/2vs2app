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

 

// REEMPLAZAR los métodos existentes en SessionService.dart
// REEMPLAZAR los métodos existentes en SessionService.dart
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

    if (response.statusCode == 200) {
      print('[SessionService] Bracket de playoffs generado exitosamente');
      return;
    } else {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['message'] ?? 'Error al generar bracket.');
    }
  } catch (e) {
    print('[SessionService] Excepción: $e');
    throw Exception('Error de conexión: $e');
  }
}


 static Future<Map<String, dynamic>> findSessionByCode(String code) async {
    print('[SessionService] Buscando sesión con código: $code');
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sessions/code/${code.toUpperCase()}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // NO incluir Authorization - es público
        },
      );

      if (response.statusCode == 200) {
        print('[SessionService] Sesión encontrada exitosamente');
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Session not found or not active');
      }
    } catch (e) {
      print('[SessionService] Error buscando sesión: $e');
      throw Exception('Session not found or not active');
    }
  }


  static Future<Map<String, dynamic>> finalizeSession(int sessionId) async {
  print('[SessionService] Finalizing session: $sessionId');
  final token = await _storage.getToken();
  
  if (token == null) {
    throw Exception('User not authenticated.');
  }

  try {
    final response = await http.post(
      Uri.parse('$baseUrl/sessions/$sessionId/finalize'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      print('[SessionService] Session finalized successfully');
      return json.decode(response.body);
    } else {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['message'] ?? 'Error finalizing session.');
    }
  } catch (e) {
    print('[SessionService] Exception: $e');
    throw Exception('Connection error: $e');
  }
}


static Future<void> generateP8Finals(int sessionId) async {
  print('[SessionService] Generating P8 finals for session: $sessionId');
  final token = await _storage.getToken();
  
  if (token == null) {
    throw Exception('User not authenticated.');
  }

  try {
    final response = await http.post(
      Uri.parse('$baseUrl/sessions/$sessionId/generate-p8-finals'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      print('[SessionService] P8 finals generated successfully');
      return;
    } else {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['message'] ?? 'Error generating finals.');
    }
  } catch (e) {
    print('[SessionService] Exception: $e');
    throw Exception('Connection error: $e');
  }
}

/// ✅ NUEVO: Auto-generar finals si están listas
static Future<Map<String, dynamic>> autoGenerateFinalsIfReady(int sessionId) async {
  try {
    final token = await _storage.getToken();
    if (token == null) {
      throw Exception('User not authenticated.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/sessions/$sessionId/auto-generate-finals'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('🤖 Auto-generate finals response: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('✅ Auto-generate response: $data');
      return data;
    } else {
      print('⚠️  Auto-generate returned ${response.statusCode}');
      return {
        'auto_generated': false,
        'message': 'Not ready to generate'
      };
    }
  } catch (e) {
    print('❌ Error auto-generating finals: $e');
    return {
      'auto_generated': false,
      'error': e.toString()
    };
  }
}

static Future<void> advanceToNextStage(int sessionId) async {
  print('[SessionService] Avanzando al siguiente stage para sesión: $sessionId');
  final token = await _storage.getToken();
  
  if (token == null) {
    throw Exception('Usuario no autenticado.');
  }

  try {
    final response = await http.post(
Uri.parse('$baseUrl/sessions/$sessionId/advance-to-next-stage') ,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      print('[SessionService] Stage avanzado exitosamente');
      return;
    } else {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['message'] ?? 'Error al avanzar al siguiente stage.');
    }
  } catch (e) {
    print('[SessionService] Excepción: $e');
    throw Exception('Error de conexión: $e');
  }
}

// AGREGAR método para verificar si se puede avanzar
static Future<Map<String, dynamic>> canAdvanceStage(int sessionId) async {
  print('[SessionService] Verificando si se puede avanzar para sesión: $sessionId');
  final token = await _storage.getToken();
  
  if (token == null) {
    throw Exception('Usuario no autenticado.');
  }

  try {
    final response = await http.get(
      Uri.parse('$baseUrl/sessions/$sessionId/can-advance'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al verificar avance.');
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
      throw Exception('Error, recharge the view.');
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
        throw Exception('Error, please recharge the view.');
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


  // AGREGAR ESTOS MÉTODOS AL FINAL DE LA CLASE SessionService
// EN: lib/services/session_service.dart

  /// Submit score para Best of 1 (original)
  static Future<Map<String, dynamic>> submitScore(
    int gameId,
    int team1Score,
    int team2Score,
  ) async {
    print('[SessionService] Submitting score for game: $gameId');
    final token = await _storage.getToken();
    
    if (token == null) {
      throw Exception('User not authenticated.');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/games/$gameId/score'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'team1_score': team1Score,
          'team2_score': team2Score,
        }),
      );

      if (response.statusCode == 200) {
        print('[SessionService] Score submitted successfully');
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Error submitting score.');
      }
    } catch (e) {
      print('[SessionService] Exception: $e');
      throw Exception('Connection error: $e');
    }
  }

  /// Update score para Best of 1 (original)
  static Future<Map<String, dynamic>> updateScore(
    int gameId,
    int team1Score,
    int team2Score,
  ) async {
    print('[SessionService] Updating score for game: $gameId');
    final token = await _storage.getToken();
    
    if (token == null) {
      throw Exception('User not authenticated.');
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/games/$gameId/update-score'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'team1_score': team1Score,
          'team2_score': team2Score,
        }),
      );

      if (response.statusCode == 200) {
        print('[SessionService] Score updated successfully');
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Error updating score.');
      }
    } catch (e) {
      print('[SessionService] Exception: $e');
      throw Exception('Connection error: $e');
    }
  }

  /// ✅ NUEVO: Submit score para Best of 3
  static Future<Map<String, dynamic>> submitScoreBestOf3(
    int gameId,
    int team1TotalScore,
    int team2TotalScore,
    int team1Set1Score,
    int team2Set1Score,
    int team1Set2Score,
    int team2Set2Score,
    int? team1Set3Score,
    int? team2Set3Score,
    int team1SetsWon,
    int team2SetsWon,
  ) async {
    print('[SessionService] Submitting Best of 3 score for game: $gameId');
    final token = await _storage.getToken();
    
    if (token == null) {
      throw Exception('User not authenticated.');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/games/$gameId/score'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'team1_score': team1TotalScore,
          'team2_score': team2TotalScore,
          'team1_set1_score': team1Set1Score,
          'team2_set1_score': team2Set1Score,
          'team1_set2_score': team1Set2Score,
          'team2_set2_score': team2Set2Score,
          'team1_set3_score': team1Set3Score,
          'team2_set3_score': team2Set3Score,
          'team1_sets_won': team1SetsWon,
          'team2_sets_won': team2SetsWon,
        }),
      );

      if (response.statusCode == 200) {
        print('[SessionService] Best of 3 score submitted successfully');
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Error submitting score.');
      }
    } catch (e) {
      print('[SessionService] Exception: $e');
      throw Exception('Connection error: $e');
    }
  }

  /// ✅ NUEVO: Update score para Best of 3
  static Future<Map<String, dynamic>> updateScoreBestOf3(
    int gameId,
    int team1TotalScore,
    int team2TotalScore,
    int team1Set1Score,
    int team2Set1Score,
    int team1Set2Score,
    int team2Set2Score,
    int? team1Set3Score,
    int? team2Set3Score,
    int team1SetsWon,
    int team2SetsWon,
  ) async {
    print('[SessionService] Updating Best of 3 score for game: $gameId');
    final token = await _storage.getToken();
    
    if (token == null) {
      throw Exception('User not authenticated.');
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/games/$gameId/update-score'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'team1_score': team1TotalScore,
          'team2_score': team2TotalScore,
          'team1_set1_score': team1Set1Score,
          'team2_set1_score': team2Set1Score,
          'team1_set2_score': team1Set2Score,
          'team2_set2_score': team2Set2Score,
          'team1_set3_score': team1Set3Score,
          'team2_set3_score': team2Set3Score,
          'team1_sets_won': team1SetsWon,
          'team2_sets_won': team2SetsWon,
        }),
      );

      if (response.statusCode == 200) {
        print('[SessionService] Best of 3 score updated successfully');
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Error updating score.');
      }
    } catch (e) {
      print('[SessionService] Exception: $e');
      throw Exception('Connection error: $e');
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
  
  static Future<Map<String, dynamic>> getPrimaryActiveGame(int sessionId) async {
  print('[SessionService] Getting primary active game for session: $sessionId');
  final token = await _storage.getToken();
  
  if (token == null) {
    throw Exception('User not authenticated.');
  }

  try {
    final response = await http.get(
      Uri.parse('$baseUrl/sessions/$sessionId/primary-active-game'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error getting primary active game.');
    }
  } catch (e) {
    print('[SessionService] Exception: $e');
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
      throw Exception('Error, recharge the view.');
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
        throw Exception('Error, please recharge the view.');
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