import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:Frutia/services/storage_service.dart';
import 'package:Frutia/utils/constantes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // Importa si no lo tienes
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
 import 'package:shared_preferences/shared_preferences.dart';

import '../model/User.dart' as frutia;

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

class AuthService {
  final StorageService _storage = StorageService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  final storage = StorageService();

final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  // Para Android: NO especifiques clientId, usa solo serverClientId
  // Para iOS: usa el client_id de tipo 2 (iOS) del google-services.json
  clientId: Platform.isIOS
      ? '943019607563-ogk5mui0a1n86u120oif2afvqbs3u5lv.apps.googleusercontent.com' // iOS client
      : null,
  serverClientId:
      '943019607563-jnuk83jvn36jpq1il30mtackaff3jfhk.apps.googleusercontent.com', // Web client (tipo 3)
);
// En AuthService.dart

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? affiliateCode, // <-- CAMBIO: Nuevo parámetro opcional
  }) async {
    // ▼▼▼ INICIO DEL CAMBIO ▼▼▼
    final body = {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
    };

    // Si el código de afiliado no está vacío, lo añadimos al cuerpo de la petición
    if (affiliateCode != null && affiliateCode.isNotEmpty) {
      body['affiliate_code'] = affiliateCode;
    }
    // ▲▲▲ FIN DEL CAMBIO ▲▲▲

    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: json.encode(body), // Usamos el nuevo cuerpo
    );

    final data = json.decode(response.body);

    if (response.statusCode == 201) {
      await _storage.saveToken(data['token']);
       return data;
    } else {
      String errorMessage = data['message'] ?? 'Ocurrió un error desconocido.';
      if (data['errors'] != null) {
        errorMessage = data['errors'].values.first[0];
      }
      throw AuthException(errorMessage);
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      debugPrint('Iniciando login con Google...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final String? firebaseToken = await userCredential.user?.getIdToken();
      if (firebaseToken == null) {
        throw AuthException("No se obtuvo token de Firebase");
      }

      final success = await sendTokenToBackend(firebaseToken, 'google');
      if (success) {
       }
      return success;
    } on AuthException catch (e) {
      debugPrint('Error de autenticación: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error inesperado en Google Sign-In: $e');
      throw AuthException('Error inesperado al iniciar sesión con Google');
    }
  }
 Future<bool> sendTokenToBackend(String firebaseToken, String provider) async {
  try {
    final endpoint = provider == 'google' ? 'google-login' : 'facebook-login';
    final url = '$baseUrl/$endpoint';
    
    debugPrint('====================================');
    debugPrint('🔵 ENVIANDO TOKEN AL BACKEND');
    debugPrint('🔵 URL COMPLETA: $url');
    debugPrint('🔵 Provider: $provider');
    debugPrint('🔵 Token (primeros 50 chars): ${firebaseToken.substring(0, firebaseToken.length > 50 ? 50 : firebaseToken.length)}...');
    debugPrint('====================================');
    
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({'id_token': firebaseToken}),
    );

    debugPrint('====================================');
    debugPrint('🟢 RESPUESTA DEL BACKEND');
    debugPrint('🟢 Status code: ${response.statusCode}');
    debugPrint('🟢 Content-Type: ${response.headers['content-type']}');
    debugPrint('🟢 Body (primeros 300 chars): ${response.body.substring(0, response.body.length > 300 ? 300 : response.body.length)}');
    debugPrint('====================================');

    // Verifica que sea JSON antes de decodificar
    if (response.headers['content-type']?.contains('application/json') != true) {
      debugPrint('❌ ERROR: El servidor NO devolvió JSON');
      debugPrint('❌ Devolvió: ${response.headers['content-type']}');
      throw AuthException('El servidor devolvió HTML en lugar de JSON. Verifica que la URL sea correcta y que el backend esté funcionando.');
    }

    final data = json.decode(response.body);

    if (response.statusCode == 200) {
      debugPrint('✅ Token validado correctamente');
      await _storage.saveToken(data['token']);
      debugPrint('✅ Token guardado en storage');

      if (data['user'] != null) {
        await _storage.saveUser(frutia.User.fromJson(data['user']));
        debugPrint('✅ Usuario guardado: ${data['user']['name']}');
      }
      return true;
    } else {
      debugPrint('❌ Error del backend: ${response.statusCode}');
      String errorMessage =
          data['message'] ?? 'Error en autenticación con Google';
      if (data['errors'] != null) {
        errorMessage = data['errors'].values.first[0];
      }
      throw AuthException(errorMessage);
    }
  } on FormatException catch (e) {
    debugPrint('❌ FormatException: No se pudo parsear JSON');
    debugPrint('❌ Error: $e');
    throw AuthException('Respuesta inválida del servidor (HTML en lugar de JSON)');
  } catch (e) {
    debugPrint('❌ Error inesperado en sendTokenToBackend');
    debugPrint('❌ Tipo: ${e.runtimeType}');
    debugPrint('❌ Error: $e');
    if (e is AuthException) rethrow;
    throw AuthException('Error al comunicarse con el servidor: $e');
  }
}


