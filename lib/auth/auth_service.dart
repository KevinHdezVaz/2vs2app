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
    // Configuración para iOS:
    clientId: Platform.isIOS
        ? '730095641142-qj58r88ha7vnjlro9b5gsmb8upo9idcu.apps.googleusercontent.com' // De GoogleService-Info.plist
        : null,
    serverClientId:
        '730095641142-2sc256o1n605r12hshom8sop83l5p4sk.apps.googleusercontent.com', // De google-services.json (client_type 3)
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
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id_token': firebaseToken}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        await _storage.saveToken(data['token']);

        if (data['user'] != null) {
          await _storage.saveUser(frutia.User.fromJson(data['user']));
        }
        return true;
      } else {
        String errorMessage =
            data['message'] ?? 'Error en autenticación con Google';
        if (data['errors'] != null) {
          errorMessage = data['errors'].values.first[0];
        }
        throw AuthException(errorMessage);
      }
    } catch (e) {
      debugPrint('Error en _sendTokenToBackend: $e');
      throw AuthException(e.toString());
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
