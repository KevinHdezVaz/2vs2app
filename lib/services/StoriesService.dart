import 'package:dio/dio.dart';
import 'package:Frutia/model/Story.dart';
 

class StoriesService {
  final Dio _dio = Dio();
  final String baseUrl = 'https://proyect.aftconta.mx/api';

  Future<List<Story>> getStories() async {
    try {
      print('Fetching stories from: $baseUrl/stories');
      final response = await _dio.get('$baseUrl/stories');
      
      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => Story.fromJson(json)).toList();
      }
      throw Exception('Failed to load stories');
    } catch (e) {
      print('Error fetching stories: $e');
      throw Exception('Error de conexión: $e');
    }
  }
}