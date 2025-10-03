import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:Frutia/auth/auth_service.dart';
import 'package:Frutia/model/booking.dart';
import 'package:Frutia/model/field.dart';
import 'package:Frutia/services/storage_service.dart';
import 'package:Frutia/utils/constantes.dart';

class BookingService {
  final StorageService storage = StorageService();
  static const Duration _timeoutDuration = Duration(seconds: 30);

  // Obtener detalles de un campo
  Future<Field> getFieldDetails(int fieldId) async {
    try {
      final token = await storage.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/fields/$fieldId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json', // Añadido para forzar JSON
        },
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Field.fromJson(data);
      } else {
        throw Exception(
            'Error al obtener los detalles del campo: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error getting field details: $e');
      if (e is TimeoutException) {
        throw Exception(
            'Tiempo de espera agotado al obtener detalles del campo');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkPaymentExists(String paymentId) async {
    try {
      final token = await storage.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/check-payment/$paymentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(_timeoutDuration);

      debugPrint('Check Payment Status Code: ${response.statusCode}');
      debugPrint('Check Payment Response: ${response.body}');

      final data = json.decode(response.body);
      return data; // {exists: true/false, booking_id: id, message: "..."}
    } catch (e) {
      debugPrint('Error checking payment: $e');
      return {'exists': false, 'message': 'Error al verificar reserva: $e'};
    }
  }

  // Cancelar una reserva
  Future<Map<String, dynamic>> cancelReservation(String reservationId) async {
    try {
      final token = await storage.getToken();
      final response = await http
          .put(
            Uri.parse('$baseUrl/bookings/$reservationId/cancel'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'reason': 'Usuario canceló la reserva'}),
          )
          .timeout(_timeoutDuration);

      debugPrint('Cancel Booking Status Code: ${response.statusCode}');
      debugPrint('Cancel Booking Response: ${response.body}');

      try {
        final responseData = json.decode(response.body);

        if (response.statusCode == 200) {
          return {
            'success': true,
            'message':
                responseData['message'] ?? 'Reserva cancelada exitosamente',
            'refunded_amount': responseData['refunded_amount'],
            'booking': responseData['booking'],
          };
        } else if (response.statusCode == 400 &&
            responseData['message'] == 'La reserva ya está cancelada') {
          return {'success': false, 'message': responseData['message']};
        } else {
          return {
            'success': false,
            'message':
                responseData['message'] ?? 'Error al cancelar la reserva',
          };
        }
      } catch (e) {
        debugPrint('Error al decodificar JSON: $e');
        return {
          'success': false,
          'message': 'Error en el servidor. Por favor, inténtalo más tarde.',
        };
      }
    } catch (e) {
      debugPrint('Error al cancelar la reserva: $e');
      if (e is TimeoutException) {
        return {
          'success': false,
          'message': 'Tiempo de espera agotado al cancelar la reserva',
        };
      }
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  // Obtener horarios disponibles
  Future<List<String>> getAvailableHours(int fieldId, String date) async {
    try {
      final token = await storage.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/fields/$fieldId/available-hours?date=$date'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(_timeoutDuration);

      debugPrint("Response status code: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);

        debugPrint("Decoded data type: ${decodedData.runtimeType}");
        debugPrint("Decoded data: $decodedData");

        if (decodedData is Map<String, dynamic> &&
            decodedData.containsKey('available_hours')) {
          final availableHours = decodedData['available_hours'];
          if (availableHours is List) {
            return availableHours.map((hour) => hour.toString()).toList();
          } else {
            debugPrint('Error: available_hours no es una lista');
            return [];
          }
        } else {
          debugPrint('Error: la respuesta no tiene el formato esperado');
          return [];
        }
      } else {
        debugPrint('Error: código de estado ${response.statusCode}');
        throw Exception(
            'Error al obtener horarios disponibles: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error getting available hours: $e');
      if (e is TimeoutException) {
        throw Exception('Tiempo de espera agotado al obtener horarios');
      }
      throw Exception('Error al obtener horarios disponibles: $e');
    }
  }

  // Crear una reserva
  Future<Map<String, dynamic>> createBooking({
    required int fieldId,
    required String date,
    required String startTime,
    int? playersNeeded,
    bool useWallet = false,
    String? paymentId,
    String? orderId,
  }) async {
    try {
      final token = await storage.getToken();
      debugPrint('Token usado para reserva: $token');

      final Map<String, dynamic> requestData = {
        'field_id': fieldId,
        'date': date,
        'start_time': startTime,
        'players_needed': playersNeeded,
        'use_wallet': useWallet,
      };

      if (paymentId != null) requestData['payment_id'] = paymentId;
      if (orderId != null) requestData['order_id'] = orderId;

      final response = await http
          .post(
            Uri.parse('$baseUrl/bookings'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json', // Añadido para forzar JSON
            },
            body: json.encode(requestData),
          )
          .timeout(_timeoutDuration);

      debugPrint('Booking Status Code: ${response.statusCode}');
      debugPrint('Booking Response: ${response.body}');

      // Manejar respuesta HTML (como 302)
      if (response.statusCode == 302 ||
          response.body.contains('<!DOCTYPE html>')) {
        debugPrint('Respuesta HTML detectada: posible redirección o error 302');
        return {
          'success': false,
          'message':
              'Error de autenticación o redirección en el servidor. Contacta al soporte.',
        };
      }

      // Intentar decodificar la respuesta
      final responseData = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': response.statusCode == 200
              ? 'La reserva ya fue procesada anteriormente'
              : 'Reserva creada exitosamente',
          'data': responseData,
        };
      } else if (response.statusCode == 422) {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Horario no disponible',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Error al crear la reserva',
        };
      }
    } catch (e) {
      debugPrint('Error en la reserva: $e');
      if (e is FormatException) {
        return {
          'success': false,
          'message': 'Respuesta inválida del servidor. Posible error 302.',
        };
      } else if (e is TimeoutException) {
        return {
          'success': false,
          'message': 'Tiempo de espera agotado al crear la reserva',
        };
      }
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>?> getDailyMatch({
    required int fieldId,
    required String date,
    required String startTime,
  }) async {
    print('Iniciando solicitud para verificar partido...');
    print('Field ID: $fieldId, Fecha: $date, Hora de inicio: $startTime');

    final token = await storage.getToken();
    print('Token obtenido: $token');

    final url =
        '$baseUrl/daily-matches/check?field_id=$fieldId&date=$date&start_time=$startTime';
    print('URL de la solicitud: $url');

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('Respuesta recibida. Código de estado: ${response.statusCode}');
    print('Cuerpo de la respuesta: ${response.body}');

    if (response.statusCode == 200) {
      print('Partido verificado exitosamente.');
      return json.decode(response.body);
    } else {
      print('Error al verificar partido: ${response.statusCode}');
      throw Exception('Error al verificar partido: ${response.statusCode}');
    }
  }

  // Obtener reservas activas
  Future<List<Booking>> getActiveReservations() async {
    try {
      final token = await storage.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/active-reservations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(_timeoutDuration);

      debugPrint(
          'Active Reservations - Código de estado: ${response.statusCode}');
      debugPrint('Active Reservations - Cuerpo de respuesta: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        debugPrint('Active Reservations - Datos recibidos: $data');

        final activeBookings =
            data.map((item) => Booking.fromJson(item)).toList();

        debugPrint('Active Reservations - Reservas activas: $activeBookings');
        return activeBookings;
      } else {
        throw Exception(
            'No se pudieron cargar las reservas activas. Código de estado: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error al obtener reservas activas: $e');
      if (e is TimeoutException) {
        throw Exception('Tiempo de espera agotado al obtener reservas activas');
      }
      rethrow;
    }
  }

  // Obtener historial de reservas
  Future<List<Booking>> getReservationHistory() async {
    try {
      final token = await storage.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/reservation-history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(_timeoutDuration);

      debugPrint('Código de estado: ${response.statusCode}');
      debugPrint('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        debugPrint('Datos de historial recibidos: $data');

        final historicalBookings =
            data.map((item) => Booking.fromJson(item)).toList();

        debugPrint('Reservas históricas: $historicalBookings');
        return historicalBookings;
      } else {
        throw Exception(
            'No se pudo cargar el historial de reservas. Código de estado: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error al obtener historial de reservas: $e');
      if (e is TimeoutException) {
        throw Exception('Tiempo de espera agotado al obtener historial');
      }
      rethrow;
    }
  }

  // Obtener todas las reservas
  Future<List<Booking>> getAllReservations() async {
    try {
      final token = await storage.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/bookings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((item) => Booking.fromJson(item)).toList();
      } else {
        throw Exception(
            'No se pudieron cargar las reservas. Código de estado: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error al obtener todas las reservas: $e');
      if (e is TimeoutException) {
        throw Exception('Tiempo de espera agotado al obtener reservas');
      }
      rethrow;
    }
  }
}