Future<Map<String, dynamic>> login(String email, String password) async {
  try {
    print('====================================');
    print('🔵 INICIO LOGIN');
    print('🔵 URL completa: $baseUrl/login');
    print('🔵 Email: $email');
    print('🔵 Password length: ${password.length}');
    print('====================================');
    
    final uri = Uri.parse('$baseUrl/login');
    print('🔵 URI parseada: $uri');
    
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'email': email,
        'password': password,
      }),
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw AuthException('Tiempo agotado. Verifica tu internet.');
      },
    );

    print('====================================');
    print('🟢 RESPUESTA RECIBIDA');
    print('🟢 Status: ${response.statusCode}');
    print('🟢 Headers: ${response.headers}');
    print('🟢 Body: ${response.body}');
    print('====================================');

    final data = json.decode(response.body);

    if (response.statusCode == 200) {
      print('✅ Login exitoso, guardando token...');
      await _storage.saveToken(data['token']);
      print('✅ Token guardado');
      
      // 🆕 AGREGAR ESTAS LÍNEAS: Guardar el usuario
      if (data['user'] != null) {
        print('✅ Guardando datos del usuario...');
        await _storage.saveUser(frutia.User.fromJson(data['user']));
        print('✅ Usuario guardado: ${data['user']['name']}');
      }
      
      return data;
    } else {
      print('❌ Login fallido: ${data['message']}');
      throw AuthException(data['message'] ?? 'Credenciales inválidas.');
    }
  } on SocketException catch (e) {
    print('❌ SocketException: $e');
    throw AuthException('Sin conexión a internet');
  } on TimeoutException catch (e) {
    print('❌ TimeoutException: $e');
    throw AuthException('Tiempo de espera agotado');
  } on FormatException catch (e) {
    print('❌ FormatException: $e');
    throw AuthException('Respuesta inválida del servidor');
  } on http.ClientException catch (e) {
    print('❌ ClientException: $e');
    throw AuthException('Error de conexión: ${e.message}');
  } catch (e, stackTrace) {
    print('====================================');
    print('❌ ERROR DESCONOCIDO');
    print('❌ Tipo: ${e.runtimeType}');
    print('❌ Error: $e');
    print('❌ Stack: $stackTrace');
    print('====================================');
    if (e is AuthException) rethrow;
    throw AuthException('Error inesperado: $e');
  }
}

  /// Cierra la sesión del usuario.
  Future<void> logout() async {
    final token = await _storage.getToken();

 

    try {
      if (token != null) {
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token'
          },
        );
      }
    } catch (e) {
      // Ignoramos el error si la API falla, lo importante es limpiar localmente
      print(
          "Error al hacer logout en el backend (se procederá con la limpieza local): $e");
    } finally {
      // Limpiaremos todo sin importar si la llamada a la API fue exitosa

      // ▼▼▼ CAMBIO IMPORTANTE AQUÍ ▼▼▼
      // En lugar de solo remover el token, limpiamos todo.
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // También es buena práctica desautenticar de Google si se usó
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Y de Firebase
      await _firebaseAuth.signOut();
    }
  }

  /// Obtiene los datos del perfil del usuario autenticado.
  Future<Map<String, dynamic>> getProfile() async {
    final token = await _storage.getToken();
    if (token == null) throw AuthException('No autenticado.');

    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw AuthException('No se pudo obtener el perfil.');
    }
  }
 
  // --- FIN NUEVO MÉTODO ---
}
