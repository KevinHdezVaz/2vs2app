// lib/services/user_service.dart
import 'dart:convert';
import 'package:Frutia/services/storage_service.dart';
import 'package:Frutia/utils/constantes.dart';
import 'package:http/http.dart' as http;

class UserService {
  static final StorageService _storage = StorageService();

  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /**
   * Obtener perfil del usuario con estadísticas
   */
  static Future<Map<String, dynamic>> getUserProfile() async {
    print('[UserService] Obteniendo perfil del usuario...');
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/profile'),
        headers: await getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        print('[UserService] Perfil obtenido exitosamente');
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener perfil del usuario');
      }
    } catch (e) {
      print('[UserService] Excepción: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  /**
   * Eliminar cuenta del usuario
   */
  static Future<void> deleteAccount() async {
    print('[UserService] Eliminando cuenta del usuario...');
    
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/user/account'),
        headers: await getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        print('[UserService] Cuenta eliminada exitosamente');
        // Limpiar datos locales
        await _storage.removeToken();
        return;
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Error al eliminar cuenta');
      }
    } catch (e) {
      print('[UserService] Excepción: $e');
      throw Exception('Error de conexión: $e');
    }
  }
}