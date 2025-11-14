import 'dart:convert';
import 'package:Frutia/model/EquipoPartidos.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/User.dart';

class StorageService {
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }


// En storage_service.dart

Future<void> removeUser() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(userKey);
}

// ✅ MEJOR AÚN: Método para limpiar todo
Future<void> clearAll() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear(); // Borra TODOS los datos
  print('🧹 SharedPreferences cleared completely');
}

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString(tokenKey);
    print("token laravel ${token ?? 'No hay token'}");
    return token;
  }

  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(userKey);
    if (userJson == null) return null;
    return User.fromJson(jsonDecode(userJson));
  }

  // NUEVO MÉTODO: Obtiene los datos del usuario como JSON string
  Future<String?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userKey);
  }
Future<void> saveUser(User user) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(userKey, json.encode(user.toJson()));
  print('Usuario guardado: ${user.name}'); // ← DEBUG
}

  Future<void> saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }
}