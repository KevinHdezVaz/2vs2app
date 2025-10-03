import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:Frutia/utils/constantes.dart';

class BannerService {
  Future<List<String>> getBanners() async {
    final response = await http.get(Uri.parse('$baseUrl/carousel-images'));
    print('URL solicitada: $baseUrl/carousel-images');
    print('Código de respuesta: ${response.statusCode}');
    print('Cuerpo de la respuesta: ${response.body}');

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => item['image_url'] as String).toList();
    } else {
      throw Exception(
          'Error al cargar banners: ${response.statusCode} - ${response.body}');
    }
  }
}
