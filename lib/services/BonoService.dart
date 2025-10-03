import 'dart:convert';
import 'dart:developer' as developer; // Importar para logging
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Frutia/model/Bonos.dart';
import 'package:Frutia/model/UserBono.dart';
import 'package:Frutia/services/storage_service.dart';

class BonoService {
  final StorageService storage = StorageService();
  final String baseUrl;

  BonoService({required this.baseUrl});

  Future<Map<String, String>> _getHeaders() async {
    final token = await storage.getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
    developer.log('Headers generados: $headers', name: 'BonoService');
    return headers;
  }

  Future<List<Bono>> getBonos() async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/bonos');
    developer.log('Solicitando GET a: $url', name: 'BonoService');

    try {
      final response = await http.get(url, headers: headers);
      developer.log('Respuesta recibida - Status: ${response.statusCode}',
          name: 'BonoService');
      developer.log('Cuerpo de la respuesta: ${response.body}',
          name: 'BonoService');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        developer.log('Datos recibidos: ${response.body}', name: 'BonoService');
        return responseData.map((data) => Bono.fromJson(data)).toList();
      } else {
        developer.log(
            'Error - Status: ${response.statusCode}, Body: ${response.body}',
            name: 'BonoService');
        throw Exception(
            'Error al cargar los bonos: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('Excepción en getBonos: $e', name: 'BonoService', error: e);
      rethrow;
    }
  }

  Future<String> createPreference(int bonoId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/bonos/create-preference'),
      headers: headers,
      body: jsonEncode({'bono_id': bonoId}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['preference_id'];
    } else {
      throw Exception('Error al crear preferencia: ${response.body}');
    }
  }

  // Obtener bonos activos del usuario
  Future<List<UserBono>> getMisBonos() async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/mis-bonos');
    developer.log('Solicitando GET a: $url', name: 'BonoService');

    try {
      final response = await http.get(url, headers: headers);
      developer.log('Respuesta recibida - Status: ${response.statusCode}',
          name: 'BonoService');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        developer.log('Datos recibidos: ${response.body}', name: 'BonoService');
        return responseData.map((data) => UserBono.fromJson(data)).toList();
      } else {
        developer.log(
            'Error - Status: ${response.statusCode}, Body: ${response.body}',
            name: 'BonoService');
        throw Exception(
            'Error al cargar los bonos del usuario: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('Excepción en getMisBonos: $e',
          name: 'BonoService', error: e);
      rethrow;
    }
  }

  // Obtener historial de bonos del usuario
  Future<List<UserBono>> getHistorialBonos() async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/historial-bonos');
    developer.log('Solicitando GET a: $url', name: 'BonoService');

    try {
      final response = await http.get(url, headers: headers);
      developer.log('Respuesta recibida - Status: ${response.statusCode}',
          name: 'BonoService');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        developer.log('Datos recibidos: ${response.body}', name: 'BonoService');
        return responseData.map((data) => UserBono.fromJson(data)).toList();
      } else {
        developer.log(
            'Error - Status: ${response.statusCode}, Body: ${response.body}',
            name: 'BonoService');
        throw Exception(
            'Error al cargar el historial de bonos: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('Excepción en getHistorialBonos: $e',
          name: 'BonoService', error: e);
      rethrow;
    }
  }

  // Comprar un bono
  Future<UserBono> comprarBono(
      {required int bonoId,
      required String paymentId,
      required String orderId}) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/bonos/comprar'),
      headers: headers,
      body: jsonEncode({
        'bono_id': bonoId,
        'payment_id': paymentId,
        'order_id': orderId,
      }),
    );

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body);
      return UserBono.fromJson(responseData['user_bono']);
    } else {
      throw Exception('Error al comprar bono: ${response.body}');
    }
  }

  // Usar un bono para una reserva
  Future<UserBono> usarBono(
      {required int userBonoId, required int bookingId}) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/bonos/usar');
    final body =
        jsonEncode({'user_bono_id': userBonoId, 'booking_id': bookingId});
    developer.log('Solicitando POST a: $url con body: $body',
        name: 'BonoService');

    try {
      final response = await http.post(url, headers: headers, body: body);
      developer.log('Respuesta recibida - Status: ${response.statusCode}',
          name: 'BonoService');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        developer.log('Datos recibidos: ${response.body}', name: 'BonoService');
        return UserBono.fromJson(responseData['user_bono']);
      } else {
        final errorData = json.decode(response.body);
        developer.log(
            'Error - Status: ${response.statusCode}, Body: ${response.body}',
            name: 'BonoService');
        throw Exception(errorData['message'] ??
            'Error al usar el bono: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('Excepción en usarBono: $e', name: 'BonoService', error: e);
      rethrow;
    }
  }

  // Cancelar un bono
  Future<UserBono> cancelarBono(int userBonoId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/bonos/cancelar/$userBonoId');
    developer.log('Solicitando PUT a: $url', name: 'BonoService');

    try {
      final response = await http.put(url, headers: headers);
      developer.log('Respuesta recibida - Status: ${response.statusCode}',
          name: 'BonoService');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        developer.log('Datos recibidos: ${response.body}', name: 'BonoService');
        return UserBono.fromJson(responseData['user_bono']);
      } else {
        final errorData = json.decode(response.body);
        developer.log(
            'Error - Status: ${response.statusCode}, Body: ${response.body}',
            name: 'BonoService');
        throw Exception(errorData['message'] ??
            'Error al cancelar el bono: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('Excepción en cancelarBono: $e',
          name: 'BonoService', error: e);
      rethrow;
    }
  }

  // Verificar código de bono
  Future<Map<String, dynamic>> verificarCodigoBono(String codigo) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/bonos/verificar-codigo');
    final body = jsonEncode({'codigo': codigo});
    developer.log('Solicitando POST a: $url con body: $body',
        name: 'BonoService');

    try {
      final response = await http.post(url, headers: headers, body: body);
      developer.log('Respuesta recibida - Status: ${response.statusCode}',
          name: 'BonoService');

      if (response.statusCode == 200) {
        developer.log('Datos recibidos: ${response.body}', name: 'BonoService');
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        developer.log(
            'Error - Status: ${response.statusCode}, Body: ${response.body}',
            name: 'BonoService');
        throw Exception(errorData['message'] ??
            'Error al verificar el código: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('Excepción en verificarCodigoBono: $e',
          name: 'BonoService', error: e);
      rethrow;
    }
  }
}
