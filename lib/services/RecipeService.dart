import 'dart:convert';
import 'package:Frutia/services/storage_service.dart';
import 'package:Frutia/utils/constantes.dart';
import 'package:http/http.dart' as http; 

class RecipeService {
  final StorageService _storage = StorageService();

  Future<Map<String, dynamic>> getRecipe(int recipeId) async {
    final token = await _storage.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/recipes/$recipeId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al cargar la receta.');
    }
  }
}