import 'dart:convert';
import 'package:Frutia/services/storage_service.dart';
import 'package:Frutia/utils/constantes.dart';
import 'package:http/http.dart' as http;

class RachaProgresoService {
  static final StorageService _storage = StorageService();

  /// Obtiene los datos del usuario y su perfil, incluyendo el historial de rachas.
  static Future<Map<String, dynamic>> getProgresoWithUser() async {
    print('[RachaProgresoService] Iniciando obtención de progreso completo...');
    final token = await _storage.getToken();
    if (token == null) {
      print('[RachaProgresoService] Error: Token no encontrado.');
      throw Exception('Usuario no autenticado.');
    }

    try {
      // Este endpoint ahora devuelve el usuario y el perfil con el historial.
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print(
          '[RachaProgresoService] Respuesta recibida. Status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        print(
            '[RachaProgresoService] Progreso completo obtenido exitosamente.');
        // Devuelve el objeto JSON completo: {'user': ..., 'profile': ...}
        return json.decode(response.body);
      } else {
        print(
            '[RachaProgresoService] Error al obtener el progreso desde el servidor.');
        throw Exception(
            'Error al obtener progreso. Código: ${response.statusCode}');
      }
    } catch (e) {
      print('[RachaProgresoService] Excepción al obtener progreso: $e');
      throw Exception('Error de conexión al obtener progreso: $e');
    }
  }

  /// Envía la señal al backend de que el usuario ha completado su día.
  static Future<Map<String, dynamic>> marcarDiaCompleto() async {
    print('[RachaProgresoService] Iniciando marcado de día completo...');
    final token = await _storage.getToken();
    if (token == null) {
      print('[RachaProgresoService] Error: Token no encontrado.');
      throw Exception('Usuario no autenticado.');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/streak/complete-day'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print(
          '[RachaProgresoService] Respuesta de marcar día recibida. Status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        print(
            '[RachaProgresoService] Día marcado y racha actualizada exitosamente.');
        return json.decode(response.body);
      } else {
        print(
            '[RachaProgresoService] Error en la respuesta del servidor al marcar el día.');
        try {
          final errorBody = json.decode(response.body);
          throw Exception(
              errorBody['message'] ?? 'Error al actualizar la racha.');
        } catch (e) {
          throw Exception(
              'Error al actualizar la racha. Código: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('[RachaProgresoService] Excepción al marcar el día: $e');
      throw Exception('Error de conexión al marcar el día: $e');
    }
  }
}
