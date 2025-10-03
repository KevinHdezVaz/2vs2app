import 'dart:convert';
import 'package:Frutia/services/storage_service.dart';
import 'package:Frutia/utils/constantes.dart';
import 'package:http/http.dart' as http;

class ProfileService {
  final StorageService _storage = StorageService();

  Future<Map<String, dynamic>?> getProfile() async {
    print('[ProfileService] Initiating profile fetch...');

    final token = await _storage.getToken();
    if (token == null) {
      print('[ProfileService] Error: Token not found. User not authenticated.');
      throw Exception('User not authenticated.');
    }

    print('[ProfileService] Token obtained successfully.');

    try {
      print('[ProfileService] Making request to $baseUrl/profile...');
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print(
          '[ProfileService] Response received. Status code: ${response.statusCode}');
      print('[ProfileService] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        // Your Laravel backend returns {'profile': data}, so we extract 'profile'
        print('[ProfileService] Profile fetched successfully.');
        //  return responseData['profile'] as Map<String, dynamic>;
        return responseData['user'] as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        print('[ProfileService] Profile not found for this user (404).');
        return null; // This indicates no existing profile, which is expected for new users
      } else {
        print('[ProfileService] Error fetching profile from server.');
        // Attempt to parse a more specific error message from the backend
        try {
          final errorBody = json.decode(response.body);
          throw Exception(errorBody['message'] ??
              'Error fetching profile. Code: ${response.statusCode}');
        } catch (e) {
          throw Exception(
              'Error fetching profile. Code: ${response.statusCode}. Body: ${response.body}');
        }
      }
    } catch (e) {
      print('[ProfileService] Exception while fetching profile: $e');
      throw Exception('Error connecting to server: $e');
    }
  }

  /// Envía los datos del perfil del usuario al backend para guardarlos.
  Future<void> saveProfile(Map<String, dynamic> profileData) async {
    print('[ProfileService] Iniciando guardado de perfil...'); // Log de inicio
    print('[ProfileService] Datos del perfil: $profileData'); // Log de datos

    final token = await _storage.getToken();
    if (token == null) {
      print(
          '[ProfileService] Error: Token no encontrado. Usuario no autenticado.'); // Log de error
      throw Exception('Usuario no autenticado.');
    }

    print('[ProfileService] Token obtenido correctamente.'); // Log de éxito

    try {
      print(
          '[ProfileService] Realizando petición a $baseUrl/profile...'); // Log de URL
      final response = await http.post(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(profileData),
      );

      print(
          '[ProfileService] Respuesta recibida. Status code: ${response.statusCode}'); // Log de status
      print(
          '[ProfileService] Cuerpo de la respuesta: ${response.body}'); // Log de cuerpo (útil para depuración)

      if (response.statusCode != 200) {
        print(
            '[ProfileService] Error en la respuesta del servidor.'); // Log de error
        throw Exception(
            'Error al guardar el perfil. Código: ${response.statusCode}');
      }

      print('[ProfileService] Perfil guardado exitosamente.'); // Log de éxito
    } catch (e) {
      print(
          '[ProfileService] Excepción al guardar el perfil: $e'); // Log de excepción
      throw Exception('Error al conectar con el servidor: $e');
    }
  }
}
