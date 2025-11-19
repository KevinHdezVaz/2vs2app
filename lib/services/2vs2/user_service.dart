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



static Future<Map<String, dynamic>> updateProfile({
  String? name,
  String? email,
  String? phone,
  String? currentPassword,
  String? newPassword,
  String? newPasswordConfirmation,
}) async {
  print('[UserService] Actualizando perfil del usuario...');
  
  try {
    // Construir el body solo con los campos que se están actualizando
    final Map<String, dynamic> body = {};
    
    if (name != null && name.isNotEmpty) body['name'] = name;
    if (email != null && email.isNotEmpty) body['email'] = email;
    if (phone != null && phone.isNotEmpty) body['phone'] = phone;
    
    // Si se está cambiando la contraseña
    if (newPassword != null && newPassword.isNotEmpty) {
      if (currentPassword == null || currentPassword.isEmpty) {
        throw Exception('Current password is required to change password');
      }
      body['current_password'] = currentPassword;
      body['new_password'] = newPassword;
      body['new_password_confirmation'] = newPasswordConfirmation ?? newPassword;
    }
    
    print('[UserService] Campos a actualizar: ${body.keys}');
    
    final response = await http.put(
      Uri.parse('$baseUrl/user/profile'),
      headers: await getAuthHeaders(),
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      print('[UserService] Perfil actualizado exitosamente');
      return json.decode(response.body);
    } else if (response.statusCode == 422) {
      // Error de validación
      final errorBody = json.decode(response.body);
      final errors = errorBody['errors'];
      
      if (errors != null && errors is Map) {
        // Tomar el primer error
        final firstError = errors.values.first;
        final errorMessage = firstError is List ? firstError.first : firstError;
        throw Exception(errorMessage);
      }
      
      throw Exception(errorBody['message'] ?? 'Validation error');
    } else if (response.statusCode == 400) {
      // Error de contraseña incorrecta
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['message'] ?? 'Invalid current password');
    } else {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['message'] ?? 'Error updating profile');
    }
  } catch (e) {
    print('[UserService] Excepción: $e');
    
    // Si ya es un Exception con mensaje personalizado, lanzarlo tal cual
    if (e is Exception) {
      rethrow;
    }
    
    throw Exception('Error de conexión: $e');
  }
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