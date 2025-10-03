// lib/services/notification_service.dart
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:Frutia/model/Notificacion.dart';
import 'package:Frutia/services/storage_service.dart';
import 'package:Frutia/utils/constantes.dart';

class NotificationServiceExtension {
  final StorageService storage = StorageService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await storage.getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
    developer.log('Headers generados: $headers', name: 'NotificationService');
    return headers;
  }

// En NotificationServiceExtension
  Future<void> markAllNotificationsAsRead() async {
    developer.log('Iniciando markAllNotificationsAsRead',
        name: 'NotificationService');

    final headers = await _getHeaders();
    developer.log('Headers obtenidos: $headers', name: 'NotificationService');

    final url = Uri.parse('$baseUrl/notifications/mark-all-as-read');
    developer.log('URL de la solicitud: $url', name: 'NotificationService');

    try {
      developer.log('Enviando solicitud POST...', name: 'NotificationService');
      final response = await http.post(url, headers: headers);

      developer.log('Respuesta recibida - Status: ${response.statusCode}',
          name: 'NotificationService');
      developer.log('Cuerpo de la respuesta: ${response.body}',
          name: 'NotificationService');

      if (response.statusCode != 200) {
        developer.log('Error: Código de estado no es 200',
            name: 'NotificationService', level: 900); // Nivel de warning
        throw Exception(
            'Error al marcar notificaciones como leídas - Status: ${response.statusCode}');
      }

      developer.log('Notificaciones marcadas como leídas exitosamente',
          name: 'NotificationService');
    } catch (e) {
      developer.log('Excepción capturada: $e',
          name: 'NotificationService',
          level: 1000, // Nivel de error
          error: e);
      throw Exception('Error en la solicitud: $e');
    }
  }

  // Obtener el historial de notificaciones
  Future<List<Notificacion>> getNotifications() async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/notifications');
    developer.log('Solicitando GET a: $url', name: 'NotificationService');

    try {
      final response = await http.get(url, headers: headers);
      developer.log('Respuesta recibida - Status: ${response.statusCode}',
          name: 'NotificationService');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> notificationsData =
            responseData['notifications'] ?? [];
        developer.log('Datos recibidos: ${response.body}',
            name: 'NotificationService');
        return notificationsData
            .map((data) => Notificacion.fromJson(data))
            .toList();
      } else {
        developer.log(
            'Error - Status: ${response.statusCode}, Body: ${response.body}',
            name: 'NotificationService');
        throw Exception(
            'Error al cargar notificaciones: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('Excepción en getNotifications: $e',
          name: 'NotificationService', error: e);
      rethrow;
    }
  }

  // Eliminar una notificación
  Future<void> deleteNotification(int notificationId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/notifications/$notificationId');
    developer.log('Solicitando DELETE a: $url', name: 'NotificationService');

    try {
      final response = await http.delete(url, headers: headers);
      developer.log('Respuesta recibida - Status: ${response.statusCode}',
          name: 'NotificationService');

      if (response.statusCode != 200) {
        developer.log(
            'Error - Status: ${response.statusCode}, Body: ${response.body}',
            name: 'NotificationService');
        throw Exception(
            'Error al eliminar notificación: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('Excepción en deleteNotification: $e',
          name: 'NotificationService', error: e);
      rethrow;
    }
  }
}
