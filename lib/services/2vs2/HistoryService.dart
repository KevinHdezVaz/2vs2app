import 'dart:convert';
import 'package:Frutia/utils/constantes.dart';
import 'package:http/http.dart' as http;
import 'package:Frutia/services/storage_service.dart';

class HistoryService {
  static final StorageService _storage = StorageService();

  static Future<List<dynamic>> getHistory() async {
    print('[HistoryService] Iniciando getHistory()');
    
    final token = await _storage.getToken();
    
    if (token == null) {
      print('[HistoryService] ERROR: Token no encontrado');
      throw Exception('Usuario no autenticado');
    }

    print('[HistoryService] Token obtenido: ${token.substring(0, 20)}...');
    print('[HistoryService] URL: $baseUrl/sessions/history');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sessions/history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('[HistoryService] Status Code: ${response.statusCode}');
      print('[HistoryService] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('[HistoryService] Sesiones encontradas: ${data['sessions']?.length ?? 0}');
        return data['sessions'] ?? [];
      } else if (response.statusCode == 404) {
        print('[HistoryService] ERROR 404: Endpoint no encontrado');
        throw Exception('Endpoint no encontrado - verifica rutas en Laravel');
      } else if (response.statusCode == 401) {
        print('[HistoryService] ERROR 401: No autorizado');
        throw Exception('Token inválido o expirado');
      } else {
        print('[HistoryService] ERROR ${response.statusCode}');
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('[HistoryService] Excepción capturada: $e');
      rethrow;
    }
  }

  // ==================== OBTENER BORRADORES (DRAFTS) ====================
static Future<List<dynamic>> getDrafts() async {
  print('[HistoryService] Iniciando getDrafts()');
  final token = await _storage.getToken();
  if (token == null) {
    print('[HistoryService] ERROR: Token no encontrado');
    throw Exception('Usuario no autenticado');
  }

  print('[HistoryService] Token obtenido: ${token.substring(0, 20)}...');
  print('[HistoryService] URL: $baseUrl/drafts');

  try {
    final response = await http.get(
      Uri.parse('$baseUrl/drafts'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print('[HistoryService] Status Code: ${response.statusCode}');
    print('[HistoryService] Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('[HistoryService] Borradores encontrados: ${data['drafts']?.length ?? 0}');
      return data['drafts'] ?? [];
    } else if (response.statusCode == 404) {
      print('[HistoryService] INFO: No hay borradores');
      return [];
    } else if (response.statusCode == 401) {
      print('[HistoryService] ERROR 401: No autorizado');
      throw Exception('Token inválido o expirado');
    } else {
      print('[HistoryService] ERROR ${response.statusCode}');
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  } catch (e) {
    print('[HistoryService] Excepción capturada: $e');
    rethrow;
  }
}

  static Future<List<dynamic>> getAllPlayers() async {
    print('[HistoryService] Iniciando getAllPlayers()');
    
    final token = await _storage.getToken();
    
    if (token == null) {
      print('[HistoryService] ERROR: Token no encontrado');
      throw Exception('Usuario no autenticado');
    }

    print('[HistoryService] Token obtenido: ${token.substring(0, 20)}...');
    print('[HistoryService] URL: $baseUrl/players/all');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/players/all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('[HistoryService] Status Code: ${response.statusCode}');
      print('[HistoryService] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('[HistoryService] Jugadores encontrados: ${data['players']?.length ?? 0}');
        return data['players'] ?? [];
      } else if (response.statusCode == 404) {
        print('[HistoryService] ERROR 404: Endpoint no encontrado');
        throw Exception('Endpoint no encontrado - verifica rutas en Laravel');
      } else if (response.statusCode == 401) {
        print('[HistoryService] ERROR 401: No autorizado');
        throw Exception('Token inválido o expirado');
      } else {
        print('[HistoryService] ERROR ${response.statusCode}');
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('[HistoryService] Excepción capturada: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getPlayerDetail(int playerId) async {
    print('[HistoryService] Iniciando getPlayerDetail() - Player ID: $playerId');
    
    final token = await _storage.getToken();
    
    if (token == null) {
      print('[HistoryService] ERROR: Token no encontrado');
      throw Exception('Usuario no autenticado');
    }

    print('[HistoryService] Token obtenido: ${token.substring(0, 20)}...');
    print('[HistoryService] URL: $baseUrl/players/$playerId');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/players/$playerId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('[HistoryService] Status Code: ${response.statusCode}');
      print('[HistoryService] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        print('[HistoryService] ERROR 404: Jugador no encontrado');
        throw Exception('Jugador no encontrado');
      } else if (response.statusCode == 401) {
        print('[HistoryService] ERROR 401: No autorizado');
        throw Exception('Token inválido o expirado');
      } else if (response.statusCode == 403) {
        print('[HistoryService] ERROR 403: Acceso denegado');
        throw Exception('No tienes permiso para ver este jugador');
      } else {
        print('[HistoryService] ERROR ${response.statusCode}');
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('[HistoryService] Excepción capturada: $e');
      rethrow;
    }
  }
}