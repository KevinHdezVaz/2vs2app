import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:Frutia/services/storage_service.dart'; // Importa tu StorageService
import 'package:Frutia/utils/constantes.dart'; // Importa tus constantes

class VerificationService {
  final StorageService storage = StorageService();

  VerificationService();

  // Método para subir el DNI (no es estático)
  Future<Map<String, dynamic>> uploadDni(File dniImage) async {
    try {
      // Obtener el token de autenticación
      final token = await storage.getToken();

      // Crear la solicitud multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-dni'), // Usa la constante baseUrl
      );

      // Agregar headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Adjuntar la imagen
      request.files.add(
        await http.MultipartFile.fromPath(
          'dni_image',
          dniImage.path,
        ),
      );

      // Enviar la solicitud
      var response = await request.send();

      // Procesar la respuesta
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        return {
          'success': true,
          'message': 'DNI subido correctamente.',
          'data': json.decode(responseData),
        };
      } else {
        var responseData = await response.stream.bytesToString();
        return {
          'success': false,
          'message': 'Error al subir el DNI: ${responseData}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }
}