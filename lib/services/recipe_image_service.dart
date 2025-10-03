import 'dart:convert';
import 'package:Frutia/auth/auth_service.dart';
import 'package:Frutia/services/storage_service.dart';
import 'package:Frutia/utils/constantes.dart';
import 'package:http/http.dart' as http; 

class RecipeImageService {
  final StorageService _storage = StorageService();

  Future<String> generateImage(String optionText) async {
    print('RecipeImageService: Iniciando generateImage para optionText="$optionText"');
    
    try {
      print('RecipeImageService: Obteniendo token...');
      final token = await _storage.getToken();
      if (token == null) {
        print('RecipeImageService: Error - No se encontró token de autenticación');
        throw AuthException('No autenticado.');
      }
      print('RecipeImageService: Token obtenido correctamente');

      print('RecipeImageService: Enviando solicitud POST a $baseUrl/recipes/generate-image');
      final response = await http.post(
        Uri.parse('$baseUrl/recipes/generate-image'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'option_text': optionText}),
      );

      print('RecipeImageService: Respuesta recibida con statusCode=${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('RecipeImageService: Decodificando respuesta JSON');
        final data = json.decode(response.body);
        final imageUrl = data['image_url'] as String?;
        
        if (imageUrl == null) {
          print('RecipeImageService: Error - image_url no encontrado en la respuesta');
          throw Exception('Respuesta inválida: image_url no encontrado');
        }
        
        print('RecipeImageService: Imagen generada con éxito, image_url=$imageUrl');
        return imageUrl;
      } else {
        print('RecipeImageService: Error en la solicitud - statusCode=${response.statusCode}, body=${response.body}');
        throw Exception('Error al generar la imagen para "$optionText": ${response.statusCode}');
      }
    } catch (e) {
      print('RecipeImageService: Excepción capturada - $e');
      rethrow; // Relanzar la excepción para que el llamador la maneje
    }
  }
}