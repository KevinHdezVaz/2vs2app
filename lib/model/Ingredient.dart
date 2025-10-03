import 'package:Frutia/model/PriceDetail.dart';

class Ingredient {
  final String item;
  final String quantity;
  final List<PriceDetail> prices;
  final String? imageUrl;  

  Ingredient({
    required this.item,
    this.quantity = '',
    required this.prices,
    this.imageUrl, // NUEVO: Añadir al constructor.
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      item: json['item'] as String? ?? 'Desconocido',
      quantity: json['quantity'] as String? ?? '',
      prices: (json['prices'] as List<dynamic>?)
              ?.map((p) => PriceDetail.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      // NUEVO: Leer el campo 'image_url' del JSON.
      // Si no existe o es nulo, el valor será null.
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item': item,
      'quantity': quantity,
      'prices': prices.map((p) => p.toJson()).toList(),
      'imageUrl': imageUrl, // NUEVO: Añadir al método toJson.
    };
  }
}

  